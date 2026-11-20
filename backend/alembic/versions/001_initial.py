"""Initial migration creating all tables and FTS5 virtual tables.

Revision ID: 001_initial
Revises: 
Create Date: 2026-11-20 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

revision = "001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Users
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("username", sa.String(length=100), nullable=False, unique=True, index=True),
        sa.Column("password_hash", sa.String(length=256), nullable=False),
        sa.Column("display_name", sa.String(length=200), nullable=True),
        sa.Column("email", sa.String(length=254), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Schedules
    op.create_table(
        "schedules",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("event_date", sa.Date(), nullable=False),
        sa.Column("start_time", sa.Time(), nullable=True),
        sa.Column("end_time", sa.Time(), nullable=True),
        sa.Column("all_day", sa.Boolean(), default=False, nullable=False),
        sa.Column("location", sa.String(length=300), nullable=True),
        sa.Column("category", sa.String(length=100), nullable=True),
        sa.Column("priority", sa.String(length=20), default="medium", nullable=True),
        sa.Column("repeat_rule", sqlite.JSON(), nullable=True),
        sa.Column("reminder_offsets", sqlite.JSON(), nullable=True),
        sa.Column("status", sa.String(length=20), default="Active", nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("actual_start", sa.DateTime(timezone=True), nullable=True),
        sa.Column("actual_end", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("visibility", sa.String(length=20), default="private", nullable=True),
        sa.Column("custom_field_values", sqlite.JSON(), nullable=True),
        sa.Column("user_id", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Solicitations
    op.create_table(
        "solicitations",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=True),
        sa.Column("organization", sa.String(length=300), nullable=True),
        sa.Column("contact_person", sa.String(length=200), nullable=True),
        sa.Column("phone", sa.String(length=30), nullable=True),
        sa.Column("email", sa.String(length=254), nullable=True),
        sa.Column("amount_requested", sa.Float(), nullable=True),
        sa.Column("quantity_requested", sa.String(length=200), nullable=True),
        sa.Column("requested_date", sa.Date(), nullable=True),
        sa.Column("deadline", sa.Date(), nullable=True),
        sa.Column("follow_up_date", sa.Date(), nullable=True),
        sa.Column("status", sa.String(length=20), default="Draft", nullable=True),
        sa.Column("priority", sa.String(length=20), default="medium", nullable=True),
        sa.Column("category", sa.String(length=100), nullable=True),
        sa.Column("location", sa.String(length=300), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("given_date", sa.Date(), nullable=True),
        sa.Column("given_amount", sa.Float(), nullable=True),
        sa.Column("given_item", sa.String(length=300), nullable=True),
        sa.Column("given_by", sa.String(length=200), nullable=True),
        sa.Column("given_to", sa.String(length=200), nullable=True),
        sa.Column("source_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("receipt_proof", sa.String(length=500), nullable=True),
        sa.Column("custom_field_values", sqlite.JSON(), nullable=True),
        sa.Column("user_id", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Custom Fields
    op.create_table(
        "custom_fields",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("module", sa.String(length=20), nullable=False, index=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("field_type", sa.String(length=30), nullable=False),
        sa.Column("options", sqlite.JSON(), nullable=True),
        sa.Column("sort_order", sa.Integer(), default=0, nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True, nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Categories
    op.create_table(
        "categories",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("module", sa.String(length=20), nullable=False, index=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("color", sa.String(length=10), default="#2E7D32", nullable=False),
        sa.Column("sort_order", sa.Integer(), default=0, nullable=False),
        sa.Column("is_custom", sa.Boolean(), default=True, nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Audit Logs
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("item_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("module", sa.String(length=20), nullable=False, index=True),
        sa.Column("action", sa.String(length=20), nullable=False),
        sa.Column("field", sa.String(length=100), nullable=True),
        sa.Column("old_value", sa.Text(), nullable=True),
        sa.Column("new_value", sa.Text(), nullable=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("actor", sa.String(length=36), nullable=False),
        sa.Column("source", sa.String(length=30), default="api", nullable=False),
    )

    # Attachments
    op.create_table(
        "attachments",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("item_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("module", sa.String(length=20), nullable=False),
        sa.Column("file_path", sa.String(length=500), nullable=False),
        sa.Column("file_type", sa.String(length=50), nullable=True),
        sa.Column("purpose", sa.String(length=50), nullable=True),
        sa.Column("ocr_text", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Share Links
    op.create_table(
        "share_links",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("token", sa.String(length=64), unique=True, nullable=False, index=True),
        sa.Column("label", sa.String(length=200), nullable=True),
        sa.Column("scope", sqlite.JSON(), nullable=True),
        sa.Column("passcode_hash", sa.String(length=256), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("view_limit", sa.Integer(), nullable=True),
        sa.Column("view_count", sa.Integer(), default=0, nullable=False),
        sa.Column("privacy_controls", sqlite.JSON(), nullable=True),
        sa.Column("allow_export", sa.Boolean(), default=False, nullable=False),
        sa.Column("is_revoked", sa.Boolean(), default=False, nullable=False),
        sa.Column("user_id", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Viewer Access Logs
    op.create_table(
        "viewer_access_logs",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("share_link_id", sa.String(length=36), sa.ForeignKey("share_links.id"), nullable=False, index=True),
        sa.Column("accessed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("user_agent", sa.String(length=500), nullable=True),
        sa.Column("ip_hash", sa.String(length=64), nullable=True),
    )

    # ML Models
    op.create_table(
        "ml_models",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("model_type", sa.String(length=50), nullable=False),
        sa.Column("module", sa.String(length=20), nullable=False),
        sa.Column("version", sa.Integer(), default=1, nullable=False),
        sa.Column("model_data", sa.LargeBinary(), nullable=True),
        sa.Column("training_samples", sa.Integer(), default=0, nullable=False),
        sa.Column("accuracy", sa.Float(), nullable=True),
        sa.Column("trained_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("user_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # Sync States
    op.create_table(
        "sync_states",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("entity_type", sa.String(length=30), nullable=False, index=True),
        sa.Column("entity_id", sa.String(length=36), nullable=False, index=True),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sync_status", sa.String(length=20), default="pending", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), default=False, nullable=False),
    )

    # FTS5 Virtual Tables and Triggers
    conn = op.get_bind()
    conn.execute(sa.text("""
        CREATE VIRTUAL TABLE IF NOT EXISTS schedules_fts USING fts5(
            id UNINDEXED,
            title,
            description,
            location,
            notes,
            category,
            content=schedules,
            content_rowid=rowid
        );
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS schedules_ai AFTER INSERT ON schedules BEGIN
            INSERT INTO schedules_fts(rowid, id, title, description, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.description, new.location, new.notes, new.category);
        END;
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS schedules_ad AFTER DELETE ON schedules BEGIN
            INSERT INTO schedules_fts(schedules_fts, rowid, id, title, description, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.description, old.location, old.notes, old.category);
        END;
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS schedules_au AFTER UPDATE ON schedules BEGIN
            INSERT INTO schedules_fts(schedules_fts, rowid, id, title, description, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.description, old.location, old.notes, old.category);
            INSERT INTO schedules_fts(rowid, id, title, description, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.description, new.location, new.notes, new.category);
        END;
    """))

    conn.execute(sa.text("""
        CREATE VIRTUAL TABLE IF NOT EXISTS solicitations_fts USING fts5(
            id UNINDEXED,
            title,
            organization,
            contact_person,
            purpose,
            location,
            notes,
            category,
            content=solicitations,
            content_rowid=rowid
        );
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_ai AFTER INSERT ON solicitations BEGIN
            INSERT INTO solicitations_fts(rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.organization, new.contact_person, new.purpose, new.location, new.notes, new.category);
        END;
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_ad AFTER DELETE ON solicitations BEGIN
            INSERT INTO solicitations_fts(solicitations_fts, rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.organization, old.contact_person, old.purpose, old.location, old.notes, old.category);
        END;
    """))
    conn.execute(sa.text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_au AFTER UPDATE ON solicitations BEGIN
            INSERT INTO solicitations_fts(solicitations_fts, rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.organization, old.contact_person, old.purpose, old.location, old.notes, old.category);
            INSERT INTO solicitations_fts(rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.organization, new.contact_person, new.purpose, new.location, new.notes, new.category);
        END;
    """))


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("DROP TRIGGER IF EXISTS solicitations_au;"))
    conn.execute(sa.text("DROP TRIGGER IF EXISTS solicitations_ad;"))
    conn.execute(sa.text("DROP TRIGGER IF EXISTS solicitations_ai;"))
    conn.execute(sa.text("DROP TABLE IF EXISTS solicitations_fts;"))
    conn.execute(sa.text("DROP TRIGGER IF EXISTS schedules_au;"))
    conn.execute(sa.text("DROP TRIGGER IF EXISTS schedules_ad;"))
    conn.execute(sa.text("DROP TRIGGER IF EXISTS schedules_ai;"))
    conn.execute(sa.text("DROP TABLE IF EXISTS schedules_fts;"))

    op.drop_table("sync_states")
    op.drop_table("ml_models")
    op.drop_table("viewer_access_logs")
    op.drop_table("share_links")
    op.drop_table("attachments")
    op.drop_table("audit_logs")
    op.drop_table("categories")
    op.drop_table("custom_fields")
    op.drop_table("solicitations")
    op.drop_table("schedules")
    op.drop_table("users")
