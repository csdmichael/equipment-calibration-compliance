"""Request and response bodies. These also produce the OpenAPI schema."""
from typing import Literal, Optional

from pydantic import BaseModel, Field

ComplianceStatus = Literal['new', 'in-progress', 'complete']
CompliancePriority = Literal['low', 'normal', 'high']


class ComplianceCreate(BaseModel):
    title: str = Field(min_length=1, max_length=400)
    reference: str = Field(default="", max_length=200)
    status: ComplianceStatus = 'new'
    priority: CompliancePriority = 'normal'


class ComplianceUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=400)
    reference: Optional[str] = Field(default=None, max_length=200)
    status: Optional[ComplianceStatus] = None
    priority: Optional[CompliancePriority] = None


class Compliance(ComplianceCreate):
    id: int
