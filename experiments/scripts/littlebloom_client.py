#!/usr/bin/env python3
"""Small HTTP client for the Little Bloom API (docs/architecture/api.md).

Used by server_admin.py and clinic_simulator.py. Python standard library only,
so it runs on any PC without pip. Works against the .NET API and the mock server.

Synthetic data only. Never use real patient data with these scripts.
"""
import json
import time
from typing import Any, Dict, List, Optional, Tuple
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

DEV_OTP_CODE = "000000"  # accepted only by a Development server
ADMIN_PHONE = "+94700000001"
SUPERVISOR_PHONE = "+94700000004"


class ApiError(Exception):
    """An HTTP error from the API, with the ProblemDetails "code" when there is one."""

    def __init__(self, status: int, body: Any):
        self.status = status
        self.body = body
        self.code = body.get("code") if isinstance(body, dict) else None
        super().__init__(f"HTTP {status} {self.code or ''} {body}")


class Client:
    def __init__(self, base_url: str, network_profile: Optional[str] = None,
                 device_id: Optional[str] = None, strategy: Optional[str] = None, timeout: float = 120):
        self.base_url = base_url.rstrip("/")
        self.network_profile = network_profile
        self.device_id = device_id
        self.strategy = strategy
        self.timeout = timeout
        self.token: Optional[str] = None
        self.user: Optional[Dict[str, Any]] = None
        self.last_server_ms: Optional[int] = None

    # ------------------------------------------------------------------ HTTP

    def request(self, method: str, path: str, body: Any = None,
                query: Optional[Dict[str, Any]] = None, raw: bool = False) -> Any:
        url = self.base_url + path
        if query:
            url += "?" + urlencode({k: v for k, v in query.items() if v is not None})

        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = Request(url, data=data, method=method)
        req.add_header("Accept", "application/json")
        if data is not None:
            req.add_header("Content-Type", "application/json; charset=utf-8")
        if self.token:
            req.add_header("Authorization", "Bearer " + self.token)
        # Measurement headers (api.md section 8), so server logs match this client's runs.
        if self.network_profile:
            req.add_header("X-Network-Profile", self.network_profile)
        if self.strategy:
            req.add_header("X-Sync-Strategy", self.strategy)
        if self.device_id:
            req.add_header("X-Device-Id", self.device_id)

        try:
            with urlopen(req, timeout=self.timeout) as resp:
                server_ms = resp.headers.get("X-Server-Time-Ms")
                self.last_server_ms = int(server_ms) if server_ms and server_ms.isdigit() else None
                payload = resp.read()
        except HTTPError as err:
            text = err.read().decode("utf-8", errors="replace")
            try:
                raise ApiError(err.code, json.loads(text)) from None
            except json.JSONDecodeError:
                raise ApiError(err.code, text) from None

        if raw:
            return payload
        return json.loads(payload) if payload else None

    # ------------------------------------------------------------------ auth

    def sign_in(self, phone: str, code: str = DEV_OTP_CODE, device_id: str = "script") -> Dict[str, Any]:
        """OTP sign-in (api.md section 9). On a Development server the code 000000 always works."""
        otp = self.request("POST", "/api/auth/otp/request", {"phone": phone})
        auth = self.request("POST", "/api/auth/otp/verify",
                            {"otpRequestId": otp["otpRequestId"], "code": code, "deviceId": device_id})
        self.token = auth["accessToken"]
        self.user = auth["user"]
        return self.user

    # ------------------------------------------------------------------ sync

    def pull_all(self, since: int = 0, limit: int = 500) -> Tuple[List[Tuple[str, Dict[str, Any]]], int]:
        """Pulls every page after `since`. Returns ([(entity, record), ...], cursor)."""
        changes: List[Tuple[str, Dict[str, Any]]] = []
        cursor = since
        while True:
            page = self.request("GET", "/api/sync/pull", query={"since": cursor, "limit": limit})
            changes.extend((c["entity"], c["record"]) for c in page["changes"])
            cursor = page["cursor"]
            if not page["hasMore"]:
                return changes, cursor

    def push(self, device_id: str, strategy: str, changes: List[Dict[str, Any]]) -> Dict[str, Any]:
        return self.request("POST", "/api/sync/push",
                            {"deviceId": device_id, "strategy": strategy, "changes": changes})


def utc_now_iso() -> str:
    """Current UTC time in the API's format, e.g. 2026-11-27T10:00:00.000Z."""
    now = time.time()
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(now)) + f".{int(now % 1 * 1000):03d}Z"
