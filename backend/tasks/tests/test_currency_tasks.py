from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest

from tasks.currency_tasks import refresh_exchange_rates


@pytest.mark.django_db
def test_refresh_creates_exchange_rate_records(settings, mock_exchange_api):
    from apps.currencies.models import ExchangeRate

    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_exchange_api({"USD": 0.2, "EUR": 0.18, "ARS": 0.001})

    refresh_exchange_rates()

    assert ExchangeRate.objects.filter(
        base_currency="BRL",
        quote_currency="USD",
    ).exists()
    assert ExchangeRate.objects.filter(
        base_currency="BRL",
        quote_currency="EUR",
    ).exists()
    assert ExchangeRate.objects.filter(
        base_currency="BRL",
        quote_currency="ARS",
    ).exists()


@pytest.mark.django_db
def test_refresh_stores_decimal_not_float(settings, mock_exchange_api):
    from apps.currencies.models import ExchangeRate

    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_exchange_api({"USD": 0.19876})

    refresh_exchange_rates()

    rate_obj = ExchangeRate.objects.get(base_currency="BRL", quote_currency="USD")
    assert rate_obj.rate == Decimal("0.19876")
    assert isinstance(rate_obj.rate, Decimal)


@pytest.mark.django_db
def test_refresh_skips_brl_to_brl(settings, mock_exchange_api):
    from apps.currencies.models import ExchangeRate

    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_exchange_api({"BRL": 1.0, "USD": 0.2})

    refresh_exchange_rates()

    assert not ExchangeRate.objects.filter(
        base_currency="BRL",
        quote_currency="BRL",
    ).exists()


@pytest.mark.django_db
def test_refresh_updates_existing_record(settings, mock_exchange_api):
    from apps.currencies.models import ExchangeRate

    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_exchange_api({"USD": 0.20})
    refresh_exchange_rates()

    mock_exchange_api({"USD": 0.21})
    refresh_exchange_rates()

    records = ExchangeRate.objects.filter(base_currency="BRL", quote_currency="USD")
    assert records.count() == 1
    assert records.first().rate == Decimal("0.21")


@pytest.mark.django_db
def test_refresh_invalidates_currency_cache(settings, mock_exchange_api, django_cache):
    settings.EXCHANGE_RATE_API_KEY = "test-key"
    django_cache.set("rachae:currencies:rates:BRL", {"USD": "0.20"}, timeout=3600)
    mock_exchange_api({"USD": 0.21})

    refresh_exchange_rates()

    assert django_cache.get("rachae:currencies:rates:BRL") is None


@pytest.mark.django_db
def test_refresh_retries_on_network_error(settings):
    settings.EXCHANGE_RATE_API_KEY = "test-key"

    with patch("requests.get", side_effect=Exception("Network timeout")):
        with pytest.raises(Exception, match="Network timeout"):
            refresh_exchange_rates.apply(throw=True)


@pytest.mark.django_db
def test_refresh_retries_on_http_error(settings):
    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_resp = MagicMock()
    mock_resp.raise_for_status.side_effect = Exception("HTTP 429")

    with patch("requests.get", return_value=mock_resp):
        with pytest.raises(Exception, match="HTTP 429"):
            refresh_exchange_rates.apply(throw=True)


@pytest.mark.django_db
def test_refresh_raises_on_empty_payload(settings):
    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"conversion_rates": {}}

    with patch("requests.get", return_value=mock_resp):
        with pytest.raises(Exception):
            refresh_exchange_rates.apply(throw=True)


@pytest.mark.django_db
def test_refresh_is_idempotent(settings, mock_exchange_api):
    from apps.currencies.models import ExchangeRate

    settings.EXCHANGE_RATE_API_KEY = "test-key"
    mock_exchange_api({"USD": 0.20, "EUR": 0.18})

    refresh_exchange_rates()
    refresh_exchange_rates()

    assert ExchangeRate.objects.filter(base_currency="BRL").count() == 2
