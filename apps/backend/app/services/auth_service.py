"""Simple in-memory user store (swap for Azure Cosmos DB in production)."""
import uuid
from typing import Dict, Optional
from app.core.security import hash_password, verify_password, create_access_token
from app.models.schemas import UserRegister, Token

# In production replace with DB calls
_users: Dict[str, dict] = {}


def register_user(data: UserRegister) -> dict:
    if data.email in _users:
        raise ValueError("User already exists")
    user_id = str(uuid.uuid4())
    _users[data.email] = {
        "id": user_id,
        "email": data.email,
        "full_name": data.full_name,
        "hashed_password": hash_password(data.password),
    }
    return {"id": user_id, "email": data.email, "full_name": data.full_name}


def authenticate_user(email: str, password: str) -> Optional[dict]:
    user = _users.get(email)
    if not user or not verify_password(password, user["hashed_password"]):
        return None
    return user


def create_token(user: dict) -> Token:
    from app.core.config import get_settings
    settings = get_settings()
    token = create_access_token(user["id"], user["email"])
    return Token(access_token=token, token_type="bearer", expires_in=settings.access_token_expire_minutes * 60)
