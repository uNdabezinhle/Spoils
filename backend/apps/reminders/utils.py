from datetime import date


def next_occurrence_on(occasion_date: date, *, today: date | None = None) -> date:
    """Return the next calendar occurrence of a yearly occasion on or after today."""
    today = today or date.today()
    try:
        candidate = occasion_date.replace(year=today.year)
    except ValueError:
        candidate = date(today.year, 2, 28)
    if candidate < today:
        try:
            return occasion_date.replace(year=today.year + 1)
        except ValueError:
            return date(today.year + 1, 2, 28)
    return candidate