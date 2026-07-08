import secrets
from decimal import Decimal
from datetime import timedelta
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from uuid import UUID, uuid4

from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.users.models import FriendInvite, FriendInviteStatus, User
from apps.users.queries import (
    convert_amount,
    get_balance_expenses_for_user,
    get_pairwise_expenses,
    get_pending_invite_by_token,
    get_pairwise_transactions,
    get_transactions_for_user,
    list_friends,
    search_users,
)
from core.storage import generate_presigned_upload_url
from tasks.s3_tasks import delete_s3_object


class UserService:
    @staticmethod
    def _normalized_supabase_phone(phone: str | None) -> str | None:
        if phone is None:
            return None
        normalized = str(phone).strip()
        return normalized or None

    @staticmethod
    def sync_from_supabase_claims(payload: dict) -> User:
        supabase_uid = UUID(payload["sub"])
        email = payload.get("email")
        if not email:
            raise ValueError("Supabase token is missing the email claim.")

        user_metadata = payload.get("user_metadata") or {}
        display_name = (
            user_metadata.get("full_name")
            or user_metadata.get("name")
            or payload.get("preferred_username")
            or email.split("@")[0]
        )
        defaults = {
            "email": email,
            "phone": UserService._normalized_supabase_phone(payload.get("phone")),
            "display_name": display_name[:100],
            "avatar_url": user_metadata.get("avatar_url"),
        }

        try:
            with transaction.atomic():
                user, created = User.all_objects.get_or_create(
                    supabase_uid=supabase_uid,
                    defaults=defaults,
                )
                if created:
                    return user

                if user.is_deleted:
                    raise ValueError("This user account has been deleted.")

                updated_fields = []
                for field, value in defaults.items():
                    if getattr(user, field) != value:
                        setattr(user, field, value)
                        updated_fields.append(field)

                if updated_fields:
                    updated_fields.append("updated_at")
                    user.save(update_fields=updated_fields)
        except IntegrityError as exc:
            # A different supabase_uid already owns this email (e.g. the Supabase
            # project was recreated and re-issued the user a new id). Surface a
            # clean auth failure instead of a 500 rather than silently re-linking.
            raise ValueError("An account with this email already exists under a different identity.") from exc

        return user

    @staticmethod
    def update_profile(user: User, validated_data: dict) -> User:
        updated_fields = []
        for field, value in validated_data.items():
            if getattr(user, field) != value:
                setattr(user, field, value)
                updated_fields.append(field)

        if updated_fields:
            updated_fields.append("updated_at")
            user.save(update_fields=updated_fields)

        return user

    @staticmethod
    def search(query: str, current_user: User):
        return search_users(query, current_user.id)

    @staticmethod
    def anonymize_and_soft_delete(user: User) -> User:
        anonymized_email = f"deleted-{user.id}@rachae.local"
        user.email = anonymized_email
        user.phone = None
        user.display_name = "Deleted User"
        user.avatar_url = None
        user.stripe_customer_id = None
        user.is_ad_free = False
        user.is_deleted = True
        user.save(
            update_fields=[
                "email",
                "phone",
                "display_name",
                "avatar_url",
                "stripe_customer_id",
                "is_ad_free",
                "is_deleted",
                "updated_at",
            ]
        )

        from apps.users.tasks import delete_user_data

        transaction.on_commit(lambda: delete_user_data.delay(str(user.id)))
        return user


class FriendService:
    @staticmethod
    def list_friends(user: User):
        return list_friends(user.id)


class AvatarService:
    DEFAULT_EXPIRES_IN = 300

    @staticmethod
    def generate_avatar_upload(user: User, content_type: str, file_name: str = "") -> dict:
        extension = Path(file_name).suffix or AvatarService._extension_for_content_type(content_type)
        file_key = f"avatars/{user.id}/{uuid4().hex}{extension}"
        upload_url = generate_presigned_upload_url(file_key, content_type, AvatarService.DEFAULT_EXPIRES_IN)
        return {
            "upload_url": upload_url,
            "file_key": file_key,
            "expires_in": AvatarService.DEFAULT_EXPIRES_IN,
        }

    @staticmethod
    def confirm_avatar_upload(user: User, file_key: str) -> User:
        expected_prefix = f"avatars/{user.id}/"
        if not file_key.startswith(expected_prefix):
            raise ValueError("Avatar file key does not belong to the current user.")

        previous_key = user.avatar_url
        user.avatar_url = file_key
        user.save(update_fields=["avatar_url", "updated_at"])

        if previous_key and previous_key != file_key and not previous_key.startswith(("http://", "https://")):
            transaction.on_commit(lambda: delete_s3_object.delay(previous_key))

        return user

    @staticmethod
    def _extension_for_content_type(content_type: str) -> str:
        mapping = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
        }
        return mapping.get(content_type, ".bin")


class BalanceService:
    REPORT_CURRENCY = "BRL"

    @classmethod
    def get_balance_summary(cls, user: User) -> dict:
        balances = cls._build_pairwise_balances(user.id)
        total_owed = sum((amount for amount in balances.values() if amount > 0), Decimal("0.00"))
        total_owing = sum((-amount for amount in balances.values() if amount < 0), Decimal("0.00"))
        return {
            "total_owed": total_owed,
            "total_owing": total_owing,
            "net_balance": total_owed - total_owing,
            "currency": cls.REPORT_CURRENCY,
        }

    @classmethod
    def pairwise_net_balances_for_user(cls, user_id, *, preloaded_expenses=None):
        """Map counterparty user id -> net in [REPORT_CURRENCY]. Positive => they owe the user.

        When ``preloaded_expenses`` is provided (same shape as ``get_balance_expenses_for_user`` with
        splits prefetched), skip reloading expenses — used by owed_to_me replay to avoid duplicate work.
        """
        return cls._build_pairwise_balances(user_id, preloaded_expenses=preloaded_expenses)

    @classmethod
    def get_pairwise_balance(cls, current_user: User, other_user: User) -> dict:
        balances = cls._build_pairwise_balances(current_user.id, other_user.id)
        net = balances.get(other_user.id, Decimal("0.00"))
        return {
            "balance": net,
            "currency": cls.REPORT_CURRENCY,
        }

    @classmethod
    def list_pairwise_nonzero(cls, user: User, *, owe_me_only: bool = False) -> list[dict]:
        raw = cls._build_pairwise_balances(user.id)
        nonzero = {}
        for uid, amount in raw.items():
            if amount == Decimal("0.00"):
                continue
            if owe_me_only and amount <= Decimal("0.00"):
                continue
            nonzero[uid] = amount

        users_by_id = {
            other.id: other
            for other in User.all_objects.filter(id__in=nonzero.keys())
        }

        out = []
        for uid, amount in nonzero.items():
            other = users_by_id.get(uid)
            if other is None:
                continue
            out.append(
                {
                    "user": other,
                    "balance": amount.quantize(Decimal("0.01")),
                    "currency": cls.REPORT_CURRENCY,
                }
            )
        return sorted(out, key=lambda row: row["user"].display_name.lower())

    @classmethod
    def _build_pairwise_balances(cls, user_id, other_user_id=None, *, preloaded_expenses=None):
        balances = {}
        if preloaded_expenses is not None:
            if other_user_id is not None:
                raise ValueError("preloaded_expenses is only valid without other_user_id")
            expenses = preloaded_expenses
        else:
            expenses = (
                get_pairwise_expenses(user_id, other_user_id)
                if other_user_id
                else get_balance_expenses_for_user(user_id)
            )
        transactions = (
            get_pairwise_transactions(user_id, other_user_id)
            if other_user_id
            else get_transactions_for_user(user_id)
        ).filter(is_disputed=False)

        for expense in expenses:
            base_currency = expense.group.currency if expense.group_id else expense.currency
            for split in expense.splits.all():
                if split.user_id == expense.paid_by_id:
                    continue

                converted_amount = convert_amount(split.amount_owed, base_currency, cls.REPORT_CURRENCY)
                if expense.paid_by_id == user_id:
                    balances[split.user_id] = balances.get(split.user_id, Decimal("0.00")) + converted_amount
                elif split.user_id == user_id:
                    balances[expense.paid_by_id] = balances.get(expense.paid_by_id, Decimal("0.00")) - converted_amount

        for settlement in transactions:
            converted_amount = convert_amount(settlement.amount, settlement.currency, cls.REPORT_CURRENCY)
            if settlement.payer_id == user_id:
                balances[settlement.receiver_id] = balances.get(settlement.receiver_id, Decimal("0.00")) + converted_amount
            else:
                balances[settlement.payer_id] = balances.get(settlement.payer_id, Decimal("0.00")) - converted_amount

        return balances


class InvitationService:
    EXPIRATION_DAYS = 7
    TOKEN_QUERY_PARAM = "invite_token"

    @classmethod
    def create_invite(cls, inviter: User, *, email: str | None = None, phone: str | None = None) -> dict:
        token = secrets.token_urlsafe(32)
        invite = FriendInvite.objects.create(
            inviter=inviter,
            email=email,
            phone=phone,
            token=token,
            expires_at=timezone.now() + timedelta(days=cls.EXPIRATION_DAYS),
        )
        return {
            "invite": invite,
            "invite_url": cls._build_invite_url(token),
        }

    @classmethod
    def _build_invite_url(cls, token: str) -> str:
        parts = urlsplit(settings.FRONTEND_INVITE_URL)
        query = dict(parse_qsl(parts.query, keep_blank_values=True))
        query[cls.TOKEN_QUERY_PARAM] = token
        return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))

    @staticmethod
    def accept_invite(user: User, token: str) -> FriendInvite:
        invite = get_pending_invite_by_token(token)
        if not invite:
            raise ValueError("Friend invite was not found.")

        if invite.expires_at <= timezone.now():
            invite.status = FriendInviteStatus.EXPIRED
            invite.save(update_fields=["status", "updated_at"])
            raise ValueError("Friend invite has expired.")

        if invite.inviter_id == user.id:
            raise ValueError("You cannot accept your own friend invite.")

        invite_has_email = bool(invite.email)
        invite_has_phone = bool(invite.phone)
        if invite_has_email or invite_has_phone:
            email_matches = invite_has_email and invite.email == user.email
            phone_matches = invite_has_phone and bool(user.phone) and invite.phone == user.phone
            if not email_matches and not phone_matches:
                raise ValueError("This invite does not belong to the authenticated user.")

        invite.status = FriendInviteStatus.ACCEPTED
        invite.accepted_by = user
        invite.save(update_fields=["status", "accepted_by", "updated_at"])
        return invite
