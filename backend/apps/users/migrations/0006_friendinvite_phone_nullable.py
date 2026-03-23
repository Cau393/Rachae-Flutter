from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0005_user_plan_expires_at_user_plan_type_and_more"),
    ]

    operations = [
        migrations.AlterField(
            model_name="friendinvite",
            name="phone",
            field=models.CharField(blank=True, db_index=True, max_length=20, null=True),
        ),
    ]
