"""CRITICAL TEST SUITE: Verify viewer tokens are strictly FORBIDDEN from ALL owner endpoints.

Every single endpoint under /api/owner/ must reject viewer tokens with HTTP 403 Forbidden.
"""

import pytest
from httpx import AsyncClient


OWNER_ENDPOINTS = [
    # Schedules
    ("GET", "/api/owner/schedules"),
    ("POST", "/api/owner/schedules"),
    ("GET", "/api/owner/schedules/dummy-id"),
    ("PUT", "/api/owner/schedules/dummy-id"),
    ("DELETE", "/api/owner/schedules/dummy-id"),
    ("POST", "/api/owner/schedules/dummy-id/restore"),
    ("POST", "/api/owner/schedules/dummy-id/duplicate"),
    ("POST", "/api/owner/schedules/bulk"),
    ("GET", "/api/owner/schedules/search?q=test"),
    # Solicitations
    ("GET", "/api/owner/solicitations"),
    ("POST", "/api/owner/solicitations"),
    ("GET", "/api/owner/solicitations/dummy-id"),
    ("PUT", "/api/owner/solicitations/dummy-id"),
    ("PUT", "/api/owner/solicitations/dummy-id/given"),
    ("DELETE", "/api/owner/solicitations/dummy-id"),
    ("POST", "/api/owner/solicitations/dummy-id/restore"),
    ("POST", "/api/owner/solicitations/dummy-id/duplicate"),
    ("POST", "/api/owner/solicitations/bulk"),
    ("GET", "/api/owner/solicitations/search?q=test"),
    # Custom Fields & Categories
    ("GET", "/api/owner/custom-fields"),
    ("POST", "/api/owner/custom-fields"),
    ("DELETE", "/api/owner/custom-fields/dummy-id"),
    ("GET", "/api/owner/categories"),
    ("POST", "/api/owner/categories"),
    # Audit Log
    ("GET", "/api/owner/audit-log"),
    ("GET", "/api/owner/audit-log/dummy-id"),
    # Sharing
    ("GET", "/api/owner/share-links"),
    ("POST", "/api/owner/share-links"),
    ("POST", "/api/owner/share-links/dummy-id/revoke"),
    ("POST", "/api/owner/share-links/dummy-id/regenerate"),
    ("GET", "/api/owner/share-links/dummy-id/access-log"),
    # Sync
    ("POST", "/api/owner/sync/push"),
    ("GET", "/api/owner/sync/pull"),
    # Export & ML
    ("POST", "/api/owner/export"),
    ("POST", "/api/owner/ml/schedule/retrain"),
    ("GET", "/api/owner/ml/schedule/suggest"),
    ("GET", "/api/owner/ml/schedule/insights"),
    ("POST", "/api/owner/ml/schedule/reset"),
]


@pytest.mark.asyncio
@pytest.mark.parametrize("method, endpoint", OWNER_ENDPOINTS)
async def test_viewer_token_cannot_access_owner_endpoints(
    client: AsyncClient, viewer_headers: dict, method: str, endpoint: str
):
    """Ensure that requesting any owner route with a viewer token yields 403 Forbidden."""
    if method == "GET":
        resp = await client.get(endpoint, headers=viewer_headers)
    elif method == "POST":
        resp = await client.post(endpoint, json={}, headers=viewer_headers)
    elif method == "PUT":
        resp = await client.put(endpoint, json={}, headers=viewer_headers)
    elif method == "DELETE":
        resp = await client.delete(endpoint, headers=viewer_headers)
    else:
        pytest.fail(f"Unsupported method: {method}")

    assert resp.status_code == 403, f"Expected 403 Forbidden for {method} {endpoint}, got {resp.status_code}"
    assert "Invalid token type" in resp.json()["detail"]
