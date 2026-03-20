from decimal import Decimal
from unittest.mock import patch

import pytest


@pytest.mark.django_db
def test_recalculate_stores_balances_in_redis(group_with_expenses, django_cache):
    from tasks.ledger_tasks import recalculate_group_ledger

    group, _users = group_with_expenses

    recalculate_group_ledger(str(group.id))

    cache_key = f"rachae:ledger:group:{group.id}:balances"
    cached = django_cache.get(cache_key)

    assert cached is not None
    assert isinstance(cached, dict)
    for value in cached.values():
        assert isinstance(value, str)
        Decimal(value)


@pytest.mark.django_db
def test_recalculate_invalidates_per_user_cache(group_with_expenses, django_cache):
    from tasks.ledger_tasks import recalculate_group_ledger

    group, users = group_with_expenses

    for user in users:
        django_cache.set(f"rachae:ledger:user:{user.id}:net_balances", {"stale": True})

    recalculate_group_ledger(str(group.id))

    for user in users:
        assert django_cache.get(f"rachae:ledger:user:{user.id}:net_balances") is None


@pytest.mark.django_db
def test_recalculate_correct_balance_values(group_with_expenses, django_cache):
    from tasks.ledger_tasks import recalculate_group_ledger

    group, users = group_with_expenses

    recalculate_group_ledger(str(group.id))

    cached = django_cache.get(f"rachae:ledger:group:{group.id}:balances")

    assert Decimal(cached[str(users[0].id)]) > Decimal("0")


@pytest.mark.django_db
def test_recalculate_is_idempotent(group_with_expenses, django_cache):
    from tasks.ledger_tasks import recalculate_group_ledger

    group, _users = group_with_expenses

    recalculate_group_ledger(str(group.id))
    first_result = django_cache.get(f"rachae:ledger:group:{group.id}:balances")

    recalculate_group_ledger(str(group.id))
    second_result = django_cache.get(f"rachae:ledger:group:{group.id}:balances")

    assert first_result == second_result


def test_recalculate_retries_on_exception():
    from tasks.ledger_tasks import recalculate_group_ledger

    with patch(
        "tasks.ledger_tasks.compute_group_net_balances",
        side_effect=Exception("DB error"),
        create=True,
    ):
        with pytest.raises(Exception, match="DB error"):
            recalculate_group_ledger.apply(args=["invalid-group-id"])


@pytest.mark.django_db
def test_run_debt_simplification_stores_suggestions(group_with_expenses, django_cache):
    from tasks.ledger_tasks import run_debt_simplification

    group, _users = group_with_expenses
    group.simplify_debts = True
    group.save(update_fields=["simplify_debts"])

    run_debt_simplification(str(group.id))

    cache_key = f"rachae:ledger:group:{group.id}:simplified"
    cached = django_cache.get(cache_key)

    assert cached is not None
    assert isinstance(cached, list)
    for suggestion in cached:
        assert isinstance(suggestion["amount"], str)
        Decimal(suggestion["amount"])


@pytest.mark.django_db
def test_run_debt_simplification_stores_empty_when_disabled(group_simplify_off, django_cache):
    from tasks.ledger_tasks import run_debt_simplification

    group = group_simplify_off

    run_debt_simplification(str(group.id))

    cached = django_cache.get(f"rachae:ledger:group:{group.id}:simplified")
    assert cached == []


@pytest.mark.django_db
def test_run_debt_simplification_handles_missing_group():
    from tasks.ledger_tasks import run_debt_simplification

    run_debt_simplification.apply(args=["00000000-0000-0000-0000-000000000000"])


@pytest.mark.django_db
def test_run_debt_simplification_handles_deleted_group(deleted_group, django_cache):
    from tasks.ledger_tasks import run_debt_simplification

    run_debt_simplification.apply(args=[str(deleted_group.id)])

    cache_key = f"rachae:ledger:group:{deleted_group.id}:simplified"
    assert django_cache.get(cache_key) is None


@pytest.mark.django_db
def test_run_debt_simplification_conservation_property(group_with_expenses, django_cache):
    from tasks.ledger_tasks import recalculate_group_ledger, run_debt_simplification

    group, _users = group_with_expenses

    recalculate_group_ledger(str(group.id))
    run_debt_simplification(str(group.id))

    balances = django_cache.get(f"rachae:ledger:group:{group.id}:balances")
    suggestions = django_cache.get(f"rachae:ledger:group:{group.id}:simplified")

    total_positive = sum(max(Decimal(b), Decimal("0")) for b in balances.values())
    total_suggested = sum(Decimal(s["amount"]) for s in suggestions)

    assert abs(total_positive - total_suggested) <= Decimal("0.02")


@pytest.mark.django_db
def test_all_groups_fan_out_dispatches_per_group(multiple_groups):
    from tasks.ledger_tasks import run_debt_simplification_all_groups

    active_groups, deleted_group, disabled_group = multiple_groups

    with patch("tasks.ledger_tasks.run_debt_simplification") as mock_task:
        run_debt_simplification_all_groups()

    dispatched_ids = {call.args[0] for call in mock_task.delay.call_args_list}
    expected_active_ids = {str(group.id) for group in active_groups}

    assert dispatched_ids == expected_active_ids
    assert str(deleted_group.id) not in dispatched_ids
    assert str(disabled_group.id) not in dispatched_ids


@pytest.mark.django_db
def test_all_groups_fan_out_handles_zero_groups():
    from tasks.ledger_tasks import run_debt_simplification_all_groups

    with patch("tasks.ledger_tasks.run_debt_simplification") as mock_task:
        run_debt_simplification_all_groups()

    mock_task.delay.assert_not_called()
