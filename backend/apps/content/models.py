from django.db import models


class StaticPage(models.Model):
    PAGE_TYPES = [
        ("about", "About Spoil"),
        ("terms", "Terms of Service"),
        ("privacy", "Privacy Policy"),
        ("how_it_works", "How It Works"),
    ]
    page_type = models.CharField(max_length=30, choices=PAGE_TYPES, unique=True)
    title = models.CharField(max_length=200)
    content = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class FAQ(models.Model):
    question = models.CharField(max_length=300)
    answer = models.TextField()
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order"]
        verbose_name = "FAQ"

    def __str__(self):
        return self.question