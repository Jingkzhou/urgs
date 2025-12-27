import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from core.config import Settings, get_settings
from schemas.api import PendingApproval


class ApprovalPolicy:
    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()

    def should_interrupt(self, requires_approval: bool) -> bool:
        return requires_approval

    def build_pending(self, action_summary: str, reason: str, expires_in_minutes: int = 30) -> PendingApproval:
        expires_at = datetime.now(tz=timezone.utc) + timedelta(minutes=expires_in_minutes)
        approval_id = f"appr_{uuid.uuid4().hex}"
        return PendingApproval(
            approval_id=approval_id,
            reason=reason,
            action_summary=action_summary,
            expires_at=expires_at,
        )
