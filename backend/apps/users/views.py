from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import AddressSerializer, RegisterSerializer, UserSerializer


def _tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


@api_view(["POST"])
@permission_classes([AllowAny])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    return Response(
        {"user": UserSerializer(user).data, "tokens": _tokens_for_user(user)},
        status=status.HTTP_201_CREATED,
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def login(request):
    email = request.data.get("email", "").strip().lower()
    password = request.data.get("password", "")
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"detail": "Invalid credentials."}, status=status.HTTP_401_UNAUTHORIZED)
    if not user.check_password(password):
        return Response({"detail": "Invalid credentials."}, status=status.HTTP_401_UNAUTHORIZED)
    return Response({"user": UserSerializer(user).data, "tokens": _tokens_for_user(user)})


@api_view(["POST"])
@permission_classes([AllowAny])
def refresh_token(request):
    from rest_framework_simplejwt.serializers import TokenRefreshSerializer

    serializer = TokenRefreshSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    return Response(serializer.validated_data)


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def me(request):
    if request.method == "GET":
        return Response(UserSerializer(request.user).data)
    serializer = UserSerializer(request.user, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def address_list(request):
    if request.method == "GET":
        addresses = request.user.addresses.all()
        return Response(AddressSerializer(addresses, many=True).data)
    serializer = AddressSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save(user=request.user)
    return Response(serializer.data, status=status.HTTP_201_CREATED)