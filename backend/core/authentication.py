from functools import lru_cache
from uuid import UUID

import jwt
from django.conf import settings
from rest_framework import authentication, exceptions

from apps.users.services import UserService


@lru_cache(maxsize=1)
def get_jwk_client():
    return jwt.PyJWKClient(f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json")


def verify_supabase_token(token: str) -> dict:
    try:
        signing_key = get_jwk_client().get_signing_key_from_jwt(token)
        # Supabase GoTrue may sign access tokens with ES256 (JWKS kty=EC) or RS256.
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256", "RS256"],
            issuer=settings.SUPABASE_ISSUER,
            options={"verify_aud": False},
            leeway=120,
        )
        UUID(payload["sub"])
        return payload
    except KeyError as exc:
        raise exceptions.AuthenticationFailed("Supabase token is missing the subject claim.") from exc
    except ValueError as exc:
        raise exceptions.AuthenticationFailed("Supabase token subject is not a valid UUID.") from exc
    except jwt.InvalidTokenError as exc:
        raise exceptions.AuthenticationFailed("Supabase token verification failed.") from exc


class SupabaseJWTAuthentication(authentication.BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).split()
        if not header:
            return None

        if header[0].decode("utf-8").lower() != self.keyword.lower():
            return None

        if len(header) != 2:
            raise exceptions.AuthenticationFailed("Authorization header must contain a bearer token.")

        token = header[1].decode("utf-8")
        payload = verify_supabase_token(token)
        try:
            user = UserService.sync_from_supabase_claims(payload)
        except ValueError as exc:
            raise exceptions.AuthenticationFailed(str(exc)) from exc
        return user, payload

    def authenticate_header(self, request):
        return self.keyword
