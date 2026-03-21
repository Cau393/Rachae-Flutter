import uuid
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.currencies.models import ExchangeRate
from apps.users.models import User


class CurrenciesApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create(
            supabase_uid=uuid.uuid4(),
            email="cur@example.com",
            phone="+5511999999999",
            display_name="Cur User",
        )

    def test_currencies_list_requires_auth(self):
        r = self.client.get("/api/v1/currencies/")
        self.assertEqual(r.status_code, 401)

    def test_currencies_list_returns_data_envelope(self):
        self.client.force_authenticate(user=self.user)
        r = self.client.get("/api/v1/currencies/")
        self.assertEqual(r.status_code, 200)
        data = r.json()["data"]
        self.assertIsInstance(data, list)
        codes = {row["code"] for row in data}
        self.assertIn("BRL", codes)
        self.assertIn("USD", codes)
        brl = next(x for x in data if x["code"] == "BRL")
        self.assertIn("name", brl)
        self.assertIn("symbol", brl)

    def test_rates_requires_auth(self):
        r = self.client.get("/api/v1/currencies/rates/")
        self.assertEqual(r.status_code, 401)

    def test_rates_returns_latest_per_quote(self):
        now = timezone.now()
        ExchangeRate.objects.create(
            base_currency="BRL",
            quote_currency="USD",
            rate=Decimal("0.200000"),
            fetched_at=now,
        )
        ExchangeRate.objects.create(
            base_currency="BRL",
            quote_currency="USD",
            rate=Decimal("0.210000"),
            fetched_at=now,
        )
        ExchangeRate.objects.create(
            base_currency="BRL",
            quote_currency="EUR",
            rate=Decimal("0.180000"),
            fetched_at=now,
        )
        self.client.force_authenticate(user=self.user)
        r = self.client.get("/api/v1/currencies/rates/", {"base": "BRL"})
        self.assertEqual(r.status_code, 200)
        rows = r.json()["data"]
        self.assertEqual(len(rows), 2)
        usd = next(x for x in rows if x["quote_currency"] == "USD")
        self.assertEqual(usd["rate"], "0.210000")

    def test_convert_requires_auth(self):
        r = self.client.get(
            "/api/v1/currencies/convert/",
            {"from": "BRL", "to": "USD", "amount": "10.00"},
        )
        self.assertEqual(r.status_code, 401)

    def test_convert_direct_pair(self):
        ExchangeRate.objects.create(
            base_currency="BRL",
            quote_currency="USD",
            rate=Decimal("0.200000"),
            fetched_at=timezone.now(),
        )
        self.client.force_authenticate(user=self.user)
        r = self.client.get(
            "/api/v1/currencies/convert/",
            {"from": "BRL", "to": "USD", "amount": "10.00"},
        )
        self.assertEqual(r.status_code, 200)
        body = r.json()["data"]
        self.assertEqual(body["result"], "2.00")
        self.assertIn("rate", body)
        self.assertIn("fetched_at", body)

    def test_convert_inverse_pair(self):
        ExchangeRate.objects.create(
            base_currency="BRL",
            quote_currency="USD",
            rate=Decimal("0.200000"),
            fetched_at=timezone.now(),
        )
        self.client.force_authenticate(user=self.user)
        r = self.client.get(
            "/api/v1/currencies/convert/",
            {"from": "USD", "to": "BRL", "amount": "2.00"},
        )
        self.assertEqual(r.status_code, 200)
        body = r.json()["data"]
        self.assertEqual(body["result"], "10.00")

    def test_convert_missing_rate_returns_400(self):
        self.client.force_authenticate(user=self.user)
        r = self.client.get(
            "/api/v1/currencies/convert/",
            {"from": "BRL", "to": "XXX", "amount": "10.00"},
        )
        self.assertEqual(r.status_code, 400)

    def test_convert_same_currency(self):
        self.client.force_authenticate(user=self.user)
        r = self.client.get(
            "/api/v1/currencies/convert/",
            {"from": "BRL", "to": "BRL", "amount": "10.00"},
        )
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["data"]["result"], "10.00")
        self.assertEqual(r.json()["data"]["rate"], "1")
