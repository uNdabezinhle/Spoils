from django.db.models import Q
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import Product
from .serializers import CategorySerializer, ProductDetailSerializer, ProductListSerializer


@api_view(["GET"])
@permission_classes([AllowAny])
def catalog_home(request):
    from .models import Category

    categories = Category.objects.filter(is_active=True)
    featured = Product.objects.filter(is_active=True, is_featured=True).select_related("category")[:8]
    popular = Product.objects.filter(is_active=True, is_popular=True).select_related("category")[:8]
    return Response({
        "categories": CategorySerializer(categories, many=True).data,
        "featured": ProductListSerializer(featured, many=True).data,
        "popular": ProductListSerializer(popular, many=True).data,
    })


@api_view(["GET"])
@permission_classes([AllowAny])
def category_list(request):
    from .models import Category

    categories = Category.objects.filter(is_active=True)
    return Response(CategorySerializer(categories, many=True).data)


@api_view(["GET"])
@permission_classes([AllowAny])
def product_list(request):
    qs = Product.objects.filter(is_active=True).select_related("category")
    category = request.query_params.get("category")
    search = request.query_params.get("search")
    featured = request.query_params.get("featured")
    popular = request.query_params.get("popular")
    min_price = request.query_params.get("min_price")
    max_price = request.query_params.get("max_price")
    occasion = request.query_params.get("occasion")

    if category:
        qs = qs.filter(category__slug=category)
    if search:
        qs = qs.filter(Q(name__icontains=search) | Q(description__icontains=search))
    if featured == "true":
        qs = qs.filter(is_featured=True)
    if popular == "true":
        qs = qs.filter(is_popular=True)
    if min_price:
        qs = qs.filter(base_price__gte=min_price)
    if max_price:
        qs = qs.filter(base_price__lte=max_price)
    if occasion:
        qs = qs.filter(occasion=occasion)

    return Response(ProductListSerializer(qs, many=True).data)


@api_view(["GET"])
@permission_classes([AllowAny])
def product_detail(request, slug):
    try:
        product = Product.objects.select_related("category").get(slug=slug, is_active=True)
    except Product.DoesNotExist:
        return Response({"detail": "Product not found."}, status=404)
    return Response(ProductDetailSerializer(product).data)