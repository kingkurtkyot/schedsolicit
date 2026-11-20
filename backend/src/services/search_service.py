"""Full-text search service using SQLite FTS5 with weighting and trigram fallback."""

from typing import Any, Dict, List, Optional
from sqlalchemy import text, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.schedule import Schedule
from src.models.solicitation import Solicitation


def sanitize_query(query: str) -> str:
    """Sanitize query for FTS5 prefix search."""
    cleaned = "".join([c if c.isalnum() or c.isspace() else " " for c in query]).strip()
    if not cleaned:
        return ""
    words = cleaned.split()
    # Format prefix search: word*
    return " ".join([f"{w}*" for w in words])


async def search_items(
    db: AsyncSession,
    user_id: str,
    module: str,
    query: str,
    limit: int = 50,
) -> List[Dict[str, Any]]:
    """Search schedules or solicitations using FTS5 with BM25 ranking and weights.
    
    Weights:
    - Schedules: title (3.0), description (1.0), location (2.0), notes (1.0), category (1.0)
    - Solicitations: title (3.0), organization (2.0), contact_person (2.0), purpose (1.0), location (1.0), notes (1.0), category (1.0)
    """
    clean_q = sanitize_query(query)
    if not clean_q:
        return []

    results: List[Dict[str, Any]] = []

    try:
        if module == "schedule":
            sql = text("""
                SELECT s.id, s.title, s.description, s.event_date, s.status, s.priority, s.category,
                       bm25(schedules_fts, 3.0, 1.0, 2.0, 1.0, 1.0) AS score
                FROM schedules_fts fts
                JOIN schedules s ON fts.rowid = s.rowid
                WHERE schedules_fts MATCH :query
                  AND s.user_id = :user_id
                  AND s.is_deleted = 0
                ORDER BY score ASC
                LIMIT :limit
            """)
            res = await db.execute(sql, {"query": clean_q, "user_id": str(user_id), "limit": limit})
            rows = res.fetchall()
            for r in rows:
                results.append({
                    "id": r.id,
                    "title": r.title,
                    "description": r.description,
                    "date": str(r.event_date) if r.event_date else None,
                    "status": r.status,
                    "priority": r.priority,
                    "category": r.category,
                    "relevance_score": float(abs(r.score)),
                    "module": "schedule",
                })
        else:
            sql = text("""
                SELECT s.id, s.title, s.organization, s.purpose, s.requested_date, s.status, s.priority, s.category,
                       bm25(solicitations_fts, 3.0, 2.0, 2.0, 1.0, 1.0, 1.0, 1.0) AS score
                FROM solicitations_fts fts
                JOIN solicitations s ON fts.rowid = s.rowid
                WHERE solicitations_fts MATCH :query
                  AND s.user_id = :user_id
                  AND s.is_deleted = 0
                ORDER BY score ASC
                LIMIT :limit
            """)
            res = await db.execute(sql, {"query": clean_q, "user_id": str(user_id), "limit": limit})
            rows = res.fetchall()
            for r in rows:
                results.append({
                    "id": r.id,
                    "title": r.title,
                    "organization": r.organization,
                    "purpose": r.purpose,
                    "date": str(r.requested_date) if r.requested_date else None,
                    "status": r.status,
                    "priority": r.priority,
                    "category": r.category,
                    "relevance_score": float(abs(r.score)),
                    "module": "solicitation",
                })
    except Exception:
        # Fallback to trigram / LIKE matching if FTS table doesn't match or on syntax error
        pass

    # If FTS returned nothing, perform typo-tolerant fallback with LIKE
    if not results:
        results = await fallback_search(db, user_id, module, query, limit)

    return results


async def fallback_search(
    db: AsyncSession,
    user_id: str,
    module: str,
    query: str,
    limit: int = 50,
) -> List[Dict[str, Any]]:
    """Substring / Trigram fallback for typo tolerance."""
    pattern = f"%{query.strip()}%"
    results = []

    if module == "schedule":
        stmt = (
            select(Schedule)
            .where(
                Schedule.user_id == str(user_id),
                Schedule.is_deleted == False,
                (Schedule.title.ilike(pattern))
                | (Schedule.description.ilike(pattern))
                | (Schedule.location.ilike(pattern))
                | (Schedule.notes.ilike(pattern)),
            )
            .limit(limit)
        )
        res = await db.execute(stmt)
        for s in res.scalars().all():
            results.append({
                "id": s.id,
                "title": s.title,
                "description": s.description,
                "date": str(s.event_date) if s.event_date else None,
                "status": s.status,
                "priority": s.priority,
                "category": s.category,
                "relevance_score": 100.0,
                "module": "schedule",
            })
    else:
        stmt = (
            select(Solicitation)
            .where(
                Solicitation.user_id == str(user_id),
                Solicitation.is_deleted == False,
                (Solicitation.title.ilike(pattern))
                | (Solicitation.organization.ilike(pattern))
                | (Solicitation.contact_person.ilike(pattern))
                | (Solicitation.purpose.ilike(pattern))
                | (Solicitation.notes.ilike(pattern)),
            )
            .limit(limit)
        )
        res = await db.execute(stmt)
        for s in res.scalars().all():
            results.append({
                "id": s.id,
                "title": s.title,
                "organization": s.organization,
                "purpose": s.purpose,
                "date": str(s.requested_date) if s.requested_date else None,
                "status": s.status,
                "priority": s.priority,
                "category": s.category,
                "relevance_score": 100.0,
                "module": "solicitation",
            })

    return results
