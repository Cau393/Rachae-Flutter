from django.urls import path

from apps.ads.views import (
    AdsStatusView,
    CreateCheckoutSessionView,
    CreatePortalSessionView,
    RevenueCatWebhookView,
    StripeWebhookView,
)

urlpatterns = [
    path("ads/status/", AdsStatusView.as_view()),
    path("ads/create-checkout-session/", CreateCheckoutSessionView.as_view()),
    path("ads/create-portal-session/", CreatePortalSessionView.as_view()),
    # Alias: Stripe CLI / docs often use .../ads/webhook/; canonical path is stripe-webhook.
    path("ads/webhook/", StripeWebhookView.as_view()),
    path("ads/stripe-webhook/", StripeWebhookView.as_view()),
    path("ads/revenuecat-webhook/", RevenueCatWebhookView.as_view()),
]
