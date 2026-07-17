import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import Mock, patch

import jwt
from cryptography.hazmat.primitives.asymmetric import rsa
from django.conf import settings
from django.test import RequestFactory, TestCase
from rest_framework.exceptions import AuthenticationFailed, NotFound, ValidationError
from rest_framework.test import APIClient

from core.authentication import verify_supabase_token
from core.exceptions import logging_exception_handler


class HealthCheckViewTests(TestCase):
    def test_health_endpoint_returns_ok_payload(self):
        client = APIClient()

        response = client.get("/api/v1/health/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"data": {"status": "ok"}})


class LoggingExceptionHandlerTests(TestCase):
    def _context(self, path="/api/v1/expenses/"):
        return {"request": RequestFactory().post(path)}

    def test_validation_error_still_returns_400_response(self):
        response = logging_exception_handler(
            ValidationError({"splits": "Users x do not exist."}), self._context()
        )

        self.assertEqual(response.status_code, 400)

    def test_validation_error_logs_path_and_detail_at_warning(self):
        with self.assertLogs("core.exceptions", level="WARNING") as logs:
            logging_exception_handler(
                ValidationError({"splits": "Users x do not exist."}), self._context()
            )

        self.assertIn("/api/v1/expenses/", logs.output[0])

    def test_not_found_is_logged_like_any_other_client_error(self):
        with self.assertLogs("core.exceptions", level="WARNING") as logs:
            logging_exception_handler(NotFound(), self._context())

        self.assertIn("404", logs.output[0])

    def test_non_api_exception_returns_none_unchanged(self):
        response = logging_exception_handler(ValueError("boom"), self._context())

        self.assertIsNone(response)


class VerifySupabaseTokenAudienceTests(TestCase):
    """Exercises the real jwt.decode(...) call in verify_supabase_token.

    Every other test in the suite mocks verify_supabase_token or bypasses
    auth with force_authenticate, so the actual signature/audience
    validation never ran anywhere — a wrong SUPABASE_JWT_AUDIENCE value
    would silently lock out every user and nothing would catch it. This
    mocks only the JWKS lookup (the network boundary, via get_jwk_client)
    and lets jwt.decode really verify the signature, issuer, and audience
    against a locally-generated RSA keypair.
    """

    def setUp(self):
        super().setUp()
        self.private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.subject = str(uuid.uuid4())

    def _make_token(self, *, audience):
        now = datetime.now(timezone.utc)
        payload = {
            "sub": self.subject,
            "iss": settings.SUPABASE_ISSUER,
            "aud": audience,
            "iat": now,
            "exp": now + timedelta(hours=1),
        }
        return jwt.encode(payload, self.private_key, algorithm="RS256")

    def _mock_jwk_client(self):
        signing_key = Mock(key=self.private_key.public_key())
        mock_client = Mock()
        mock_client.get_signing_key_from_jwt.return_value = signing_key
        return patch("core.authentication.get_jwk_client", return_value=mock_client)

    def test_token_with_correct_audience_is_accepted(self):
        token = self._make_token(audience=settings.SUPABASE_JWT_AUDIENCE)

        with self._mock_jwk_client():
            payload = verify_supabase_token(token)

        self.assertEqual(payload["sub"], self.subject)

    def test_token_with_wrong_audience_is_rejected(self):
        token = self._make_token(audience="wrong-audience")

        with self._mock_jwk_client():
            with self.assertRaises(AuthenticationFailed):
                verify_supabase_token(token)
