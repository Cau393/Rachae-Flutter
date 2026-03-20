import logging
from decimal import Decimal

from celery import shared_task

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=300, task_acks_late=True)
def refresh_exchange_rates(self):
    try:
        import requests
        from django.conf import settings
        from django.core.cache import cache
        from django.utils.timezone import now

        from apps.currencies.models import ExchangeRate

        api_key = settings.EXCHANGE_RATE_API_KEY
        base = "BRL"
        url = f"{settings.EXCHANGE_RATE_API_URL}/{api_key}/latest/{base}"

        logger.info("[currency_tasks] refresh_exchange_rates: fetching url=%s", url)

        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        rates = data.get("conversion_rates", {})
        if not rates:
            raise ValueError("Empty conversion_rates payload received from exchange rate API.")

        updated = 0
        for quote_currency, rate_value in rates.items():
            if quote_currency == base:
                continue

            ExchangeRate.objects.update_or_create(
                base_currency=base,
                quote_currency=quote_currency,
                defaults={
                    "rate": Decimal(str(rate_value)),
                    "fetched_at": now(),
                },
            )
            updated += 1

        try:
            cache.delete_pattern("rachae:currencies:*")
        except AttributeError:
            for key in ["rachae:currencies:rates:BRL", "rachae:currencies:list"]:
                cache.delete(key)

        logger.info("[currency_tasks] refresh_exchange_rates: updated=%d base=%s", updated, base)
    except Exception as exc:
        logger.error("[currency_tasks] refresh_exchange_rates failed: %s", exc)
        raise self.retry(exc=exc)
