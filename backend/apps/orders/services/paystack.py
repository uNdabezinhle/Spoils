import hashlib
import hmac
import uuid

import requests
from django.conf import settings


class PaystackError(Exception):
    pass


def generate_reference(order_id: int) -> str:
    return f"spoil_{order_id}_{uuid.uuid4().hex[:12]}"


def generate_subscription_reference(subscription_id: int) -> str:
    return f"sub_{subscription_id}_{uuid.uuid4().hex[:12]}"


def is_demo_mode() -> bool:
    return not settings.PAYSTACK_SECRET_KEY


def initialize_transaction(*, email: str, amount_cents: int, reference: str, metadata: dict | None = None) -> dict:
    if is_demo_mode():
        return {
            "demo_mode": True,
            "reference": reference,
            "authorization_url": None,
            "access_code": None,
        }

    response = requests.post(
        "https://api.paystack.co/transaction/initialize",
        headers={"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"},
        json={
            "email": email,
            "amount": amount_cents,
            "currency": "ZAR",
            "reference": reference,
            "metadata": metadata or {},
        },
        timeout=30,
    )
    body = response.json()
    if not response.ok or not body.get("status"):
        raise PaystackError(body.get("message", "Could not initialize payment."))

    data = body["data"]
    return {
        "demo_mode": False,
        "reference": data["reference"],
        "authorization_url": data["authorization_url"],
        "access_code": data.get("access_code"),
    }


def verify_transaction(reference: str) -> dict:
    if is_demo_mode():
        return {
            "status": "success",
            "reference": reference,
            "demo_mode": True,
            "authorization_code": f"demo_auth_{reference[:24]}",
        }

    response = requests.get(
        f"https://api.paystack.co/transaction/verify/{reference}",
        headers={"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"},
        timeout=30,
    )
    body = response.json()
    if not response.ok or not body.get("status"):
        raise PaystackError(body.get("message", "Could not verify payment."))

    data = body["data"]
    authorization = data.get("authorization") or {}
    return {
        "status": data["status"],
        "reference": data["reference"],
        "amount": data["amount"],
        "demo_mode": False,
        "authorization_code": authorization.get("authorization_code", ""),
    }


def charge_authorization(
    *,
    email: str,
    amount_cents: int,
    authorization_code: str,
    reference: str,
    metadata: dict | None = None,
) -> dict:
    if is_demo_mode():
        return {
            "status": "success",
            "reference": reference,
            "demo_mode": True,
            "authorization_code": authorization_code,
        }

    response = requests.post(
        "https://api.paystack.co/transaction/charge_authorization",
        headers={"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"},
        json={
            "email": email,
            "amount": amount_cents,
            "authorization_code": authorization_code,
            "reference": reference,
            "currency": "ZAR",
            "metadata": metadata or {},
        },
        timeout=30,
    )
    body = response.json()
    if not response.ok or not body.get("status"):
        raise PaystackError(body.get("message", "Could not charge authorization."))

    data = body["data"]
    authorization = data.get("authorization") or {}
    return {
        "status": data["status"],
        "reference": data["reference"],
        "demo_mode": False,
        "authorization_code": authorization.get("authorization_code", authorization_code),
    }


def refund_transaction(*, reference: str, amount_cents: int | None = None) -> dict:
    if is_demo_mode():
        return {"status": "success", "reference": reference, "demo_mode": True}

    payload: dict = {"transaction": reference}
    if amount_cents is not None:
        payload["amount"] = amount_cents

    response = requests.post(
        "https://api.paystack.co/refund",
        headers={"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"},
        json=payload,
        timeout=30,
    )
    body = response.json()
    if not response.ok or not body.get("status"):
        raise PaystackError(body.get("message", "Could not process refund."))
    return {"status": "success", "reference": reference, "demo_mode": False}


def verify_webhook_signature(*, payload: bytes, signature: str) -> bool:
    """Validate Paystack x-paystack-signature (HMAC SHA512 of raw body)."""
    if is_demo_mode():
        return True
    if not signature:
        return False
    digest = hmac.new(
        settings.PAYSTACK_SECRET_KEY.encode("utf-8"),
        payload,
        hashlib.sha512,
    ).hexdigest()
    return hmac.compare_digest(digest, signature)