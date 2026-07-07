from datetime import datetime

from django.db import transaction

from ..models import Occasion, Recipient


@transaction.atomic
def import_contacts(*, user, contacts: list[dict]) -> dict:
    created = 0
    skipped = 0
    for entry in contacts:
        name = (entry.get("name") or "").strip()
        if not name:
            skipped += 1
            continue
        external_id = (entry.get("external_id") or entry.get("id") or "").strip()
        if external_id and Recipient.objects.filter(user=user, external_id=external_id, source="contact").exists():
            skipped += 1
            continue
        if Recipient.objects.filter(user=user, name__iexact=name, source="contact").exists():
            skipped += 1
            continue
        Recipient.objects.create(
            user=user,
            name=name,
            relationship=entry.get("relationship", "Contact")[:50],
            notes=entry.get("notes", ""),
            popia_consent=bool(entry.get("popia_consent", False)),
            source="contact",
            external_id=external_id[:120],
        )
        created += 1
    return {"created": created, "skipped": skipped}


@transaction.atomic
def import_calendar_events(*, user, events: list[dict]) -> dict:
    created_occasions = 0
    created_recipients = 0
    skipped = 0

    for entry in events:
        title = (entry.get("title") or "").strip()
        date_str = entry.get("date") or entry.get("start_date")
        if not title or not date_str:
            skipped += 1
            continue
        try:
            if "T" in date_str:
                event_date = datetime.fromisoformat(date_str.replace("Z", "+00:00")).date()
            else:
                event_date = datetime.strptime(date_str[:10], "%Y-%m-%d").date()
        except ValueError:
            skipped += 1
            continue

        recipient_name = (entry.get("recipient_name") or title).strip()
        external_id = (entry.get("external_id") or entry.get("id") or "").strip()
        occasion_type = entry.get("type", "other")
        if occasion_type not in dict(Occasion.OCCASION_TYPES):
            occasion_type = "other"

        recipient = None
        if external_id:
            recipient = Recipient.objects.filter(user=user, external_id=external_id, source="calendar").first()
        if not recipient:
            recipient = Recipient.objects.filter(user=user, name__iexact=recipient_name).first()
        if not recipient:
            recipient = Recipient.objects.create(
                user=user,
                name=recipient_name,
                relationship=entry.get("relationship", "Calendar")[:50],
                popia_consent=bool(entry.get("popia_consent", False)),
                source="calendar",
                external_id=external_id[:120],
            )
            created_recipients += 1

        if Occasion.objects.filter(recipient=recipient, date=event_date, type=occasion_type).exists():
            skipped += 1
            continue

        Occasion.objects.create(
            recipient=recipient,
            type=occasion_type,
            date=event_date,
            reminder_days_before=int(entry.get("reminder_days_before", 14)),
            notes=entry.get("notes", ""),
            share_with_family=bool(entry.get("share_with_family", False)),
        )
        created_occasions += 1

    return {
        "recipients_created": created_recipients,
        "occasions_created": created_occasions,
        "skipped": skipped,
    }