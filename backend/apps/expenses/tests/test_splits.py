import uuid
from decimal import Decimal

from django.test import SimpleTestCase
from rest_framework.exceptions import ValidationError

from apps.expenses.services import SplitService


class SplitServiceTests(SimpleTestCase):
    def test_equal_split_rounding_assigns_extra_cent_to_first_participant(self):
        user_ids = [uuid.uuid4(), uuid.uuid4(), uuid.uuid4()]

        splits = SplitService.compute_splits(
            method="equal",
            splits_data=[{"user_id": user_id} for user_id in user_ids],
            amount_in_group_currency=Decimal("100.00"),
        )

        self.assertEqual(
            [split["amount_owed"] for split in splits],
            [Decimal("33.34"), Decimal("33.33"), Decimal("33.33")],
        )
        self.assertEqual(
            sum(split["amount_owed"] for split in splits),
            Decimal("100.00"),
        )

    def test_percentage_validation_rejects_values_that_do_not_sum_to_one_hundred(self):
        splits_data = [
            {"user_id": uuid.uuid4(), "share_value": Decimal("40.00")},
            {"user_id": uuid.uuid4(), "share_value": Decimal("35.00")},
            {"user_id": uuid.uuid4(), "share_value": Decimal("26.00")},
        ]

        with self.assertRaises(ValidationError) as exc_info:
            SplitService.validate_splits(
                "percentage",
                splits_data,
                Decimal("120.00"),
            )

        self.assertIn("Percentages sum to 101.00, must be 100.", str(exc_info.exception))
