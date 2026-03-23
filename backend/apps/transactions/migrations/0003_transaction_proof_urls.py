from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("transactions", "0002_alter_transaction_options_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="transaction",
            name="proof_urls",
            field=models.JSONField(blank=True, default=list),
        ),
    ]
