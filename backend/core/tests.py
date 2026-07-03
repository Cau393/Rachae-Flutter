from django.test import RequestFactory, TestCase
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.test import APIClient

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
