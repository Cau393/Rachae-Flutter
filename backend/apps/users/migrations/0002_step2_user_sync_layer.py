from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0001_initial"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="user",
            name="phone",
        ),
        migrations.RemoveField(
            model_name="user",
            name="is_ad_free",
        ),
        migrations.RemoveField(
            model_name="user",
            name="stripe_customer_id",
        ),
        migrations.RenameField(
            model_name="user",
            old_name="preferred_locale",
            new_name="locale",
        ),
        migrations.AlterField(
            model_name="user",
            name="supabase_uid",
            field=models.UUIDField(db_index=True, unique=True),
        ),
        migrations.AlterField(
            model_name="user",
            name="display_name",
            field=models.CharField(blank=True, default="", max_length=100),
        ),
        migrations.AlterField(
            model_name="user",
            name="avatar_url",
            field=models.TextField(blank=True, default=""),
        ),
        migrations.AddField(
            model_name="user",
            name="is_active",
            field=models.BooleanField(default=True),
        ),
    ]
