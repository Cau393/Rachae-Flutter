import uuid
from decimal import Decimal

from django.core.validators import MinValueValidator
from django.db import models


class Transaction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    group = models.ForeignKey(
        "groups.Group",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="transactions",
    )
    payer = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="payments_made",
    )
    receiver = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="payments_received",
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    currency = models.CharField(max_length=3, default="BRL")
    note = models.TextField(null=True, blank=True)
    proof_urls = models.JSONField(default=list, blank=True)
    is_confirmed = models.BooleanField(default=False)
    is_disputed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "transactions"
        indexes = [
            models.Index(fields=["payer", "is_confirmed"]),
            models.Index(fields=["receiver", "is_confirmed"]),
            models.Index(fields=["group", "is_confirmed"]),
        ]

    def __str__(self):
        return f"{self.payer} -> {self.receiver}: {self.amount} {self.currency}"
