"""Multi-format server-side export service: CSV, JSON, XLSX, PDF, PNG, ICS."""

import csv
import io
import json
from datetime import date, datetime
from typing import Any, Dict, List, Optional

from icalendar import Calendar, Event as ICalEvent
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from sqlalchemy.ext.asyncio import AsyncSession

from src.schemas.export import ExportFormat, ExportRequest
from src.services import schedule_service, solicitation_service
from src.utils.field_stripper import strip_fields


def _json_serial(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    return str(obj)


def export_json(items: List[Dict[str, Any]]) -> bytes:
    """Export items as JSON bytes."""
    return json.dumps(items, indent=2, default=_json_serial).encode("utf-8")


def export_csv(items: List[Dict[str, Any]], fieldnames: Optional[List[str]] = None) -> bytes:
    """Export items as CSV bytes."""
    output = io.StringIO()
    if not items:
        return "".encode("utf-8")

    keys = fieldnames or list(items[0].keys())
    writer = csv.DictWriter(output, fieldnames=keys, extrasaction="ignore")
    writer.writeheader()
    for it in items:
        row = {k: (_json_serial(v) if v is not None else "") for k, v in it.items()}
        writer.writerow(row)
    return output.getvalue().encode("utf-8")


def export_xlsx(items: List[Dict[str, Any]], title: str = "Export") -> bytes:
    """Export items as styled Excel workbook bytes."""
    wb = Workbook()
    ws = wb.active
    ws.title = title[:30]

    if not items:
        buf = io.BytesIO()
        wb.save(buf)
        return buf.getvalue()

    headers = list(items[0].keys())
    ws.append(headers)

    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="2E7D32", end_color="2E7D32", fill_type="solid")

    for col_num in range(1, len(headers) + 1):
        cell = ws.cell(row=1, column=col_num)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center")

    for it in items:
        row = [(_json_serial(it.get(h)) if it.get(h) is not None else "") for h in headers]
        ws.append(row)

    # Auto-adjust column widths
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col)
        col_letter = col[0].column_letter
        ws.column_dimensions[col_letter].width = max(max_len + 3, 12)

    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


def export_pdf(items: List[Dict[str, Any]], title: str = "Export Report") -> bytes:
    """Export items as formatted PDF document bytes."""
    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=landscape(letter), leftMargin=30, rightMargin=30, topMargin=30, bottomMargin=30)
    styles = getSampleStyleSheet()

    story = [
        Paragraph(f"<b>{title}</b>", styles["Title"]),
        Paragraph(f"Generated at: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}", styles["Normal"]),
        Spacer(1, 15),
    ]

    if not items:
        story.append(Paragraph("No items found.", styles["Normal"]))
    else:
        # Pick top 6 columns for PDF readability
        priority_cols = ["title", "status", "priority", "category", "event_date", "requested_date", "location"]
        keys = [k for k in priority_cols if k in items[0]] or list(items[0].keys())[:6]

        table_data = [[Paragraph(f"<b>{k.replace('_', ' ').title()}</b>", styles["Normal"]) for k in keys]]

        for it in items:
            row = []
            for k in keys:
                val = str(it.get(k) or "")
                row.append(Paragraph(val, styles["Normal"]))
            table_data.append(row)

        table = Table(table_data, repeatRows=1)
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2E7D32")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
            ("ALIGN", (0, 0), (-1, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F9F5")]),
        ]))
        story.append(table)

    doc.build(story)
    return buf.getvalue()


def export_png(items: List[Dict[str, Any]], title: str = "Export Image") -> bytes:
    """Render items table into an image with Pillow."""
    width = 1080
    row_height = 40
    header_height = 80
    total_height = max(200, min(header_height + len(items) * row_height + 40, 4000))

    img = Image.new("RGB", (width, total_height), color="#FFFFFF")
    draw = ImageDraw.Draw(img)

    # Header bar
    draw.rectangle([0, 0, width, header_height], fill="#2E7D32")
    draw.text((20, 25), title, fill="#FFFFFF")

    if items:
        keys = ["title", "status", "priority", "category"]
        keys = [k for k in keys if k in items[0]] or list(items[0].keys())[:4]
        col_width = width // len(keys)

        # Subheaders
        y = header_height + 10
        for i, k in enumerate(keys):
            draw.text((20 + i * col_width, y), k.replace("_", " ").title(), fill="#1B5E20")

        # Rows
        y += 30
        for idx, it in enumerate(items[:80]):
            bg_color = "#F5F9F5" if idx % 2 == 0 else "#FFFFFF"
            draw.rectangle([0, y - 5, width, y + row_height - 5], fill=bg_color)
            for i, k in enumerate(keys):
                val = str(it.get(k) or "")[:25]
                draw.text((20 + i * col_width, y), val, fill="#333333")
            y += row_height

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def export_ics(items: List[Dict[str, Any]]) -> bytes:
    """Generate ICS bytes from schedule items."""
    cal = Calendar()
    cal.add("prodid", "-//SchedSolicit Export//EN")
    cal.add("version", "2.0")

    for it in items:
        ev = ICalEvent()
        ev.add("summary", it.get("title", "Event"))
        if it.get("description"):
            ev.add("description", it["description"])
        if it.get("event_date"):
            ev.add("dtstart", it["event_date"])
        ev.add("uid", f"{it.get('id', 'item')}@schedsolicit")
        cal.add_component(ev)

    return cal.to_ical()


async def generate_export(
    db: AsyncSession,
    user_id: str,
    req: ExportRequest,
    privacy_controls: Optional[Dict[str, Any]] = None,
) -> bytes:
    """Fetch data and generate requested export format."""
    # Retrieve items
    if req.module == "schedule":
        raw_items = await schedule_service.list_schedules(
            db, user_id, filters=schedule_service.FilterParams(is_deleted=False),
            pagination=schedule_service.PaginationParams(page=1, per_page=1000),
            sort=schedule_service.SortParams(),
        )
        items = raw_items["items"]
    else:
        raw_items = await solicitation_service.list_solicitations(
            db, user_id, filters=solicitation_service.FilterParams(is_deleted=False),
            pagination=solicitation_service.PaginationParams(page=1, per_page=1000),
            sort=solicitation_service.SortParams(),
        )
        items = raw_items["items"]

    # Convert to dicts
    dict_items = [
        {c.name: getattr(it, c.name) for c in it.__table__.columns if not c.name.startswith("_")}
        for it in items
    ]

    # Filter item_ids if specified
    if req.item_ids:
        dict_items = [d for d in dict_items if d["id"] in req.item_ids]

    # Privacy stripping
    if privacy_controls:
        dict_items = strip_fields(dict_items, privacy_controls)

    fmt = req.format
    if fmt == ExportFormat.csv:
        return export_csv(dict_items, req.fields)
    elif fmt == ExportFormat.json:
        return export_json(dict_items)
    elif fmt == ExportFormat.xlsx:
        return export_xlsx(dict_items, req.title or "Export")
    elif fmt == ExportFormat.pdf:
        return export_pdf(dict_items, req.title or "Export Report")
    elif fmt == ExportFormat.png:
        return export_png(dict_items, req.title or "Export Image")
    elif fmt == ExportFormat.ics:
        return export_ics(dict_items)
    else:
        return export_json(dict_items)
