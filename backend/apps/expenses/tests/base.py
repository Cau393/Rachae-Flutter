import uuid
from decimal import Decimal

from rest_framework.test import APIClient

from apps.expenses.models import Expense, SplitMethod
from apps.groups.models import Group, GroupMember, GroupRole, GroupType
from apps.splits.models import Split
from apps.users.models import User


class ExpenseTestMixin:
    def setUp(self):
        super().setUp()
        self.client = APIClient()
        self.user = self.create_user("owner@example.com", "+5511999999999", "Owner User")
        self.member_user = self.create_user("member@example.com", "+5511888888888", "Member User")
        self.third_user = self.create_user("third@example.com", "+5511777777777", "Third User")
        self.other_user = self.create_user("other@example.com", "+5511666666666", "Other User")

        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        self.add_membership(self.group, self.third_user, GroupRole.MEMBER)

    def create_user(self, email: str, phone: str, display_name: str) -> User:
        return User.objects.create(
            supabase_uid=uuid.uuid4(),
            email=email,
            phone=phone,
            display_name=display_name,
        )

    def create_group(
        self,
        *,
        created_by=None,
        name: str = "Trip Group",
        description: str | None = None,
        group_type: str = GroupType.TRIP,
        currency: str = "BRL",
        simplify_debts: bool = True,
    ) -> Group:
        return Group.objects.create(
            name=name,
            description=description,
            type=group_type,
            currency=currency,
            created_by=created_by or self.user,
            simplify_debts=simplify_debts,
        )

    def add_membership(
        self,
        group: Group,
        user: User,
        role: str = GroupRole.MEMBER,
        invited_by=None,
    ) -> GroupMember:
        return GroupMember.objects.create(
            group=group,
            user=user,
            role=role,
            invited_by=invited_by,
        )

    def authenticate(self, user=None):
        self.client.force_authenticate(user=user or self.user)

    def create_expense(
        self,
        *,
        group=None,
        paid_by=None,
        created_by=None,
        amount="60.00",
        currency="BRL",
        exchange_rate_to_group_currency="1.000000",
        amount_in_group_currency=None,
        description="Groceries",
        category="geral",
        split_method=SplitMethod.EQUAL,
        receipt_urls=None,
    ) -> Expense:
        normalized_amount = Decimal(str(amount)).quantize(Decimal("0.01"))
        normalized_amount_in_group_currency = Decimal(
            str(amount_in_group_currency if amount_in_group_currency is not None else amount)
        ).quantize(Decimal("0.01"))

        return Expense.objects.create(
            group=group,
            paid_by=paid_by or self.user,
            amount=normalized_amount,
            currency=currency,
            exchange_rate_to_group_currency=exchange_rate_to_group_currency,
            amount_in_group_currency=normalized_amount_in_group_currency,
            description=description,
            category=category,
            split_method=split_method,
            created_by=created_by or self.user,
            receipt_urls=receipt_urls or [],
        )

    def create_split(
        self,
        expense: Expense,
        user: User,
        amount_owed,
        *,
        share_value=None,
        is_settled=False,
    ) -> Split:
        return Split.objects.create(
            expense=expense,
            user=user,
            amount_owed=Decimal(str(amount_owed)).quantize(Decimal("0.01")),
            share_value=share_value,
            is_settled=is_settled,
        )
