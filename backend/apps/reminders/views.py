import calendar
from datetime import date, timedelta

from django.utils import timezone

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Occasion, Recipient, ReminderLog
from .serializers import RecipientSerializer
from .services.auto_gift import approve_proposal, reject_proposal, serialize_pending_proposal
from .services.suggestions import suggest_gifts_for_occasion
from .utils import next_occurrence_on


def _user_occasion(user, pk):
    try:
        return Occasion.objects.select_related("recipient").get(
            pk=pk,
            recipient__user=user,
        )
    except Occasion.DoesNotExist:
        return None


def _serialize_occasion(o: Occasion, *, today):
    next_date = next_occurrence_on(o.date, today=today)
    return {
        "id": o.id,
        "recipient_id": o.recipient_id,
        "recipient_name": o.recipient.name,
        "relationship": o.recipient.relationship,
        "type": o.type,
        "type_label": o.get_type_display(),
        "date": next_date.isoformat(),
        "original_date": o.date.isoformat(),
        "reminder_days_before": o.reminder_days_before,
        "days_until": (next_date - today).days,
    }


def _user_recipient(user, pk):
    try:
        return Recipient.objects.prefetch_related("occasions").get(pk=pk, user=user)
    except Recipient.DoesNotExist:
        return None


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def recipient_list(request):
    if request.method == "GET":
        recipients = Recipient.objects.filter(user=request.user).prefetch_related("occasions")
        return Response(RecipientSerializer(recipients, many=True).data)
    serializer = RecipientSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save(user=request.user)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def recipient_detail(request, pk):
    recipient = _user_recipient(request.user, pk)
    if not recipient:
        return Response({"detail": "Recipient not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(RecipientSerializer(recipient).data)

    if request.method == "DELETE":
        recipient.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = RecipientSerializer(recipient, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def upcoming_occasions(request):
    today = timezone.localdate()
    occasions = (
        Occasion.objects.filter(recipient__user=request.user, is_active=True)
        .select_related("recipient")
        .order_by("date")[:20]
    )
    data = sorted(
        [_serialize_occasion(o, today=today) for o in occasions],
        key=lambda item: item["days_until"],
    )
    return Response(data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def in_app_reminders(request):
    """Occasions currently in the reminder window for in-app banners."""
    today = timezone.localdate()
    feed = []
    occasions = Occasion.objects.filter(
        recipient__user=request.user,
        is_active=True,
    ).select_related("recipient")

    for occasion in occasions:
        if occasion.snoozed_until and today <= occasion.snoozed_until:
            continue
        next_date = next_occurrence_on(occasion.date, today=today)
        if ReminderLog.objects.filter(occasion=occasion, status="skipped", skip_year=next_date.year).exists():
            continue
        reminder_start = next_date - timedelta(days=occasion.reminder_days_before)
        if reminder_start <= today <= next_date:
            days_until = (next_date - today).days
            feed.append(
                {
                    **_serialize_occasion(occasion, today=today),
                    "message": (
                        f"{occasion.recipient.name}'s {occasion.get_type_display().lower()} "
                        f"is {'today' if days_until == 0 else f'in {days_until} days'} — time to spoil them."
                    ),
                    "shop_occasion": occasion.type,
                }
            )

    feed.sort(key=lambda item: item["days_until"])
    return Response(feed)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def occasion_detail(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)
    today = timezone.localdate()
    next_date = next_occurrence_on(occasion.date, today=today)
    return Response(
        {
            **_serialize_occasion(occasion, today=today),
            "recipient_notes": occasion.recipient.notes,
            "occasion_notes": occasion.notes,
            "snoozed_until": occasion.snoozed_until.isoformat() if occasion.snoozed_until else None,
            "skipped_this_year": ReminderLog.objects.filter(
                occasion=occasion,
                status="skipped",
                skip_year=next_date.year,
            ).exists(),
            "pending_auto_gift": serialize_pending_proposal(user=request.user, occasion=occasion),
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def occasion_suggestions(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)
    products = suggest_gifts_for_occasion(occasion=occasion, user=request.user)
    return Response({"occasion_id": occasion.id, "products": products})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def occasion_snooze(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)
    days = int(request.data.get("days", 3))
    days = max(1, min(days, 14))
    today = timezone.localdate()
    occasion.snoozed_until = today + timedelta(days=days)
    occasion.save(update_fields=["snoozed_until"])
    ReminderLog.objects.create(occasion=occasion, status="snoozed")
    return Response(
        {
            "detail": f"Reminder snoozed until {occasion.snoozed_until.isoformat()}.",
            "snoozed_until": occasion.snoozed_until.isoformat(),
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def occasion_skip(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)
    today = timezone.localdate()
    skip_year = next_occurrence_on(occasion.date, today=today).year
    ReminderLog.objects.create(occasion=occasion, status="skipped", skip_year=skip_year)
    return Response({"detail": f"Skipped reminders for {skip_year}.", "skip_year": skip_year})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def occasion_pending_gift(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)
    proposal = serialize_pending_proposal(user=request.user, occasion=occasion)
    if not proposal:
        return Response({"proposal": None})
    return Response({"proposal": proposal})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def occasion_approve_gift(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)

    from .services.auto_gift import get_pending_proposal

    proposal = get_pending_proposal(user=request.user, occasion=occasion)
    if not proposal:
        return Response({"detail": "No pending gift to approve."}, status=404)

    address_id = request.data.get("address_id")
    if not address_id:
        return Response({"detail": "address_id is required."}, status=400)

    product_id = request.data.get("product_id")
    try:
        result = approve_proposal(
            proposal=proposal,
            address_id=int(address_id),
            product_id=int(product_id) if product_id else None,
        )
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)

    return Response(result)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def occasion_reject_gift(request, pk):
    occasion = _user_occasion(request.user, pk)
    if not occasion:
        return Response({"detail": "Occasion not found."}, status=404)

    from .services.auto_gift import get_pending_proposal

    proposal = get_pending_proposal(user=request.user, occasion=occasion)
    if not proposal:
        return Response({"detail": "No pending gift to reject."}, status=404)

    try:
        reject_proposal(proposal=proposal)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)

    return Response({"detail": "Gift proposal rejected."})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def occasion_calendar(request):
    today = timezone.localdate()
    try:
        year = int(request.query_params.get("year", today.year))
        month = int(request.query_params.get("month", today.month))
    except (TypeError, ValueError):
        return Response({"detail": "year and month must be integers."}, status=400)

    if month < 1 or month > 12:
        return Response({"detail": "month must be 1-12."}, status=400)

    occasions = Occasion.objects.filter(
        recipient__user=request.user,
        is_active=True,
    ).select_related("recipient")

    by_date: dict[str, list] = {}
    for occasion in occasions:
        try:
            occurrence = occasion.date.replace(year=year)
        except ValueError:
            occurrence = date(year, 2, 28)
        if occurrence.month != month:
            continue
        key = occurrence.isoformat()
        payload = _serialize_occasion(occasion, today=today)
        payload["date"] = occurrence.isoformat()
        payload["days_until"] = (occurrence - today).days
        by_date.setdefault(key, []).append(payload)

    return Response(
        {
            "year": year,
            "month": month,
            "month_name": calendar.month_name[month],
            "days_in_month": calendar.monthrange(year, month)[1],
            "events": by_date,
        }
    )