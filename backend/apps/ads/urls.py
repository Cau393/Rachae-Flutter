from django.urls import path

from apps.ads.views import (
    AdsStatusView,
    CreateCheckoutSessionView,
    CreatePortalSessionView,
    StripeWebhookView,
)

urlpatterns = [
    path("ads/status/", AdsStatusView.as_view()),
    path("ads/create-checkout-session/", CreateCheckoutSessionView.as_view()),
    path("ads/create-portal-session/", CreatePortalSessionView.as_view()),
    path("ads/stripe-webhook/", StripeWebhookView.as_view()),
]
