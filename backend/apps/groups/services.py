from decimal import Decimal
from importlib import import_module

from django.db import transaction
from django.db.models import Sum
from django.shortcuts import get_object_or_404

from apps.groups.algorithms import run_min_cash_flow
from apps.groups.models import Group, GroupMember, GroupRole
from apps.groups.queries import admin_count, get_group_members, get_membership, get_user_groups
from apps.users.models import User

ZERO = Decimal("0.00")


def _schedule_group_ledger_recalculation(group_id) -> None:
    try:
        ledger_tasks = import_module("tasks.ledger_tasks")
    except ModuleNotFoundError:
        return

    transaction.on_commit(lambda: ledger_tasks.recalculate_group_ledger.delay(str(group_id)))


class GroupService:
    @staticmethod
    def list_for_user(user: User):
        groups = list(get_user_groups(user))

        for group in groups:
            group.member_count = len(group.members.all())
            balances_payload = BalanceService.group_balances(group)
            your_balance = next(
                (
                    item["net_balance"]
                    for item in balances_payload["balances"]
                    if item["user_id"] == user.id
                ),
                ZERO,
            )
            group.your_net_balance = your_balance

        return groups

    @staticmethod
    def create_group(creator: User, validated_data: dict) -> Group:
        member_ids = validated_data.pop("member_ids", [])

        with transaction.atomic():
            group = Group.objects.create(created_by=creator, **validated_data)
            GroupMember.objects.create(group=group, user=creator, role=GroupRole.ADMIN)

            extra_members = [
                GroupMember(group=group, user=user, role=GroupRole.MEMBER)
                for user in User.objects.filter(id__in=member_ids).exclude(id=creator.id)
            ]
            if extra_members:
                GroupMember.objects.bulk_create(extra_members)

            _schedule_group_ledger_recalculation(group.id)

        return group

    @staticmethod
    def get_detail(group: Group, requesting_user: User) -> Group:
        del requesting_user
        group.net_balances = BalanceService.group_balances(group)["balances"]
        return group

    @staticmethod
    def update_group(group: Group, validated_data: dict) -> Group:
        if "currency" in validated_data and validated_data["currency"] != group.currency:
            try:
                from apps.expenses.models import Expense as expense_model
            except ImportError:
                expense_model = None

            if expense_model and expense_model.objects.filter(group=group, is_deleted=False).exists():
                raise ValueError("Cannot change currency after expenses have been added.")

        simplify_debts_changed = (
            "simplify_debts" in validated_data
            and validated_data["simplify_debts"] != group.simplify_debts
        )

        updated_fields = []
        for field, value in validated_data.items():
            if getattr(group, field) != value:
                setattr(group, field, value)
                updated_fields.append(field)

        if updated_fields:
            updated_fields.append("updated_at")
            group.save(update_fields=updated_fields)

        if simplify_debts_changed:
            _schedule_group_ledger_recalculation(group.id)

        return group

    @staticmethod
    def delete_group(group: Group, actor: User) -> None:
        del actor
        group.soft_delete()


class MemberService:
    @staticmethod
    def list_members(group: Group):
        return get_group_members(group)

    @staticmethod
    def add_member(group: Group, user_id, role: str, inviter: User) -> GroupMember:
        user = get_object_or_404(User, id=user_id)

        if GroupMember.objects.filter(group=group, user=user).exists():
            raise ValueError("User is already a member of this group.")

        with transaction.atomic():
            membership = GroupMember.objects.create(
                group=group,
                user=user,
                role=role,
                invited_by=inviter,
            )
            _schedule_group_ledger_recalculation(group.id)

        return membership

    @staticmethod
    def change_role(group: Group, target_user_id, new_role: str, actor: User | None = None) -> GroupMember:
        membership = get_object_or_404(GroupMember, group=group, user_id=target_user_id)

        if (
            actor is not None
            and actor.id == membership.user_id
            and membership.role == GroupRole.ADMIN
            and new_role != GroupRole.ADMIN
            and admin_count(group) == 1
        ):
            raise ValueError("Cannot change your own role — you are the last admin.")

        if membership.role != new_role:
            membership.role = new_role
            membership.save(update_fields=["role"])

        return membership

    @staticmethod
    def remove_member(group: Group, target_user_id, actor: User) -> None:
        if actor.id == target_user_id:
            raise ValueError("Use the leave endpoint to remove yourself from the group.")

        membership = get_object_or_404(GroupMember, group=group, user_id=target_user_id)
        if membership.role == GroupRole.ADMIN and admin_count(group) == 1:
            raise ValueError("Cannot remove the last admin. Transfer admin role first.")

        with transaction.atomic():
            membership.delete()
            _schedule_group_ledger_recalculation(group.id)

    @staticmethod
    def leave_group(group: Group, user: User) -> None:
        membership = get_membership(user, group)
        if not membership:
            raise ValueError("You are not a member of this group.")

        if membership.role == GroupRole.ADMIN and admin_count(group) == 1:
            raise ValueError("You are the last admin. Transfer the admin role before leaving.")

        with transaction.atomic():
            membership.delete()
            _schedule_group_ledger_recalculation(group.id)


class BalanceService:
    @classmethod
    def group_balances(cls, group: Group) -> dict:
        try:
            from apps.expenses.models import Expense
            from apps.splits.models import Split
        except ImportError:
            return {
                "group_id": group.id,
                "currency": group.currency,
                "balances": [],
            }

        paid_totals = {
            item["paid_by_id"]: item["total"] or ZERO
            for item in Expense.objects.filter(
                group=group,
                is_deleted=False,
            )
            .values("paid_by_id")
            .annotate(total=Sum("amount_in_group_currency"))
        }
        owed_totals = {
            item["user_id"]: item["total"] or ZERO
            for item in Split.objects.filter(
                expense__group=group,
                expense__is_deleted=False,
                is_settled=False,
            )
            .values("user_id")
            .annotate(total=Sum("amount_owed"))
        }

        balances = []
        for membership in get_group_members(group):
            paid = paid_totals.get(membership.user_id, ZERO)
            owed = owed_totals.get(membership.user_id, ZERO)
            balances.append(
                {
                    "user_id": membership.user_id,
                    "display_name": membership.user.display_name,
                    "net_balance": paid - owed,
                }
            )

        return {
            "group_id": group.id,
            "currency": group.currency,
            "balances": balances,
        }

    @classmethod
    def simplified_balances(cls, group: Group) -> dict:
        if not group.simplify_debts:
            return {
                "group_id": group.id,
                "currency": group.currency,
                "simplify_debts": False,
                "suggestions": [],
            }

        balances_payload = cls.group_balances(group)
        net_balances = {
            str(item["user_id"]): item["net_balance"]
            for item in balances_payload["balances"]
        }
        member_names = {
            str(item["user_id"]): item["display_name"]
            for item in balances_payload["balances"]
        }

        suggestions = [
            {
                "payer_id": suggestion["payer_id"],
                "payer_name": member_names.get(str(suggestion["payer_id"]), ""),
                "receiver_id": suggestion["receiver_id"],
                "receiver_name": member_names.get(str(suggestion["receiver_id"]), ""),
                "amount": suggestion["amount"],
            }
            for suggestion in run_min_cash_flow(net_balances)
        ]

        return {
            "group_id": group.id,
            "currency": group.currency,
            "simplify_debts": True,
            "suggestions": suggestions,
        }


class ReportService:
    @staticmethod
    def group_report(group: Group, date_from=None, date_to=None) -> dict:
        per_person_spend = [
            {
                "user_id": membership.user_id,
                "display_name": membership.user.display_name,
                "total_paid": ZERO,
                "total_owed": ZERO,
                "net": ZERO,
            }
            for membership in get_group_members(group)
        ]

        try:
            from apps.transactions.models import Transaction

            txn_qs = Transaction.objects.filter(
                group=group,
                is_confirmed=True,
            ).select_related("payer", "receiver")
            if date_from:
                txn_qs = txn_qs.filter(created_at__date__gte=date_from)
            if date_to:
                txn_qs = txn_qs.filter(created_at__date__lte=date_to)
            settlements = list(
                txn_qs.values(
                    "id",
                    "payer__display_name",
                    "receiver__display_name",
                    "amount",
                    "currency",
                    "is_confirmed",
                    "created_at",
                )
            )
        except ImportError:
            settlements = []

        return {
            "group_id": group.id,
            "group_name": group.name,
            "currency": group.currency,
            "date_from": date_from,
            "date_to": date_to,
            "total_spent": ZERO,
            "per_person_spend": per_person_spend,
            "expenses": [],
            "settlements": settlements,
        }
