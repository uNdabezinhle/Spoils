from datetime import date, timedelta

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.content.models import FAQ, StaticPage
from apps.orders.models import Cart, CartItem
import hashlib
import hmac
import json

from django.test import override_settings

from apps.products.models import Category, Product
from apps.subscriptions.models import SubscriptionPlan

User = get_user_model()


class PublicApiSmokeTests(APITestCase):
    def setUp(self):
        FAQ.objects.create(question="Test?", answer="Yes.", sort_order=0, is_active=True)
        StaticPage.objects.create(
            page_type="privacy",
            title="Privacy",
            content="POPIA compliant.",
        )

    def test_health_check(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["app"], "Spoils")

    def test_catalog_home(self):
        response = self.client.get("/api/v1/products/home/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("categories", response.json())

    def test_product_filter_by_occasion(self):
        category = Category.objects.create(name="Flowers", slug="flowers")
        Product.objects.create(
            category=category,
            name="Birthday Roses",
            slug="birthday-roses",
            description="For birthdays.",
            base_price="399.00",
            occasion="birthday",
        )
        Product.objects.create(
            category=category,
            name="Anniversary Lilies",
            slug="anniversary-lilies",
            description="For anniversaries.",
            base_price="499.00",
            occasion="anniversary",
        )
        response = self.client.get("/api/v1/products/", {"occasion": "birthday"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        slugs = [p["slug"] for p in response.json()]
        self.assertEqual(slugs, ["birthday-roses"])

    def test_content_faq(self):
        response = self.client.get("/api/v1/content/faq/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)

    def test_content_static_page(self):
        response = self.client.get("/api/v1/content/pages/privacy/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["title"], "Privacy")


class AuthFlowSmokeTests(APITestCase):
    def test_register_login_and_profile(self):
        register = self.client.post(
            "/api/v1/auth/register/",
            {
                "email": "gift@example.com",
                "password": "securepass123",
                "password_confirm": "securepass123",
                "first_name": "Thabo",
                "last_name": "Mokoena",
            },
            format="json",
        )
        self.assertEqual(register.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", register.json()["tokens"])

        login = self.client.post(
            "/api/v1/auth/login/",
            {"email": "gift@example.com", "password": "securepass123"},
            format="json",
        )
        self.assertEqual(login.status_code, status.HTTP_200_OK)

        token = login.json()["tokens"]["access"]
        me = self.client.get("/api/v1/auth/me/", HTTP_AUTHORIZATION=f"Bearer {token}")
        self.assertEqual(me.status_code, status.HTTP_200_OK)
        self.assertEqual(me.json()["email"], "gift@example.com")


class CheckoutSmokeTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="buyer@example.com",
            email="buyer@example.com",
            password="securepass123",
        )
        category = Category.objects.create(name="Hampers", slug="hampers")
        self.product = Product.objects.create(
            category=category,
            name="Luxury Hamper",
            slug="luxury-hamper",
            description="A treat.",
            base_price="499.00",
        )
        cart, _ = Cart.objects.get_or_create(user=self.user)
        CartItem.objects.create(cart=cart, product=self.product, quantity=1)
        self.client.force_authenticate(user=self.user)

    def test_cart_detail(self):
        response = self.client.get("/api/v1/orders/cart/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["item_count"], 1)

    def test_checkout_preview(self):
        response = self.client.post(
            "/api/v1/orders/checkout/preview/",
            {"delivery_type": "standard"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertIn("total", data)
        self.assertIn("demo_mode", data)
        self.assertGreater(float(data["total"]), 0)

    def test_create_recipient(self):
        response = self.client.post(
            "/api/v1/reminders/recipients/",
            {
                "name": "Nomsa",
                "relationship": "Sister",
                "popia_consent": True,
                "occasions": [
                    {
                        "type": "birthday",
                        "date": (date.today() + timedelta(days=30)).isoformat(),
                        "reminder_days_before": 14,
                    }
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()["name"], "Nomsa")

    def test_popia_export(self):
        response = self.client.get("/api/v1/auth/me/export/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("profile", response.json())
        self.assertIn("orders", response.json())


class PostMvpSmokeTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="mvp@example.com",
            email="mvp@example.com",
            password="securepass123",
        )
        self.client.force_authenticate(user=self.user)
        category = Category.objects.create(name="Flowers", slug="flowers")
        Product.objects.create(
            category=category,
            name="Birthday Roses",
            slug="birthday-roses",
            description="For birthdays.",
            base_price="399.00",
            occasion="birthday",
            is_active=True,
        )
        self.plan = SubscriptionPlan.objects.create(
            name="Test Plan",
            slug="test-plan",
            model_type="gift_credit",
            description="Test subscription.",
            price_monthly="299.00",
            is_active=True,
        )
        recipient = self.client.post(
            "/api/v1/reminders/recipients/",
            {
                "name": "Zanele",
                "relationship": "Friend",
                "popia_consent": True,
                "occasions": [
                    {
                        "type": "birthday",
                        "date": (date.today() + timedelta(days=12)).isoformat(),
                        "reminder_days_before": 14,
                    }
                ],
            },
            format="json",
        )
        self.occasion_id = recipient.json()["occasions"][0]["id"]

    def test_occasion_detail_and_suggestions(self):
        detail = self.client.get(f"/api/v1/reminders/occasions/{self.occasion_id}/")
        self.assertEqual(detail.status_code, status.HTTP_200_OK)
        self.assertEqual(detail.json()["recipient_name"], "Zanele")

        suggestions = self.client.get(f"/api/v1/reminders/occasions/{self.occasion_id}/suggestions/")
        self.assertEqual(suggestions.status_code, status.HTTP_200_OK)
        self.assertIn("products", suggestions.json())

    def test_occasion_snooze_and_skip(self):
        snooze = self.client.post(f"/api/v1/reminders/occasions/{self.occasion_id}/snooze/", {"days": 3}, format="json")
        self.assertEqual(snooze.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(snooze.json().get("snoozed_until"))

        skip = self.client.post(f"/api/v1/reminders/occasions/{self.occasion_id}/skip/")
        self.assertEqual(skip.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(skip.json().get("skip_year"))

    def test_occasion_calendar(self):
        today = date.today()
        response = self.client.get(
            "/api/v1/reminders/calendar/",
            {"year": today.year, "month": today.month},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("events", response.json())

    def test_subscriptions_flow(self):
        plans = self.client.get("/api/v1/subscriptions/plans/")
        self.assertEqual(plans.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(plans.json()), 1)

        subscribe = self.client.post(
            "/api/v1/subscriptions/subscribe/",
            {"plan_id": self.plan.id},
            format="json",
        )
        self.assertEqual(subscribe.status_code, status.HTTP_201_CREATED)

        sub_id = subscribe.json()["id"]
        cancel = self.client.post(f"/api/v1/subscriptions/{sub_id}/cancel/")
        self.assertEqual(cancel.status_code, status.HTTP_200_OK)
        self.assertEqual(cancel.json()["status"], "cancelled")


class AnalyticsSmokeTests(APITestCase):
    def setUp(self):
        self.staff = User.objects.create_user(
            username="admin@example.com",
            email="admin@example.com",
            password="securepass123",
            is_staff=True,
        )
        self.user = User.objects.create_user(
            username="user@example.com",
            email="user@example.com",
            password="securepass123",
        )

    def test_analytics_requires_staff(self):
        self.client.force_authenticate(user=self.user)
        denied = self.client.get("/api/v1/analytics/overview/")
        self.assertEqual(denied.status_code, status.HTTP_403_FORBIDDEN)

        self.client.force_authenticate(user=self.staff)
        allowed = self.client.get("/api/v1/analytics/overview/")
        self.assertEqual(allowed.status_code, status.HTTP_200_OK)
        self.assertIn("users_total", allowed.json())
        self.assertIn("top_products", allowed.json())

    def test_admin_analytics_dashboard_page(self):
        self.client.force_login(self.staff)
        page = self.client.get("/admin/analytics/")
        self.assertEqual(page.status_code, status.HTTP_200_OK)
        self.assertContains(page, "Analytics overview")
        self.assertContains(page, "Revenue")


class PaystackWebhookSmokeTests(APITestCase):
    @override_settings(PAYSTACK_SECRET_KEY="sk_test_secret")
    def test_webhook_rejects_invalid_signature(self):
        payload = json.dumps({"event": "charge.success", "data": {"reference": "spoil_1_abc"}}).encode()
        response = self.client.post(
            "/api/v1/orders/paystack/webhook/",
            data=payload,
            content_type="application/json",
            HTTP_X_PAYSTACK_SIGNATURE="invalid",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    @override_settings(PAYSTACK_SECRET_KEY="sk_test_secret")
    def test_webhook_accepts_valid_signature(self):
        payload = json.dumps({"event": "ping", "data": {}}).encode()
        signature = hmac.new(b"sk_test_secret", payload, hashlib.sha512).hexdigest()
        response = self.client.post(
            "/api/v1/orders/paystack/webhook/",
            data=payload,
            content_type="application/json",
            HTTP_X_PAYSTACK_SIGNATURE=signature,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)