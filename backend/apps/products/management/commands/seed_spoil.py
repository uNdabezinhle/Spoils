from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.content.models import FAQ, StaticPage
from apps.subscriptions.models import SubscriptionPlan
from apps.orders.models import PromoCode
from apps.products.models import Category, MessageTemplate, Product, WrappingOption


class Command(BaseCommand):
    help = "Seed Spoil with categories, products, wrapping options, and content."

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write("Seeding Spoil catalogue…")

        categories_data = [
            ("flowers", "Flowers", "Fresh, beautiful bouquets for every occasion.", 1),
            ("hampers", "Hampers", "Curated luxury hampers — spoil them properly.", 2),
            ("personalised", "Personalised Gifts", "Gifts made personal with love.", 3),
            ("experiences", "Experiences", "Memorable moments they'll never forget.", 4),
            ("just-because", "Just Because", "No reason needed — just spoil them.", 5),
        ]

        categories = {}
        for slug, name, desc, order in categories_data:
            cat, _ = Category.objects.update_or_create(
                slug=slug,
                defaults={
                    "name": name,
                    "description": desc,
                    "sort_order": order,
                    "is_active": True,
                    "image_url": f"https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=400&h=300&fit=crop",
                },
            )
            categories[slug] = cat

        # slug, name, category, description, price, featured, popular, delivery, occasion
        products_data = [
            ("spring-bloom-bouquet", "Spring Bloom Bouquet", "flowers", "A lush arrangement of seasonal blooms — roses, proteas and eucalyptus. Perfect for birthdays and thank-yous.", "449.00", True, True, "Same-day delivery in JHB, CPT, DBN", "birthday"),
            ("classic-rose-dozen", "Classic Rose Dozen", "flowers", "Twelve premium red roses, hand-tied with satin ribbon.", "599.00", True, False, "Next-day nationwide", "anniversary"),
            ("sunshine-sunflowers", "Sunshine Sunflowers", "flowers", "Bright sunflowers to light up their day.", "379.00", False, True, "Same-day in major metros", "thank_you"),
            ("elegant-lilies", "Elegant White Lilies", "flowers", "Pure white lilies — sophisticated and serene.", "429.00", False, False, "2–3 business days", "other"),
            ("protea-pride", "Protea Pride Bouquet", "flowers", "Proudly South African proteas with fynbos accents.", "499.00", True, False, "Same-day in CPT", "birthday"),
            ("luxury-gourmet-hamper", "Luxury Gourmet Hamper", "hampers", "Artisan chocolates, preserves, biscuits and premium tea.", "899.00", True, True, "2–3 business days nationwide", "anniversary"),
            ("wine-cheese-hamper", "Wine & Cheese Hamper", "hampers", "Local wine, aged cheddar, crackers and fig preserve.", "749.00", True, False, "Nationwide courier", "thank_you"),
            ("spa-retreat-hamper", "Spa Retreat Hamper", "hampers", "Bath salts, scented candles, body lotion and plush towel.", "649.00", False, True, "2–3 business days", "just_because"),
            ("coffee-lovers-hamper", "Coffee Lover's Hamper", "hampers", "Specialty beans, mug, shortbread and artisan chocolate.", "549.00", False, False, "Nationwide", "birthday"),
            ("celebration-snack-box", "Celebration Snack Box", "hampers", "Sweet and savoury treats for sharing.", "399.00", False, True, "1–2 business days", "just_because"),
            ("personalised-mug", "Personalised Photo Mug", "personalised", "Upload a photo — we'll print a premium ceramic mug.", "299.00", True, True, "5–7 business days", "birthday"),
            ("engraved-keyring", "Engraved Keyring", "personalised", "Custom text engraving on a brushed steel keyring.", "199.00", False, False, "5–7 business days", "anniversary"),
            ("custom-candle", "Custom Scented Candle", "personalised", "Choose scent and add a personal message on the label.", "349.00", False, True, "5–7 business days", "thank_you"),
            ("photo-frame-gift", "Photo Frame Gift Set", "personalised", "Beautiful wooden frame with optional message card.", "279.00", False, False, "3–5 business days", "other"),
            ("monogram-tote", "Monogram Tote Bag", "personalised", "Canvas tote with embroidered initials.", "399.00", True, False, "7–10 business days", "birthday"),
            ("spa-day-voucher", "Spa Day Voucher", "experiences", "Full spa day for two at a premium partner spa.", "1299.00", True, True, "Voucher delivered instantly", "anniversary"),
            ("wine-tasting-experience", "Wine Tasting Experience", "experiences", "Private tasting for two in the Cape Winelands.", "999.00", True, False, "Book within 30 days", "anniversary"),
            ("hot-air-balloon", "Hot Air Balloon Ride", "experiences", "Sunrise balloon flight — an unforgettable adventure.", "2499.00", False, True, "Subject to availability", "birthday"),
            ("cooking-class-duo", "Cooking Class for Two", "experiences", "Hands-on class with a local chef.", "799.00", False, False, "Book within 60 days", "just_because"),
            ("sunset-picnic", "Sunset Picnic Experience", "experiences", "Curated picnic basket at a scenic location.", "699.00", False, True, "CPT & JHB only", "anniversary"),
            ("thinking-of-you", "Thinking of You Box", "just-because", "A sweet surprise box of treats and a heartfelt card.", "329.00", True, True, "Same-day in major metros", "just_because"),
            ("chocolate-indulgence", "Chocolate Indulgence Box", "just-because", "Handcrafted Belgian chocolates in a gift box.", "279.00", False, True, "1–2 business days", "just_because"),
            ("comfort-tea-set", "Comfort Tea Set", "just-because", "Premium teas, honey and a cosy mug.", "249.00", False, False, "2–3 business days", "thank_you"),
            ("mini-succulent-garden", "Mini Succulent Garden", "just-because", "Three succulents in a ceramic planter.", "199.00", False, True, "Same-day in JHB & CPT", "just_because"),
        ]

        image_seeds = {
            "flowers": "photo-1490750967868-88d62216e903",
            "hampers": "photo-1549465220-1a0b6e55668e",
            "personalised": "photo-1513885535751-8b9238bd345a",
            "experiences": "photo-1506905925346-21bda4d32df4",
            "just-because": "photo-1513201099705-a9746e1e201f",
        }

        for slug, name, cat_slug, desc, price, featured, popular, delivery, occasion in products_data:
            img_id = image_seeds.get(cat_slug, "photo-1513885535751-8b9238bd345a")
            Product.objects.update_or_create(
                slug=slug,
                defaults={
                    "name": name,
                    "category": categories[cat_slug],
                    "description": desc,
                    "base_price": Decimal(price),
                    "image_url": f"https://images.unsplash.com/{img_id}?w=600&h=600&fit=crop",
                    "delivery_info": delivery,
                    "occasion": occasion,
                    "is_featured": featured,
                    "is_popular": popular,
                    "is_active": True,
                },
            )

        wrapping_data = [
            ("Classic Cream", "#FDF8F3", "0.00"),
            ("Warm Gold Ribbon", "#C9A227", "49.00"),
            ("Deep Teal Elegance", "#0F766E", "49.00"),
            ("Soft Blush Wrap", "#F8E7E7", "39.00"),
        ]
        for name, colour, price in wrapping_data:
            WrappingOption.objects.update_or_create(
                name=name,
                defaults={"ribbon_color": colour, "price": Decimal(price), "is_active": True},
            )

        templates = [
            ("birthday", "Happy Birthday!", "Wishing you the happiest of birthdays! Hope your day is as wonderful as you are."),
            ("anniversary", "Happy Anniversary", "Celebrating your love today and always. Here's to many more beautiful years together."),
            ("thank_you", "Thank You", "Thank you for everything — your kindness means the world to me."),
            ("just_because", "Just Because", "No special reason — just wanted you to know you're thought of and loved."),
        ]
        for occasion, title, message in templates:
            MessageTemplate.objects.update_or_create(
                title=title,
                defaults={"occasion": occasion, "message": message, "is_active": True},
            )

        PromoCode.objects.update_or_create(
            code="SPOIL10",
            defaults={"discount_percent": 10, "is_active": True},
        )

        faqs = [
            ("How long does delivery take?", "Delivery times vary by product and location. Same-day delivery is available in Johannesburg, Cape Town and Durban for selected gifts. Most orders arrive within 2–5 business days."),
            ("Can I add a personal message?", "Absolutely! Every gift can include a heartfelt message. Many gifts also support photo uploads and custom wrapping."),
            ("Do you deliver nationwide?", "Yes — we deliver across South Africa. Remote areas may take a little longer, and we'll keep you updated every step of the way."),
        ]
        for i, (q, a) in enumerate(faqs):
            FAQ.objects.update_or_create(question=q, defaults={"answer": a, "sort_order": i, "is_active": True})

        pages = [
            ("about", "About Spoils", "Spoils is South Africa's modern gift shop. We help you spoil the people who matter most — beautifully and effortlessly."),
            ("how_it_works", "How It Works", "1. Browse our curated gifts\n2. Personalise with a message or photo\n3. Choose delivery date and address\n4. We wrap it beautifully and deliver with care"),
            ("terms", "Terms of Service", "By using Spoil you agree to our terms. Orders are subject to product availability and delivery conditions."),
            ("privacy", "Privacy Policy", "We respect your privacy and comply with POPIA. Your data is stored securely and never sold to third parties."),
        ]
        for page_type, title, content in pages:
            StaticPage.objects.update_or_create(
                page_type=page_type,
                defaults={"title": title, "content": content},
            )

        plans = [
            (
                "monthly-spoil-box",
                "Monthly Spoil Box",
                "spoil_box",
                "Curated joy, delivered monthly.",
                "A rotating themed gift box each month — self-care, celebration, gratitude and more.",
                "499.00",
                ["Curated monthly theme", "Free delivery", "Pause anytime"],
            ),
            (
                "someone-to-spoil",
                "Someone to Spoil",
                "someone_to_spoil",
                "Spoil them every month.",
                "Send a thoughtful gift to someone special on the same day each month.",
                "399.00",
                ["Named recipient", "Surprise & delight", "Skip a month anytime"],
            ),
            (
                "gift-credit",
                "Gift Credit",
                "gift_credit",
                "Flexible monthly gifting credit.",
                "R299 monthly credit to spend on any gift in the store. Unused credit rolls over.",
                "299.00",
                ["Use on any gift", "Credit rolls over", "No lock-in"],
            ),
            (
                "occasion-auto",
                "Occasion Auto-Gift",
                "occasion_auto",
                "Never miss an important date.",
                "Pairs with My People reminders — approve suggested gifts before they send.",
                "349.00",
                ["Occasion-linked", "You approve each gift", "Smart suggestions"],
            ),
        ]
        for i, (slug, name, model_type, tagline, description, price, features) in enumerate(plans):
            SubscriptionPlan.objects.update_or_create(
                slug=slug,
                defaults={
                    "name": name,
                    "model_type": model_type,
                    "tagline": tagline,
                    "description": description,
                    "price_monthly": Decimal(price),
                    "features": features,
                    "sort_order": i,
                    "is_active": True,
                    "image_url": "https://images.unsplash.com/photo-1549465220-1a0b6e55668e?w=600&h=400&fit=crop",
                },
            )

        self.stdout.write(self.style.SUCCESS(
            f"Done! {Category.objects.count()} categories, {Product.objects.count()} products, "
            f"{SubscriptionPlan.objects.count()} subscription plans seeded."
        ))