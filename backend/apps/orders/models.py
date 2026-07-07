from django.conf import settings
from django.db import models


class PromoCode(models.Model):
    code = models.CharField(max_length=50, unique=True)
    discount_percent = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.code


class Cart(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="cart")
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Cart for {self.user}"


class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey("products.Product", on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    customisation_details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("cart", "product")


class Order(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending Payment"),
        ("paid", "Paid"),
        ("processing", "Processing"),
        ("shipped", "Shipped"),
        ("delivered", "Delivered"),
        ("cancelled", "Cancelled"),
    ]
    DELIVERY_CHOICES = [
        ("standard", "Standard"),
        ("express", "Express"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_address = models.JSONField()
    delivery_date = models.DateField()
    delivery_type = models.CharField(max_length=20, choices=DELIVERY_CHOICES, default="standard")
    paystack_reference = models.CharField(max_length=100, blank=True)
    points_redeemed = models.PositiveIntegerField(default=0)
    points_discount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    promo_code = models.ForeignKey(PromoCode, null=True, blank=True, on_delete=models.SET_NULL)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order #{self.pk} — {self.user}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey("products.Product", on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    customisation_details = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f"{self.product.name} x{self.quantity}"