from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("orders", "0004_engagement_features"),
    ]

    operations = [
        migrations.AddField(
            model_name="order",
            name="subscription_id",
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
    ]