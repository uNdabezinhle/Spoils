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
from apps.reminders.models import Occasion
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

    @override_settings(PAYSTACK_SECRET_KEY="", PAYSTACK_PUBLIC_KEY="")
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
        self.assertTrue(subscribe.json().get("demo_mode"))
        sub_id = subscribe.json()["subscription"]["id"]
        reference = subscribe.json()["reference"]

        verify = self.client.post(
            "/api/v1/subscriptions/subscribe/verify/",
            {"subscription_id": sub_id, "reference": reference},
            format="json",
        )
        self.assertEqual(verify.status_code, status.HTTP_200_OK)
        self.assertEqual(verify.json()["subscription"]["status"], "active")

        cancel = self.client.post(f"/api/v1/subscriptions/{sub_id}/cancel/")
        self.assertEqual(cancel.status_code, status.HTTP_200_OK)
        self.assertEqual(cancel.json()["status"], "cancelled")

    @override_settings(PAYSTACK_SECRET_KEY="", PAYSTACK_PUBLIC_KEY="")
    def test_auto_gift_approval_flow(self):
        from apps.reminders.models import Recipient
        from apps.reminders.services.auto_gift import create_proposal_for_occasion
        from apps.subscriptions.models import UserSubscription

        recipient = Recipient.objects.get(pk=Occasion.objects.get(pk=self.occasion_id).recipient_id)
        soon_occasion = Occasion.objects.create(
            recipient=recipient,
            type="birthday",
            date=date.today() + timedelta(days=5),
            reminder_days_before=14,
        )

        auto_plan = SubscriptionPlan.objects.create(
            name="Auto Gift",
            slug="auto-gift",
            model_type="occasion_auto",
            description="Auto gifting.",
            price_monthly="199.00",
            is_active=True,
        )
        sub = UserSubscription.objects.create(
            user=self.user,
            plan=auto_plan,
            status="active",
            recipient_name="Zanele",
            occasion=soon_occasion,
            paystack_authorization_code="demo_auth_test",
        )
        proposal = create_proposal_for_occasion(occasion=soon_occasion, subscription=sub)
        self.assertIsNotNone(proposal)

        detail = self.client.get(f"/api/v1/reminders/occasions/{soon_occasion.id}/")
        self.assertIsNotNone(detail.json().get("pending_auto_gift"))

        address = self.client.post(
            "/api/v1/auth/addresses/",
            {
                "label": "Home",
                "recipient_name": "Zanele",
                "phone": "0821234567",
                "street_address": "1 Main Rd",
                "suburb": "Sandton",
                "city": "Johannesburg",
                "province": "Gauteng",
                "postal_code": "2196",
            },
            format="json",
        )
        self.assertEqual(address.status_code, status.HTTP_201_CREATED)

        approve = self.client.post(
            f"/api/v1/reminders/occasions/{soon_occasion.id}/approve-gift/",
            {"address_id": address.json()["id"]},
            format="json",
        )
        self.assertEqual(approve.status_code, status.HTTP_200_OK)
        self.assertIn("order_id", approve.json())

        proposal.refresh_from_db()
        self.assertEqual(proposal.status, "ordered")


class GrowthFeaturesSmokeTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="growth@example.com",
            email="growth@example.com",
            password="securepass123",
        )
        self.client.force_authenticate(user=self.user)

    def test_loyalty_and_support(self):
        loyalty = self.client.get("/api/v1/loyalty/me/")
        self.assertEqual(loyalty.status_code, status.HTTP_200_OK)
        self.assertEqual(loyalty.json()["balance"], 0)

        convo = self.client.get("/api/v1/support/conversation/")
        self.assertEqual(convo.status_code, status.HTTP_200_OK)
        self.assertIn("messages", convo.json())

        send = self.client.post("/api/v1/support/conversation/", {"body": "Need help with delivery"}, format="json")
        self.assertEqual(send.status_code, status.HTTP_201_CREATED)

    @override_settings(PAYSTACK_SECRET_KEY="", PAYSTACK_PUBLIC_KEY="")
    def test_group_gift_public_and_contribute(self):
        category = Category.objects.create(name="Hampers", slug="hampers")
        product = Product.objects.create(
            category=category,
            name="Celebration Hamper",
            slug="celebration-hamper",
            description="A hamper.",
            base_price="599.00",
            is_active=True,
        )
        address = self.client.post(
            "/api/v1/auth/addresses/",
            {
                "label": "Home",
                "recipient_name": "Team",
                "phone": "0821234567",
                "street_address": "1 Main Rd",
                "suburb": "Sandton",
                "city": "Johannesburg",
                "province": "Gauteng",
                "postal_code": "2196",
            },
            format="json",
        )
        self.client.post(
            f"/api/v1/orders/cart/items/",
            {"product_id": product.id, "quantity": 1},
            format="json",
        )

        gift = self.client.post(
            "/api/v1/group-gifts/",
            {
                "title": "Team birthday gift",
                "address_id": address.json()["id"],
                "delivery_date": (date.today() + timedelta(days=10)).isoformat(),
                "recipient_name": "Sarah",
            },
            format="json",
        )
        self.assertEqual(gift.status_code, status.HTTP_201_CREATED)
        token = gift.json()["share_token"]

        public = self.client.get(f"/api/v1/group-gifts/public/{token}/")
        self.assertEqual(public.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(user=None)
        initiate = self.client.post(
            f"/api/v1/group-gifts/public/{token}/contribute/",
            {
                "amount": "100.00",
                "contributor_name": "Friend",
                "contributor_email": "friend@example.com",
            },
            format="json",
        )
        self.assertEqual(initiate.status_code, status.HTTP_201_CREATED)
        self.assertTrue(initiate.json().get("demo_mode"))

    def test_product_ar_fields(self):
        category = Category.objects.create(name="Gifts", slug="gifts")
        Product.objects.create(
            category=category,
            name="AR Gift Box",
            slug="ar-gift-box",
            description="Preview in AR.",
            base_price="299.00",
            ar_enabled=True,
            preview_mode="image",
        )
        detail = self.client.get("/api/v1/products/ar-gift-box/")
        self.assertEqual(detail.status_code, status.HTTP_200_OK)
        self.assertTrue(detail.json().get("ar_enabled"))


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