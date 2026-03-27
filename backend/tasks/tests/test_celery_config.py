from celery import current_app


def test_celery_app_name():
    from config.celery import app

    assert app.main == "rachae"


def test_task_acks_late_enabled():
    assert current_app.conf.task_acks_late is True


def test_task_reject_on_worker_lost_enabled():
    assert current_app.conf.task_reject_on_worker_lost is True


def test_json_serializers_enabled():
    assert current_app.conf.task_serializer == "json"
    assert current_app.conf.result_serializer == "json"


def test_beat_schedule_contains_required_tasks():
    schedule = current_app.conf.beat_schedule
    task_names = {entry["task"] for entry in schedule.values()}
    assert "tasks.currency_tasks.refresh_exchange_rates" in task_names
    assert "tasks.s3_tasks.cleanup_orphan_s3_files" in task_names
    assert "tasks.ledger_tasks.run_debt_simplification_all_groups" in task_names


def test_all_task_files_importable():
    import tasks.currency_tasks  # noqa: F401
    import tasks.email_tasks  # noqa: F401
    import tasks.ledger_tasks  # noqa: F401
    import tasks.notification_tasks  # noqa: F401
    import tasks.s3_tasks  # noqa: F401
    import tasks.stripe_tasks  # noqa: F401
