from dataclasses import dataclass
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
import httpx
from app.core.config import settings

bearer_scheme = HTTPBearer(auto_error=False)


@dataclass
class AuthenticatedUser:
    user_id: str
    email: str


def verify_supabase_token(token: str) -> AuthenticatedUser:
    """
    Verifies a Supabase access token using either local HMAC-SHA256 JWT secret
    verification or by querying the Supabase Auth `/auth/v1/user` endpoint.
    Never trusts client-supplied user IDs outside the signed JWT.
    """
    try:
        jwt.get_unverified_header(token)
    except jwt.InvalidTokenError:
        # Not even a structurally valid JWT: reject without calling Supabase.
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )

    if settings.SUPABASE_JWT_SECRET:
        try:
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_aud": False},
            )
            user_id = payload.get("sub")
            email = payload.get("email", "")
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication token: missing subject claim.",
                )
            return AuthenticatedUser(user_id=str(user_id), email=str(email))
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Your session has expired. Please sign in again.",
            )
        except jwt.InvalidTokenError:
            if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication token.",
                )

    if settings.SUPABASE_URL and settings.SUPABASE_ANON_KEY:
        try:
            resp = httpx.get(
                f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/user",
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": settings.SUPABASE_ANON_KEY,
                },
                timeout=8.0,
            )
            if resp.status_code == 200:
                data = resp.json()
                return AuthenticatedUser(user_id=data["id"], email=data.get("email", ""))
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service is temporarily unreachable.",
            )

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired authentication token.",
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> AuthenticatedUser:
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided.",
        )
    return verify_supabase_token(credentials.credentials)