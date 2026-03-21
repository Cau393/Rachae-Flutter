from django.urls import path

from apps.currencies.views import (
    ConvertCurrencyView,
    ExchangeRatesView,
    SupportedCurrenciesView,
)

urlpatterns = [
    path("currencies/", SupportedCurrenciesView.as_view(), name="currencies-supported"),
    path("currencies/rates/", ExchangeRatesView.as_view(), name="currencies-rates"),
    path("currencies/convert/", ConvertCurrencyView.as_view(), name="currencies-convert"),
]
