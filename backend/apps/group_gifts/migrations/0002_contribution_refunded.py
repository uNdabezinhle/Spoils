from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("group_gifts", "0001_growth_features"),
    ]

    operations = [
        migrations.AlterField(
            model_name="groupgiftcontribution",
            name="status",
            field=models.CharField(
                choices=[
                    ("pending", "Pending"),
                    ("paid", "Paid"),
                    ("failed", "Failed"),
                    ("refunded", "Refunded"),
                ],
                default="pending",
                max_length=20,
            ),
        ),
    ]