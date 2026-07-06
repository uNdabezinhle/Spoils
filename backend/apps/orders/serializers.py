from decimal import Decimal

from rest_framework import serializers

from apps.products.models import Product, WrappingOption

from .models import CartItem


class CustomisationSerializer(serializers.Serializer):
    message = serializers.CharField(required=False, allow_blank=True, max_length=1000)
    photo_url = serializers.URLField(required=False, allow_blank=True)
    wrapping_option_id = serializers.IntegerField(required=False, allow_null=True)
    wrapping_name = serializers.CharField(required=False, allow_blank=True)
    ribbon_color = serializers.CharField(required=False, allow_blank=True)
    wrapping_price = serializers.DecimalField(required=False, max_digits=8, decimal_places=2)


class AddToCartSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, default=1)
    customisation = CustomisationSerializer(required=False)

    def validate_product_id(self, value):
        if not Product.objects.filter(pk=value, is_active=True).exists():
            raise serializers.ValidationError("Product not found.")
        return value

    def validate(self, attrs):
        customisation = attrs.get("customisation") or {}
        wrapping_id = customisation.get("wrapping_option_id")
        if wrapping_id:
            try:
                wrap = WrappingOption.objects.get(pk=wrapping_id, is_active=True)
            except WrappingOption.DoesNotExist:
                raise serializers.ValidationError({"customisation": "Invalid wrapping option."})
            customisation["wrapping_name"] = wrap.name
            customisation["ribbon_color"] = wrap.ribbon_color
            customisation["wrapping_price"] = str(wrap.price)
            attrs["customisation"] = customisation
        return attrs


class UpdateCartItemSerializer(serializers.Serializer):
    quantity = serializers.IntegerField(min_value=1, required=False)
    customisation = CustomisationSerializer(required=False)


def line_unit_total(product: Product, customisation: dict) -> Decimal:
    wrapping = Decimal(customisation.get("wrapping_price", "0") or "0")
    return product.base_price + wrapping


def serialize_cart_item(item: CartItem) -> dict:
    product = item.product
    customisation = item.customisation_details or {}
    unit_total = line_unit_total(product, customisation)
    return {
        "id": item.id,
        "product_id": product.id,
        "product_slug": product.slug,
        "product_name": product.name,
        "product_image_url": product.image_url,
        "quantity": item.quantity,
        "unit_price": str(product.base_price),
        "line_unit_total": str(unit_total),
        "line_total": str(unit_total * item.quantity),
        "customisation_details": customisation,
    }


def serialize_cart(cart) -> dict:
    items = [serialize_cart_item(i) for i in cart.items.select_related("product").all()]
    subtotal = sum(Decimal(i["line_total"]) for i in items)
    return {
        "id": cart.id,
        "items": items,
        "item_count": sum(i.quantity for i in cart.items.all()),
        "subtotal": str(subtotal),
    }