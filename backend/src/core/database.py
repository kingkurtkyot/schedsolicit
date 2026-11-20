"""Async SQLAlchemy engine, Base, session factory, FTS5 setup."""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import MetaData, event, text
from typing import AsyncGenerator

from src.core.config import settings

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def setup_fts5(conn) -> None:
    """Create FTS5 virtual tables and triggers for full-text search."""
    raw = conn
    # Schedules FTS
    await raw.execute(text("""
        CREATE VIRTUAL TABLE IF NOT EXISTS schedules_fts USING fts5(
            id UNINDEXED,
            title,
            description,
            location,
            notes,
            category,
            content=schedules,
            content_rowid=rowid
        )
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS schedules_ai AFTER INSERT ON schedules BEGIN
            INSERT INTO schedules_fts(rowid, id, title, description, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.description, new.location, new.notes, new.category);
        END
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS schedules_ad AFTER DELETE ON schedules BEGIN
            INSERT INTO schedules_fts(schedules_fts, rowid, id, title, description, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.description, old.location, old.notes, old.category);
        END
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS schedules_au AFTER UPDATE ON schedules BEGIN
            INSERT INTO schedules_fts(schedules_fts, rowid, id, title, description, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.description, old.location, old.notes, old.category);
            INSERT INTO schedules_fts(rowid, id, title, description, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.description, new.location, new.notes, new.category);
        END
    """))
    # Solicitations FTS
    await raw.execute(text("""
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
        )
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_ai AFTER INSERT ON solicitations BEGIN
            INSERT INTO solicitations_fts(rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.organization, new.contact_person, new.purpose, new.location, new.notes, new.category);
        END
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_ad AFTER DELETE ON solicitations BEGIN
            INSERT INTO solicitations_fts(solicitations_fts, rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.organization, old.contact_person, old.purpose, old.location, old.notes, old.category);
        END
    """))
    await raw.execute(text("""
        CREATE TRIGGER IF NOT EXISTS solicitations_au AFTER UPDATE ON solicitations BEGIN
            INSERT INTO solicitations_fts(solicitations_fts, rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES ('delete', old.rowid, old.id, old.title, old.organization, old.contact_person, old.purpose, old.location, old.notes, old.category);
            INSERT INTO solicitations_fts(rowid, id, title, organization, contact_person, purpose, location, notes, category)
            VALUES (new.rowid, new.id, new.title, new.organization, new.contact_person, new.purpose, new.location, new.notes, new.category);
        END
    """))
    await raw.commit()


async def init_db() -> None:
    """Create all tables and set up FTS5."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        conn = await session.connection()
        await setup_fts5(session)
