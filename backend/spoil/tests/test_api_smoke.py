from datetime import date, timedelta

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.content.models import FAQ, StaticPage
from apps.orders.models import Cart, CartItem
from apps.products.models import Category, Product

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
        self.assertEqual(response.json()["app"], "Spoil")

    def test_catalog_home(self):
        response = self.client.get("/api/v1/products/home/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("categories", response.json())

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