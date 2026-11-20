"""Server-side field stripping utility based on privacy controls."""

from typing import Any, Dict, List, Union


def strip_fields(
    item_or_items: Union[Dict[str, Any], List[Dict[str, Any]]],
    privacy_controls: Dict[str, Any] = None,
) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
    """Strip sensitive fields from dictionary representation according to privacy controls.
    
    Fields are completely removed (not set to None) so they never leave the server.
    Privacy controls flags:
    - summary_only: bool (only keep id, title, status, event_date/requested_date, category)
    - hide_amounts: bool (strip amount_requested, given_amount)
    - hide_contacts: bool (strip organization, contact_person, phone, email, given_by, given_to)
    - hide_notes: bool (strip notes, description)
    - hide_attachments: bool (strip receipt_proof, attachments)
    """
    if privacy_controls is None:
        privacy_controls = {}

    if isinstance(item_or_items, list):
        return [strip_single_item(item, privacy_controls) for item in item_or_items]
    return strip_single_item(item_or_items, privacy_controls)


def strip_single_item(item: Dict[str, Any], controls: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(item, dict):
        # In case item is a model instance or other object, convert to dict
        if hasattr(item, "__dict__"):
            item = {k: v for k, v in item.__dict__.items() if not k.startswith("_")}
        else:
            return item

    data = dict(item)

    # 1. Summary only takes precedence
    if controls.get("summary_only"):
        allowed_keys = {
            "id",
            "title",
            "status",
            "priority",
            "category",
            "event_date",
            "start_time",
            "end_time",
            "all_day",
            "requested_date",
            "deadline",
            "created_at",
            "updated_at",
        }
        return {k: v for k, v in data.items() if k in allowed_keys}

    # 2. Hide amounts
    if controls.get("hide_amounts"):
        amount_fields = ["amount_requested", "given_amount"]
        for f in amount_fields:
            data.pop(f, None)
        if isinstance(data.get("custom_field_values"), dict):
            data["custom_field_values"] = {
                k: v for k, v in data["custom_field_values"].items()
                if not any(term in k.lower() for term in ["amount", "cost", "price", "budget", "fee", "grant"])
            }

    # 3. Hide contacts
    if controls.get("hide_contacts"):
        contact_fields = ["organization", "contact_person", "phone", "email", "given_by", "given_to"]
        for f in contact_fields:
            data.pop(f, None)
        if isinstance(data.get("custom_field_values"), dict):
            data["custom_field_values"] = {
                k: v for k, v in data["custom_field_values"].items()
                if not any(term in k.lower() for term in ["contact", "phone", "email", "mobile", "address", "donor"])
            }

    # 4. Hide notes
    if controls.get("hide_notes"):
        note_fields = ["notes", "description"]
        for f in note_fields:
            data.pop(f, None)
        if isinstance(data.get("custom_field_values"), dict):
            data["custom_field_values"] = {
                k: v for k, v in data["custom_field_values"].items()
                if not any(term in k.lower() for term in ["note", "desc", "comment", "remark"])
            }

    # 5. Hide attachments
    if controls.get("hide_attachments"):
        attachment_fields = ["receipt_proof", "attachments"]
        for f in attachment_fields:
            data.pop(f, None)

    return data
