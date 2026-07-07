from django.conf import settings
from django.db import models


class LoyaltyAccount(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="loyalty_account")
    balance = models.PositiveIntegerField(default=0)
    lifetime_earned = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} — {self.balance} pts"


class PointsLedgerEntry(models.Model):
    ENTRY_TYPES = [
        ("earn", "Earned"),
        ("redeem", "Redeemed"),
        ("adjust", "Adjustment"),
    ]

    account = models.ForeignKey(LoyaltyAccount, on_delete=models.CASCADE, related_name="entries")
    entry_type = models.CharField(max_length=10, choices=ENTRY_TYPES)
    points = models.IntegerField()
    balance_after = models.PositiveIntegerField()
    description = models.CharField(max_length=255, blank=True)
    order = models.ForeignKey("orders.Order", on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.entry_type} {self.points} → {self.balance_after}"