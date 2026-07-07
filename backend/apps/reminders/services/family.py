import calendar

from django.utils import timezone

from ..models import FamilyGroup, FamilyMembership, Occasion
from ..utils import next_occurrence_on


def get_user_family_group(user) -> FamilyGroup | None:
    membership = FamilyMembership.objects.filter(user=user).select_related("group").first()
    return membership.group if membership else None


def serialize_family_group(group: FamilyGroup, *, user) -> dict:
    members = (
        FamilyMembership.objects.filter(group=group)
        .select_related("user")
        .order_by("joined_at")
    )
    return {
        "id": group.id,
        "name": group.name,
        "invite_code": group.invite_code,
        "is_owner": group.owner_id == user.id,
        "members": [
            {
                "user_id": m.user_id,
                "email": m.user.email,
                "display_name": m.user.get_full_name() or m.user.email,
                "role": m.role,
            }
            for m in members
        ],
    }


def family_calendar(*, group: FamilyGroup, year: int, month: int) -> dict:
    today = timezone.localdate()
    member_ids = FamilyMembership.objects.filter(group=group).values_list("user_id", flat=True)
    occasions = Occasion.objects.filter(
        recipient__user_id__in=member_ids,
        is_active=True,
        share_with_family=True,
        recipient__popia_consent=True,
    ).select_related("recipient", "recipient__user")

    by_date: dict[str, list] = {}
    for occasion in occasions:
        try:
            occurrence = occasion.date.replace(year=year)
        except ValueError:
            occurrence = occasion.date.replace(year=year, day=28)
        if occurrence.month != month:
            continue
        key = occurrence.isoformat()
        next_date = next_occurrence_on(occasion.date, today=today)
        payload = {
            "id": occasion.id,
            "recipient_name": occasion.recipient.name,
            "owner_email": occasion.recipient.user.email,
            "type": occasion.type,
            "type_label": occasion.get_type_display(),
            "date": occurrence.isoformat(),
            "days_until": (occurrence - today).days,
            "surprise_mode_enabled": occasion.surprise_mode_enabled,
        }
        by_date.setdefault(key, []).append(payload)

    return {
        "year": year,
        "month": month,
        "month_name": calendar.month_name[month],
        "days_in_month": calendar.monthrange(year, month)[1],
        "events": by_date,
        "group_name": group.name,
    }