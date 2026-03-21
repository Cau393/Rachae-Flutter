import json
import time
from functools import lru_cache
from uuid import UUID

import jwt
from django.conf import settings
from rest_framework import authentication, exceptions

from apps.users.services import UserService

# #region agent log
_DEBUG_LOG_PATH = "/Users/cauecasonato/Envs/Rachae_Flutter/.cursor/debug-5c3a4e.log"


def _agent_log(hypothesis_id, location, message, data, run_id="pre-fix"):
    try:
        line = (
            json.dumps(
                {
                    "sessionId": "5c3a4e",
                    "runId": run_id,
                    "hypothesisId": hypothesis_id,
                    "location": location,
                    "message": message,
                    "data": data,
                    "timestamp": int(time.time() * 1000),
                }
            )
            + "\n"
        )
        with open(_DEBUG_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def _debug_groups_post(request):
    return request.method == "POST" and "/groups" in request.path


# #endregion


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
            # #region agent log
            if _debug_groups_post(request):
                _agent_log(
                    "H1",
                    "authentication.py:SupabaseJWTAuthentication.authenticate",
                    "no_authorization_header",
                    {"path": request.path},
                )
            # #endregion
            return None

        if header[0].decode("utf-8").lower() != self.keyword.lower():
            # #region agent log
            if _debug_groups_post(request):
                _agent_log(
                    "H1",
                    "authentication.py:SupabaseJWTAuthentication.authenticate",
                    "authorization_not_bearer",
                    {"path": request.path},
                )
            # #endregion
            return None

        if len(header) != 2:
            raise exceptions.AuthenticationFailed("Authorization header must contain a bearer token.")

        token = header[1].decode("utf-8")
        # #region agent log
        try:
            payload = verify_supabase_token(token)
        except exceptions.AuthenticationFailed as exc:
            if _debug_groups_post(request):
                cause = exc.__cause__
                jwt_err = (
                    type(cause).__name__
                    if cause is not None
                    else type(exc).__name__
                )
                _agent_log(
                    "H2,H3",
                    "authentication.py:SupabaseJWTAuthentication.authenticate",
                    "supabase_jwt_rejected",
                    {
                        "path": request.path,
                        "detail": str(exc)[:200],
                        "jwt_error_type": jwt_err,
                    },
                )
            raise
        # #endregion
        try:
            user = UserService.sync_from_supabase_claims(payload)
        except ValueError as exc:
            # #region agent log
            if _debug_groups_post(request):
                _agent_log(
                    "H3",
                    "authentication.py:SupabaseJWTAuthentication.authenticate",
                    "user_sync_failed",
                    {"path": request.path, "detail": str(exc)[:200]},
                )
            # #endregion
            raise exceptions.AuthenticationFailed(str(exc)) from exc
        return user, payload

    def authenticate_header(self, request):
        return self.keyword
