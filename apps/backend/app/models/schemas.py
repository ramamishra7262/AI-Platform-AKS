from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserOut(BaseModel):
    id: str
    email: str
    full_name: str


class ChatMessage(BaseModel):
    role: str  # user | assistant | system
    content: str
    timestamp: Optional[datetime] = None


class ChatRequest(BaseModel):
    session_id: str
    message: str
    document_filter: Optional[List[str]] = None


class ChatResponse(BaseModel):
    session_id: str
    answer: str
    sources: List[dict] = []
    tokens_used: int = 0


class DocumentOut(BaseModel):
    id: str
    filename: str
    status: str
    uploaded_at: datetime
    chunk_count: int = 0


class HealthStatus(BaseModel):
    status: str
    version: str
    environment: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    checks: dict = {}
