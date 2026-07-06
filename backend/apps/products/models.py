from django.db import models


class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    image_url = models.URLField(blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name


class Product(models.Model):
    OCCASION_CHOICES = [
        ("birthday", "Birthday"),
        ("anniversary", "Anniversary"),
        ("thank_you", "Thank You"),
        ("just_because", "Just Because"),
        ("other", "Other"),
    ]

    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="products")
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField()
    base_price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(blank=True)
    delivery_info = models.CharField(max_length=255, blank=True)
    is_featured = models.BooleanField(default=False)
    is_popular = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    occasion = models.CharField(max_length=30, choices=OCCASION_CHOICES, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_featured", "name"]

    def __str__(self):
        return self.name


class WrappingOption(models.Model):
    name = models.CharField(max_length=100)
    ribbon_color = models.CharField(max_length=50)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    image_url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class MessageTemplate(models.Model):
    OCCASION_CHOICES = [
        ("birthday", "Birthday"),
        ("anniversary", "Anniversary"),
        ("thank_you", "Thank You"),
        ("just_because", "Just Because"),
        ("other", "Other"),
    ]
    occasion = models.CharField(max_length=30, choices=OCCASION_CHOICES)
    title = models.CharField(max_length=100)
    message = models.TextField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.title