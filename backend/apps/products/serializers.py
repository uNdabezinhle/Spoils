from rest_framework import serializers

from .models import Category, Product


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "slug", "description", "image_url")


class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source="category.name", read_only=True)
    category_slug = serializers.CharField(source="category.slug", read_only=True)

    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "slug",
            "base_price",
            "image_url",
            "category_name",
            "category_slug",
            "occasion",
            "is_featured",
            "is_popular",
            "ar_enabled",
        )


class ProductDetailSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)

    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "slug",
            "description",
            "base_price",
            "image_url",
            "delivery_info",
            "category",
            "occasion",
            "is_featured",
            "is_popular",
            "ar_enabled",
            "preview_mode",
            "model_3d_url",
            "preview_scale",
        )