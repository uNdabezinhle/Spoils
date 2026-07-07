from decimal import Decimal

from django.conf import settings
from django.db import models


class SubscriptionPlan(models.Model):
    MODEL_CHOICES = [
        ("spoil_box", "Monthly Spoil Box"),
        ("someone_to_spoil", "Someone to Spoil"),
        ("gift_credit", "Gift Credit"),
        ("occasion_auto", "Occasion Auto-Gift"),
    ]

    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    model_type = models.CharField(max_length=30, choices=MODEL_CHOICES)
    tagline = models.CharField(max_length=200, blank=True)
    description = models.TextField()
    price_monthly = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0.00"))
    image_url = models.URLField(blank=True)
    features = models.JSONField(default=list, blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sort_order", "name"]

    def __str__(self):
        return self.name


class UserSubscription(models.Model):
    STATUS_CHOICES = [
        ("pending_payment", "Pending Payment"),
        ("active", "Active"),
        ("paused", "Paused"),
        ("cancelled", "Cancelled"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions")
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.PROTECT, related_name="subscribers")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending_payment")
    recipient_name = models.CharField(max_length=150, blank=True)
    occasion = models.ForeignKey(
        "reminders.Occasion",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="auto_gift_subscriptions",
    )
    started_at = models.DateTimeField(auto_now_add=True)
    next_billing_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    paystack_reference = models.CharField(max_length=100, blank=True)
    paystack_authorization_code = models.CharField(max_length=100, blank=True)
    last_payment_reference = models.CharField(max_length=100, blank=True)
    last_payment_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-started_at"]

    def __str__(self):
        return f"{self.user.email} — {self.plan.name} ({self.status})"