import secrets

from django.conf import settings
from django.db import models


def generate_share_token() -> str:
    return secrets.token_urlsafe(12)


class GroupGift(models.Model):
    STATUS_CHOICES = [
        ("open", "Open"),
        ("funded", "Funded"),
        ("ordered", "Ordered"),
        ("cancelled", "Cancelled"),
    ]

    organizer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="group_gifts")
    share_token = models.CharField(max_length=32, unique=True, default=generate_share_token)
    title = models.CharField(max_length=200)
    recipient_name = models.CharField(max_length=150, blank=True)
    message = models.TextField(blank=True)
    target_amount = models.DecimalField(max_digits=10, decimal_places=2)
    amount_collected = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="open")
    cart_snapshot = models.JSONField(default=list)
    delivery_address = models.JSONField(default=dict, blank=True)
    delivery_date = models.DateField(null=True, blank=True)
    delivery_type = models.CharField(max_length=20, default="standard")
    order = models.ForeignKey("orders.Order", on_delete=models.SET_NULL, null=True, blank=True, related_name="group_gifts")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.status})"

    @property
    def progress_percent(self) -> int:
        if self.target_amount <= 0:
            return 0
        return min(100, int((self.amount_collected / self.target_amount) * 100))


class GroupGiftContribution(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("paid", "Paid"),
        ("failed", "Failed"),
        ("refunded", "Refunded"),
    ]

    group_gift = models.ForeignKey(GroupGift, on_delete=models.CASCADE, related_name="contributions")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    contributor_name = models.CharField(max_length=150)
    contributor_email = models.EmailField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    paystack_reference = models.CharField(max_length=100, blank=True)
    message = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.contributor_name} — R{self.amount}"