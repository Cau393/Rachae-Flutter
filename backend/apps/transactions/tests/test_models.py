from django.test import TestCase

from apps.transactions.models import Transaction

from .test_services import TransactionTestMixin


class TransactionModelTests(TransactionTestMixin, TestCase):
    def test_transaction_defaults_to_pending_and_not_disputed(self):
        transaction = self.create_transaction()

        self.assertFalse(transaction.is_confirmed)
        self.assertFalse(transaction.is_disputed)

    def test_transaction_model_has_no_is_deleted_field(self):
        field_names = [field.name for field in Transaction._meta.get_fields()]

        self.assertNotIn("is_deleted", field_names)
        self.assertFalse(hasattr(Transaction(), "is_deleted"))

    def test_transaction_model_declares_expected_composite_indexes(self):
        index_fields = {tuple(index.fields) for index in Transaction._meta.indexes}

        self.assertIn(("payer", "is_confirmed"), index_fields)
        self.assertIn(("receiver", "is_confirmed"), index_fields)
        self.assertIn(("group", "is_confirmed"), index_fields)
