"""Import all models so they're registered with SQLAlchemy Base."""

from src.models.base import BaseModel
from src.models.user import User
from src.models.schedule import Schedule
from src.models.solicitation import Solicitation
from src.models.custom_field import CustomField
from src.models.audit_log import AuditLog
from src.models.attachment import Attachment
from src.models.share_link import ShareLink
from src.models.viewer_access_log import ViewerAccessLog
from src.models.ml_model import MlModel
from src.models.category import Category
from src.models.sync_state import SyncState

__all__ = [
    "BaseModel",
    "User",
    "Schedule",
    "Solicitation",
    "CustomField",
    "AuditLog",
    "Attachment",
    "ShareLink",
    "ViewerAccessLog",
    "MlModel",
    "Category",
    "SyncState",
]
