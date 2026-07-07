from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("reminders", "0005_engagement_features"),
    ]

    operations = [
        migrations.AddField(
            model_name="occasion",
            name="auto_send_enabled",
            field=models.BooleanField(default=False),
        ),
    ]