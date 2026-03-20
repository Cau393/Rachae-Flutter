from django.db import migrations


class Migration(migrations.Migration):
    # Columns are added by users.0005_user_plan_expires_at_user_plan_type_and_more.
    # This migration previously duplicated them via RunSQL and caused duplicate
    # column errors when users.0005 ran after ads.0001 (both depended only on
    # users.0004). Keep a no-op migration so django_migrations history stays valid.
    dependencies = [
        ("users", "0005_user_plan_expires_at_user_plan_type_and_more"),
    ]

    operations = []
