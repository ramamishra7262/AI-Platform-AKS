from fastapi import APIRouter, HTTPException, status
from app.models.schemas import UserRegister, UserLogin, Token, UserOut
from app.services.auth_service import register_user, authenticate_user, create_token

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=UserOut, status_code=201)
def register(data: UserRegister):
    try:
        return register_user(data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=Token)
def login(data: UserLogin):
    user = authenticate_user(data.email, data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return create_token(user)
