import json
import logging
from urllib.request import urlopen

import jwt
import requests
from django.conf import settings
from django.contrib.auth import get_user_model

from ..models import SocialAccount

logger = logging.getLogger(__name__)
User = get_user_model()


class SocialAuthError(Exception):
    pass


def verify_google_id_token(id_token: str) -> dict:
    client_id = settings.GOOGLE_OAUTH_CLIENT_ID
    if not client_id:
        raise SocialAuthError("Google sign-in is not configured.")

    response = requests.get(
        "https://oauth2.googleapis.com/tokeninfo",
        params={"id_token": id_token},
        timeout=15,
    )
    if not response.ok:
        raise SocialAuthError("Invalid Google token.")

    data = response.json()
    if data.get("aud") != client_id:
        raise SocialAuthError("Google token audience mismatch.")
    if data.get("email_verified") not in ("true", True):
        raise SocialAuthError("Google email is not verified.")

    return {
        "provider": "google",
        "uid": data["sub"],
        "email": data.get("email", "").lower(),
        "first_name": data.get("given_name", ""),
        "last_name": data.get("family_name", ""),
    }


def verify_apple_identity_token(id_token: str) -> dict:
    client_id = settings.APPLE_CLIENT_ID
    if not client_id:
        raise SocialAuthError("Apple sign-in is not configured.")

    try:
        header = jwt.get_unverified_header(id_token)
        kid = header["kid"]
        with urlopen("https://appleid.apple.com/auth/keys") as response:
            keys = json.load(response)
        public_key = None
        for key in keys["keys"]:
            if key["kid"] == kid:
                public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
                break
        if public_key is None:
            raise SocialAuthError("Apple public key not found.")

        payload = jwt.decode(
            id_token,
            public_key,
            algorithms=["RS256"],
            audience=client_id,
            issuer="https://appleid.apple.com",
        )
    except SocialAuthError:
        raise
    except Exception as exc:
        logger.exception("Apple token verification failed")
        raise SocialAuthError("Invalid Apple token.") from exc

    email = (payload.get("email") or "").lower()
    return {
        "provider": "apple",
        "uid": payload["sub"],
        "email": email,
        "first_name": "",
        "last_name": "",
    }


def authenticate_social_user(*, profile: dict, fallback_first_name: str = "", fallback_last_name: str = "") -> User:
    provider = profile["provider"]
    uid = profile["uid"]
    email = profile.get("email", "")
    first_name = profile.get("first_name") or fallback_first_name
    last_name = profile.get("last_name") or fallback_last_name

    social = SocialAccount.objects.filter(provider=provider, uid=uid).select_related("user").first()
    if social:
        return social.user

    user = None
    if email:
        user = User.objects.filter(email=email).first()

    if user is None:
        if not email:
            email = f"{provider}_{uid[:24]}@spoils.social"
        user = User.objects.create_user(
            username=email,
            email=email,
            first_name=first_name,
            last_name=last_name,
        )
        user.set_unusable_password()
        user.save()
    elif first_name and not user.first_name:
        user.first_name = first_name
        user.last_name = last_name
        user.save(update_fields=["first_name", "last_name"])

    SocialAccount.objects.get_or_create(
        provider=provider,
        uid=uid,
        defaults={"user": user},
    )
    return user