from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from django.conf import settings

from .models import Address, User
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


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout(request):
    refresh = request.data.get("refresh")
    if refresh:
        try:
            token = RefreshToken(refresh)
            token.blacklist()
        except Exception:
            pass
    return Response({"detail": "Logged out successfully."})


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def me(request):
    if request.method == "GET":
        return Response(UserSerializer(request.user).data)
    serializer = UserSerializer(request.user, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([AllowAny])
def password_reset_request(request):
    email = request.data.get("email", "").strip().lower()
    message = "If that email is registered, we've sent password reset instructions."

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"detail": message})

    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    reset_path = f"/auth/reset-password?uid={uid}&token={token}"

    send_mail(
        subject="Reset your Spoil password",
        message=(
            f"Hi {user.first_name or 'there'},\n\n"
            f"We received a request to reset your Spoil password.\n\n"
            f"Use this link in the app: {reset_path}\n\n"
            f"Or use uid={uid} and token={token} in the reset form.\n\n"
            f"If you didn't request this, you can safely ignore this email.\n\n"
            f"Spoil them properly."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )

    payload = {"detail": message}
    if settings.DEBUG:
        payload["debug"] = {"uid": uid, "token": token}

    return Response(payload)


@api_view(["POST"])
@permission_classes([AllowAny])
def password_reset_confirm(request):
    uid = request.data.get("uid", "")
    token = request.data.get("token", "")
    password = request.data.get("password", "")

    if len(password) < 8:
        return Response({"password": ["Password must be at least 8 characters."]}, status=400)

    try:
        user_id = force_str(urlsafe_base64_decode(uid))
        user = User.objects.get(pk=user_id)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        return Response({"detail": "Invalid reset link."}, status=400)

    if not default_token_generator.check_token(user, token):
        return Response({"detail": "Invalid or expired reset link."}, status=400)

    user.set_password(password)
    user.save()
    return Response({"detail": "Password updated. You can sign in now."})


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def address_list(request):
    if request.method == "GET":
        addresses = request.user.addresses.all()
        return Response(AddressSerializer(addresses, many=True).data)
    serializer = AddressSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    address = serializer.save(user=request.user)
    if address.is_default:
        Address.objects.filter(user=request.user).exclude(pk=address.pk).update(is_default=False)
    return Response(AddressSerializer(address).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def address_detail(request, pk):
    try:
        address = request.user.addresses.get(pk=pk)
    except Address.DoesNotExist:
        return Response({"detail": "Address not found."}, status=404)

    if request.method == "GET":
        return Response(AddressSerializer(address).data)

    if request.method == "DELETE":
        address.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = AddressSerializer(address, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    address = serializer.save()
    if address.is_default:
        Address.objects.filter(user=request.user).exclude(pk=address.pk).update(is_default=False)
    return Response(AddressSerializer(address).data)