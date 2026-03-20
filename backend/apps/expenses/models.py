from decimal import Decimal

from django.db import models
from django.utils import timezone

from core.models import BaseModel


class SplitMethod(models.TextChoices):
    EQUAL = "equal", "Equal"
    EXACT = "exact", "Exact"
    PERCENTAGE = "percentage", "Percentage"
    SHARES = "shares", "Shares"


class Expense(BaseModel):
    group = models.ForeignKey(
        "groups.Group",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="expenses",
    )
    paid_by = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="paid_expenses",
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="BRL")
    exchange_rate_to_group_currency = models.DecimalField(
        max_digits=14,
        decimal_places=6,
        default=Decimal("1.000000"),
    )
    amount_in_group_currency = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.CharField(max_length=255)
    category = models.CharField(max_length=50, default="geral")
    expense_date = models.DateField(default=timezone.localdate)
    split_method = models.CharField(max_length=10, choices=SplitMethod.choices, default=SplitMethod.EQUAL)
    receipt_urls = models.JSONField(default=list, blank=True)
    created_by = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="created_expenses",
    )
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "expenses"
        ordering = ["-created_at"]

    def soft_delete(self):
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=["is_deleted", "deleted_at", "updated_at"])
