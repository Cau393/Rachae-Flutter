from django.db import models

from core.models import BaseModel


class ExchangeRate(BaseModel):
    base_currency = models.CharField(max_length=3, db_index=True)
    quote_currency = models.CharField(max_length=3, db_index=True)
    rate = models.DecimalField(max_digits=14, decimal_places=6)
    fetched_at = models.DateTimeField(db_index=True)

    class Meta:
        db_table = "exchange_rates"
        ordering = ["-fetched_at"]
