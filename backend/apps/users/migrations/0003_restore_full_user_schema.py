from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0002_step2_user_sync_layer"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="phone",
            field=models.CharField(blank=True, max_length=20, null=True, unique=True),
        ),
        migrations.AddField(
            model_name="user",
            name="is_ad_free",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="user",
            name="stripe_customer_id",
            field=models.CharField(blank=True, max_length=50, null=True, unique=True),
        ),
        migrations.RenameField(
            model_name="user",
            old_name="locale",
            new_name="preferred_locale",
        ),
        migrations.RemoveField(
            model_name="user",
            name="is_active",
        ),
        migrations.AlterField(
            model_name="user",
            name="display_name",
            field=models.CharField(max_length=100),
        ),
        migrations.AlterField(
            model_name="user",
            name="avatar_url",
            field=models.TextField(blank=True, null=True),
        ),
    ]
