"""Smart gift suggestions — keyword intelligence with optional OpenAI enrichment."""

import json
import re
from decimal import Decimal

import requests
from django.conf import settings

from apps.orders.models import OrderItem
from apps.products.models import Product
from apps.products.serializers import ProductListSerializer


def _note_keywords(notes: str) -> set[str]:
    if not notes:
        return set()
    tokens = re.findall(r"[a-zA-Z]{3,}", notes.lower())
    stop = {"the", "and", "for", "she", "her", "him", "his", "likes", "loves", "enjoys"}
    return {t for t in tokens if t not in stop}


def _score_product(*, product: Product, occasion, purchased_ids: set[int], keywords: set[str]) -> tuple[int, str]:
    score = 0
    reasons: list[str] = []
    blob = f"{product.name} {product.description} {product.category.name} {product.occasion}".lower()

    if product.occasion == occasion.type:
        score += 40
        reasons.append(f"matched their {occasion.get_type_display().lower()}")

    for kw in keywords:
        if kw in blob:
            score += 25
            reasons.append(f"fits their note about “{kw}”")
            break

    if product.id in purchased_ids:
        score += 15
        reasons.append("you've ordered this before")

    if product.is_featured:
        score += 12
        reasons.append("staff favourite")
    if product.is_popular:
        score += 8
        reasons.append("trending now")

    if occasion.surprise_budget and product.base_price <= Decimal(str(occasion.surprise_budget)):
        score += 10
        reasons.append("within your surprise budget")

    if occasion.recipient.relationship:
        rel = occasion.recipient.relationship.lower()
        if rel in blob or (rel in {"mom", "mother", "dad", "father"} and "family" in blob):
            score += 6
            reasons.append(f"great for a {occasion.recipient.relationship}")

    pick_reason = (
        f"Why we picked this: {reasons[0].capitalize()}."
        if reasons
        else f"A thoughtful pick for {occasion.recipient.name}."
    )
    return score, pick_reason


def _openai_rank(*, occasion, candidates: list[Product], limit: int) -> list[int] | None:
    api_key = getattr(settings, "OPENAI_API_KEY", "") or ""
    if not api_key or len(candidates) < 2:
        return None

    catalog = [
        {
            "id": p.id,
            "name": p.name,
            "price": str(p.base_price),
            "occasion": p.occasion,
            "category": p.category.name,
        }
        for p in candidates[:20]
    ]
    prompt = (
        f"Pick the best {limit} gift product IDs for {occasion.recipient.name}'s "
        f"{occasion.get_type_display()} (relationship: {occasion.recipient.relationship}). "
        f"Notes: {occasion.recipient.notes or 'none'}. "
        f"Reply with JSON only: {{\"product_ids\": [1,2,3]}} from catalog {json.dumps(catalog)}"
    )
    try:
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
            json={
                "model": getattr(settings, "OPENAI_MODEL", "gpt-4o-mini"),
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.3,
            },
            timeout=20,
        )
        if not response.ok:
            return None
        content = response.json()["choices"][0]["message"]["content"]
        match = re.search(r"\{.*\}", content, re.DOTALL)
        if not match:
            return None
        data = json.loads(match.group())
        ids = data.get("product_ids", [])
        return [int(i) for i in ids if isinstance(i, (int, str))][:limit]
    except (KeyError, ValueError, requests.RequestException, json.JSONDecodeError):
        return None


def suggest_gifts_for_occasion(*, occasion, user, limit: int = 8) -> list[dict]:
    paid_statuses = ["paid", "processing", "shipped", "delivered"]
    purchased_ids = set(
        OrderItem.objects.filter(order__user=user, order__status__in=paid_statuses).values_list(
            "product_id", flat=True
        )
    )
    keywords = _note_keywords(occasion.recipient.notes)

    pool = list(
        Product.objects.filter(is_active=True).select_related("category").order_by("-is_featured", "-is_popular")
    )
    ranked = sorted(
        pool,
        key=lambda p: _score_product(product=p, occasion=occasion, purchased_ids=purchased_ids, keywords=keywords)[0],
        reverse=True,
    )

    ai_ids = _openai_rank(occasion=occasion, candidates=ranked, limit=limit)
    if ai_ids:
        by_id = {p.id: p for p in ranked}
        selected = [by_id[i] for i in ai_ids if i in by_id]
        if len(selected) < limit:
            for p in ranked:
                if p not in selected:
                    selected.append(p)
                if len(selected) >= limit:
                    break
    else:
        selected = ranked[:limit]

    serialized = ProductListSerializer(selected, many=True).data
    for item, product in zip(serialized, selected):
        _, reason = _score_product(
            product=product, occasion=occasion, purchased_ids=purchased_ids, keywords=keywords
        )
        if ai_ids:
            item["pick_reason"] = f"{reason} AI-ranked for {occasion.recipient.name}."
            item["ai_ranked"] = True
        else:
            item["pick_reason"] = reason
            item["ai_ranked"] = False
    return serialized