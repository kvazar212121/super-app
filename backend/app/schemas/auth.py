from typing import Optional

from pydantic import BaseModel, Field
from app.schemas.user import UserOut


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    surname: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=9, max_length=20)
    password: str = Field(..., min_length=4, max_length=100)
    verification_token: str = Field(..., min_length=10)


class LoginRequest(BaseModel):
    phone: str
    password: str


class SendOtpRequest(BaseModel):
    phone: str = Field(..., min_length=9, max_length=20)
    purpose: str = Field(default="auth", pattern="^(auth|login|register)$")


class VerifyOtpRequest(BaseModel):
    phone: str = Field(..., min_length=9, max_length=20)
    code: str = Field(..., min_length=4, max_length=8)


class SendOtpResponse(BaseModel):
    message: str
    phone: str
    expires_in: int
    purpose: str
    dev_code: Optional[str] = None


class VerifyOtpResponse(BaseModel):
    verified: bool = True
    phone: str
    user_exists: bool
    verification_token: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    user: Optional[UserOut] = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut


class RefreshRequest(BaseModel):
    refresh_token: str
