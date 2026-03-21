from decimal import Decimal, InvalidOperation

from django.utils import timezone

from apps.currencies.models import ExchangeRate

# MVP catalog aligned with common ISO codes (BRL-first product).
SUPPORTED_CURRENCIES: tuple[tuple[str, str, str], ...] = (
    ("BRL", "Brazilian Real", "R$"),
    ("USD", "US Dollar", "$"),
    ("EUR", "Euro", "€"),
    ("GBP", "British Pound", "£"),
    ("ARS", "Argentine Peso", "$"),
    ("CLP", "Chilean Peso", "$"),
    ("MXN", "Mexican Peso", "$"),
    ("CAD", "Canadian Dollar", "$"),
    ("JPY", "Japanese Yen", "¥"),
    ("CHF", "Swiss Franc", "CHF"),
)


class CurrencyService:
    @staticmethod
    def list_supported() -> list[dict]:
        return [
            {"code": c, "name": n, "symbol": s} for c, n, s in SUPPORTED_CURRENCIES
        ]

    @staticmethod
    def latest_rates_for_base(base: str) -> list[dict]:
        base_u = (base or "BRL").upper()
        rows = ExchangeRate.objects.filter(base_currency=base_u).order_by(
            "-fetched_at", "-created_at"
        )
        seen: set[str] = set()
        out: list[dict] = []
        for row in rows:
            if row.quote_currency in seen:
                continue
            seen.add(row.quote_currency)
            out.append(
                {
                    "base_currency": row.base_currency,
                    "quote_currency": row.quote_currency,
                    "rate": str(row.rate),
                    "fetched_at": row.fetched_at,
                }
            )
        return out

    @staticmethod
    def convert(*, from_currency: str, to_currency: str, amount: str) -> dict:
        try:
            amount_dec = Decimal(str(amount))
        except (InvalidOperation, TypeError, ValueError) as exc:
            raise ValueError("Invalid amount.") from exc

        fc = (from_currency or "").strip().upper()
        tc = (to_currency or "").strip().upper()
        if not fc or not tc:
            raise ValueError("from and to currency codes are required.")

        if amount_dec.copy_abs() > Decimal("999999999999.99"):
            raise ValueError("Amount out of supported range.")

        now = timezone.now()
        if fc == tc:
            res = amount_dec.quantize(Decimal("0.01"))
            return {
                "result": str(res),
                "rate": "1",
                "fetched_at": now,
            }

        row = (
            ExchangeRate.objects.filter(base_currency=fc, quote_currency=tc)
            .order_by("-fetched_at")
            .first()
        )
        if row is not None:
            r = row.rate
            res = (amount_dec * r).quantize(Decimal("0.01"))
            eff = (
                (res / amount_dec).quantize(Decimal("0.000001"))
                if amount_dec != 0
                else r
            )
            return {
                "result": str(res),
                "rate": str(eff),
                "fetched_at": row.fetched_at.isoformat(),
            }

        row_inv = (
            ExchangeRate.objects.filter(base_currency=tc, quote_currency=fc)
            .order_by("-fetched_at")
            .first()
        )
        if row_inv is not None:
            r = row_inv.rate
            res = (amount_dec / r).quantize(Decimal("0.01"))
            eff = (
                (res / amount_dec).quantize(Decimal("0.000001"))
                if amount_dec != 0
                else (Decimal("1") / r).quantize(Decimal("0.000001"))
            )
            return {
                "result": str(res),
                "rate": str(eff),
                "fetched_at": row_inv.fetched_at.isoformat(),
            }

        raise ValueError(f"Exchange rate not available for {fc} -> {tc}.")
