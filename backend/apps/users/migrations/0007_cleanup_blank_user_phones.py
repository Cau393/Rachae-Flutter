from django.db import migrations


def cleanup_blank_user_phones(apps, schema_editor):
    User = apps.get_model("users", "User")
    for user in User._base_manager.exclude(phone__isnull=True):
        if str(user.phone).strip() == "":
            user.phone = None
            user.save(update_fields=["phone"])


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0006_friendinvite_phone_nullable"),
    ]

    operations = [
        migrations.RunPython(
            cleanup_blank_user_phones,
            migrations.RunPython.noop,
        ),
    ]
