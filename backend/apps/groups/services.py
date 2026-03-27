from collections import defaultdict
from decimal import Decimal
from importlib import import_module

from django.db import transaction
from django.shortcuts import get_object_or_404

from apps.ledger.algorithms import compute_group_net_balances, run_min_cash_flow
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
    def list_eligible_groups_for_friend(requesting_user: User, friend_user_id) -> list[Group]:
        get_object_or_404(User, id=friend_user_id, is_deleted=False)

        groups = list(
            Group.objects.filter(
                is_deleted=False,
                members__user=requesting_user,
                members__role=GroupRole.ADMIN,
                members__is_deleted=False,
            )
            .exclude(
                members__user_id=friend_user_id,
                members__is_deleted=False,
            )
            .distinct()
            .prefetch_related("members__user")
            .order_by("name", "created_at")
        )

        for group in groups:
            group.member_count = len(
                [
                    membership
                    for membership in group.members.all()
                    if not getattr(membership, "is_deleted", False)
                ]
            )

        return groups

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
            and actor.id != membership.user_id
            and membership.user_id == group.created_by_id
            and membership.role == GroupRole.ADMIN
            and new_role != GroupRole.ADMIN
        ):
            raise ValueError("Cannot demote the group creator.")

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
        if membership.user_id == group.created_by_id:
            raise ValueError("Cannot remove the group creator.")

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
        net_totals = compute_group_net_balances(str(group.id))

        balances = []
        for membership in get_group_members(group):
            balances.append(
                {
                    "user_id": membership.user_id,
                    "display_name": membership.user.display_name,
                    "net_balance": net_totals.get(str(membership.user_id), ZERO),
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
        from apps.expenses.models import Expense

        cent = Decimal("0.01")
        expense_qs = (
            Expense.objects.filter(group=group, is_deleted=False)
            .select_related("paid_by")
            .prefetch_related("splits")
            .order_by("-expense_date", "-created_at")
        )
        if date_from is not None:
            expense_qs = expense_qs.filter(expense_date__gte=date_from)
        if date_to is not None:
            expense_qs = expense_qs.filter(expense_date__lte=date_to)

        total_spent = ZERO
        expenses_out = []
        paid_by_user = defaultdict(lambda: ZERO)
        owed_by_user = defaultdict(lambda: ZERO)

        for expense in expense_qs:
            ag = Decimal(str(expense.amount_in_group_currency)).quantize(cent)
            total_spent = (total_spent + ag).quantize(cent)
            pid = expense.paid_by_id
            paid_by_user[pid] = (paid_by_user[pid] + ag).quantize(cent)
            expenses_out.append(
                {
                    "description": expense.description,
                    "amount_in_group_currency": str(ag),
                    "expense_date": expense.expense_date.isoformat(),
                    "category": expense.category,
                }
            )
            for split in expense.splits.all():
                if split.is_deleted:
                    continue
                ow = Decimal(str(split.amount_owed)).quantize(cent)
                uid = split.user_id
                owed_by_user[uid] = (owed_by_user[uid] + ow).quantize(cent)

        per_person_spend = []
        for membership in get_group_members(group):
            uid = membership.user_id
            tp = paid_by_user[uid].quantize(cent)
            to_ = owed_by_user[uid].quantize(cent)
            net = (tp - to_).quantize(cent)
            per_person_spend.append(
                {
                    "user_id": uid,
                    "display_name": membership.user.display_name,
                    "total_paid": tp,
                    "total_owed": to_,
                    "net": net,
                }
            )

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
            "total_spent": total_spent.quantize(cent),
            "per_person_spend": per_person_spend,
            "expenses": expenses_out,
            "settlements": settlements,
        }
