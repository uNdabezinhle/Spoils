import logging

from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def _get_firebase_app():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    if not settings.FIREBASE_CREDENTIALS_PATH:
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
        return _firebase_app
    except Exception:
        logger.exception("Could not initialize Firebase Admin SDK")
        return None


def send_fcm_to_tokens(
    *,
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    if not tokens:
        return 0
    payload = {str(k): str(v) for k, v in (data or {}).items()}
    if not _get_firebase_app():
        logger.info(
            "FCM stub — would push (%d device(s)): %s / %s data=%s",
            len(tokens),
            title,
            body,
            payload,
        )
        return 0
    try:
        from firebase_admin import messaging

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data=payload,
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        return response.success_count
    except Exception:
        logger.exception("FCM multicast failed")
        return 0