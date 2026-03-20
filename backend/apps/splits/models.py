from django.db import models

from core.models import BaseModel


class Split(BaseModel):
    expense = models.ForeignKey(
        "expenses.Expense",
        on_delete=models.PROTECT,
        related_name="splits",
    )
    user = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="splits",
    )
    amount_owed = models.DecimalField(max_digits=12, decimal_places=2)
    share_value = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
    is_settled = models.BooleanField(default=False)

    class Meta:
        db_table = "splits"
        ordering = ["created_at"]
