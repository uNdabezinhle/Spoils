import os
import uuid

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

from .models import Address, DeviceToken, User
from .serializers import AddressSerializer, RegisterSerializer, UserSerializer
from .services.popia import delete_user_account, export_user_data
from .services.social_auth import (
    SocialAuthError,
    authenticate_social_user,
    verify_apple_identity_token,
    verify_google_id_token,
)


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
def google_login(request):
    id_token = request.data.get("id_token", "").strip()
    if not id_token:
        return Response({"detail": "id_token is required."}, status=400)
    try:
        profile = verify_google_id_token(id_token)
        user = authenticate_social_user(profile=profile)
    except SocialAuthError as exc:
        return Response({"detail": str(exc)}, status=400)
    return Response({"user": UserSerializer(user).data, "tokens": _tokens_for_user(user)})


@api_view(["POST"])
@permission_classes([AllowAny])
def apple_login(request):
    id_token = request.data.get("id_token", "").strip()
    if not id_token:
        return Response({"detail": "id_token is required."}, status=400)
    try:
        profile = verify_apple_identity_token(id_token)
        user = authenticate_social_user(
            profile=profile,
            fallback_first_name=request.data.get("first_name", ""),
            fallback_last_name=request.data.get("last_name", ""),
        )
    except SocialAuthError as exc:
        return Response({"detail": str(exc)}, status=400)
    return Response({"user": UserSerializer(user).data, "tokens": _tokens_for_user(user)})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def upload_avatar(request):
    photo = request.FILES.get("photo")
    if not photo:
        return Response({"detail": "No photo uploaded."}, status=400)
    if photo.size > 5 * 1024 * 1024:
        return Response({"detail": "Photo must be under 5MB."}, status=400)

    allowed = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
    if photo.content_type not in allowed:
        return Response({"detail": "Only JPEG, PNG, and WebP images are allowed."}, status=400)

    if settings.CLOUDINARY_CLOUD_NAME:
        import cloudinary.uploader

        result = cloudinary.uploader.upload(
            photo,
            folder="spoil/avatars",
            transformation={"width": 400, "height": 400, "crop": "fill", "gravity": "face"},
        )
        photo_url = result["secure_url"]
    else:
        ext = os.path.splitext(photo.name)[1] or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        upload_dir = os.path.join(str(settings.MEDIA_ROOT), "avatars")
        os.makedirs(upload_dir, exist_ok=True)
        filepath = os.path.join(upload_dir, filename)
        with open(filepath, "wb+") as dest:
            for chunk in photo.chunks():
                dest.write(chunk)
        photo_url = request.build_absolute_uri(settings.MEDIA_URL + f"avatars/{filename}")

    request.user.avatar_url = photo_url
    request.user.save(update_fields=["avatar_url"])
    return Response({"avatar_url": photo_url, "user": UserSerializer(request.user).data})


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


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def me_export(request):
    return Response(export_user_data(request.user))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def me_delete(request):
    password = request.data.get("password", "")
    if not password:
        return Response({"detail": "password is required to delete your account."}, status=400)
    try:
        delete_user_account(request.user, password=password)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    return Response({"detail": "Your account and personal data have been permanently deleted."})


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


@api_view(["POST", "DELETE"])
@permission_classes([IsAuthenticated])
def device_token(request):
    token = request.data.get("token", "").strip()
    if not token:
        return Response({"detail": "token is required."}, status=400)

    if request.method == "DELETE":
        DeviceToken.objects.filter(user=request.user, token=token).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    platform = request.data.get("platform", "android")
    DeviceToken.objects.update_or_create(
        token=token,
        defaults={"user": request.user, "platform": platform},
    )
    return Response({"detail": "Device registered for notifications."}, status=status.HTTP_201_CREATED)