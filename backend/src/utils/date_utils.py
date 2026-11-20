"""Date utilities: UTC conversion, formatting, and DST-safe recurrence expansion."""

from datetime import date, datetime, time, timedelta, timezone
from typing import Any, Dict, List, Optional, Union
import calendar

Union_date = Union[date, datetime]


def to_utc(dt: datetime) -> datetime:
    """Ensure datetime has UTC timezone."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def now_utc() -> datetime:
    """Return current UTC datetime."""
    return datetime.now(timezone.utc)


def format_iso_date(d: Optional[Union_date]) -> Optional[str]:
    """Format date to YYYY-MM-DD."""
    return d.isoformat() if d else None


def format_iso_datetime(dt: Optional[datetime]) -> Optional[str]:
    """Format datetime to ISO 8601 string."""
    return dt.isoformat() if dt else None


def add_months(sourcedate: date, months: int) -> date:
    """Safely add months to a date preserving end-of-month logic."""
    month = sourcedate.month - 1 + months
    year = sourcedate.year + month // 12
    month = month % 12 + 1
    day = min(sourcedate.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def expand_recurrence(
    start_date: date,
    repeat_rule: Dict[str, Any],
    max_occurrences: int = 100,
    until_date: Optional[date] = None,
) -> List[date]:
    """Expand a recurrence rule into a list of dates.
    
    repeat_rule schema:
    {
        "frequency": "daily" | "weekly" | "monthly" | "yearly",
        "interval": int (default 1),
        "count": Optional[int],
        "until": Optional[str (YYYY-MM-DD)],
        "by_day": Optional[List[int]] (0=Monday, 6=Sunday for weekly)
    }
    """
    if not repeat_rule:
        return [start_date]

    freq = repeat_rule.get("frequency", "daily").lower()
    interval = max(1, int(repeat_rule.get("interval", 1)))
    rule_count = repeat_rule.get("count")
    rule_until_str = repeat_rule.get("until")
    
    effective_until = until_date
    if rule_until_str:
        parsed_until = date.fromisoformat(rule_until_str)
        if effective_until is None or parsed_until < effective_until:
            effective_until = parsed_until

    limit = min(max_occurrences, rule_count if rule_count else max_occurrences)

    occurrences = [start_date]
    curr = start_date

    while len(occurrences) < limit:
        if freq == "daily":
            curr = curr + timedelta(days=interval)
        elif freq == "weekly":
            curr = curr + timedelta(weeks=interval)
        elif freq == "monthly":
            curr = add_months(curr, interval)
        elif freq == "yearly":
            try:
                curr = curr.replace(year=curr.year + interval)
            except ValueError:
                # Handle Feb 29 leap year
                curr = curr.replace(year=curr.year + interval, day=28)
        else:
            break

        if effective_until and curr > effective_until:
            break

        occurrences.append(curr)

    return occurrences
