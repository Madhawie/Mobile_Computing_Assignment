#!/usr/bin/env python3
"""Mock Little Bloom sync server (docs/architecture/api.md).

Lets the Flutter app be built and tested before the .NET pull endpoint is
ready, and gives a second, simple implementation of the S1/S2/S3 rules to
compare against. Python standard library only; data lives in memory.

Run (from the repo root):
    python3 experiments/scripts/mock_server.py                 # 0.0.0.0:5000
    python3 experiments/scripts/mock_server.py --port 5050 --no-auth

From the Android emulator the Mac is http://10.0.2.2:<port>.

Endpoints (same JSON as the .NET API):
    GET  /api/health
    POST /api/auth/otp/request   {"phone"}            -> 202 {otpRequestId, expiresInSeconds}
    POST /api/auth/otp/verify    {otpRequestId, code, deviceId}   code 000000
    POST /api/auth/refresh       {refreshToken, deviceId}
    POST /api/sync/push          api.md section 4
    GET  /api/sync/pull?since=&limit=   api.md section 5
Mock only (experiments):
    POST /mock/reset             empty all data
    GET  /mock/stats             counts, conflicts, processed operations

Synthetic data only. Never load real patient data into this server.
"""
import argparse
import json
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import parse_qs, urlparse

ENTITIES = {"mother", "maternalVisit", "child", "growthMeasurement", "vaccination"}
MAX_PUSH_CHANGES = 200
COMMON_FIELDS = {"id", "version", "updatedAt", "deviceId", "deleted"}

# Same made-up staff as the .NET Development seed (backend/README.md).
DEV_USERS = {
    "+94700000001": {"role": "admin", "name": "Test Admin", "areaId": None},
    "+94700000002": {"role": "phm", "name": "Test PHM East", "areaId": "glg-east"},
    "+94700000003": {"role": "phm", "name": "Test PHM West", "areaId": "glg-west"},
    "+94700000004": {"role": "supervisor", "name": "Test Supervisor", "areaId": None},
}
DEV_OTP_CODE = "000000"


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


class Store:
    """All server data. One lock: requests are handled one at a time."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.reset()

    def reset(self) -> None:
        self.change_seq = 0
        # (entity, id) -> {"record": dict, "seq": int}
        self.records: Dict[Tuple[str, str], Dict[str, Any]] = {}
        # (entity, id) -> list of {"version", "changedFields", "updatedAt", "deleted"}
        self.history: Dict[Tuple[str, str], List[Dict[str, Any]]] = {}
        # operationId -> result dict (idempotency, like ProcessedOperations)
        self.processed: Dict[str, Dict[str, Any]] = {}
        self.conflicts: List[Dict[str, Any]] = []
        self.otps: Dict[str, str] = {}  # otpRequestId -> phone
        self.refresh_tokens: Dict[str, str] = {}  # refreshToken -> phone

    # ------------------------------------------------------------- push

    def push(self, body: Dict[str, Any]) -> Dict[str, Any]:
        strategy = body.get("strategy", "S3")
        results = []
        for change in body.get("changes", []):
            op_id = change["operationId"]
            if op_id in self.processed:
                # Retry of a change we already handled: same answer, no copy.
                results.append(dict(self.processed[op_id], status="duplicate"))
                continue
            result = self._apply(change, strategy)
            if result["status"] != "rejected":
                self.processed[op_id] = result
            results.append(result)
        return {"results": results, "serverTime": now_iso(), "cursor": self.change_seq}

    def _apply(self, change: Dict[str, Any], strategy: str) -> Dict[str, Any]:
        op_id, entity, record_id = change["operationId"], change["entity"], change["recordId"]
        base = {"operationId": op_id, "recordId": record_id}
        if entity not in ENTITIES:
            return dict(base, status="rejected", error={"code": "UNKNOWN_ENTITY"})

        key = (entity, record_id)
        current = self.records.get(key)
        server_version = current["record"]["version"] if current else 0
        data = dict(change.get("data") or {})
        is_delete = change.get("op") == "delete"

        if is_delete and not data:
            if current is None:
                return dict(base, status="rejected", error={"code": "NOT_FOUND"})
            data = dict(current["record"])
        if not is_delete and not data:
            return dict(base, status="rejected", error={"code": "INVALID_FIELD", "field": "data"})
        if is_delete:
            data["deleted"] = True
        data["id"] = record_id

        changed = change.get("changedFields") or [k for k in data if k not in COMMON_FIELDS]
        if is_delete:
            changed = ["deleted"]

        # S1 / S2: last upload wins, no version check.
        if strategy in ("S1", "S2") or current is None or change.get("baseVersion", 0) >= server_version:
            new_version = self._write(key, data, changed)
            return dict(base, status="applied", newVersion=new_version)

        return self._resolve_s3(base, key, current["record"], data, changed, change["baseVersion"], is_delete)

    def _resolve_s3(self, base, key, server_rec, data, phone_changed, base_version, is_delete):
        """api.md section 6, rules 2 and 3."""
        later = [h for h in self.history.get(key, []) if h["version"] > base_version]
        server_changed = set()
        for h in later:
            server_changed.update(h["changedFields"])

        merged = dict(server_rec)
        lost: List[Dict[str, Any]] = []

        # Rule 3: delete vs update -> the update wins, record stays.
        if is_delete and server_changed - {"deleted"}:
            merged["deleted"] = False
            lost.append({"field": "deleted", "kept": False, "lost": True, "lostDeviceId": data.get("deviceId")})
            return self._flag(base, key, merged, ["deleted"], lost)
        if not is_delete and server_rec.get("deleted") and "deleted" in server_changed:
            merged.update({f: data[f] for f in phone_changed if f in data})
            merged["deleted"] = False
            lost.append({"field": "deleted", "kept": False, "lost": True,
                         "lostDeviceId": server_rec.get("deviceId")})
            return self._flag(base, key, merged, list(phone_changed) + ["deleted"], lost)

        shared = server_changed.intersection(phone_changed)
        for f in phone_changed:
            if f not in data:
                continue
            if f in shared:
                # Same field changed on both sides: newest updatedAt wins.
                server_time = max(h["updatedAt"] for h in later if f in h["changedFields"])
                phone_newer = data.get("updatedAt", "") > server_time
                kept, lost_value = (data[f], server_rec.get(f)) if phone_newer else (server_rec.get(f), data[f])
                merged[f] = kept
                lost.append({"field": f, "kept": kept, "lost": lost_value,
                             "lostDeviceId": server_rec.get("deviceId") if phone_newer else data.get("deviceId")})
            else:
                merged[f] = data[f]
        merged["updatedAt"] = max(server_rec.get("updatedAt", ""), data.get("updatedAt", ""))
        merged["deviceId"] = data.get("deviceId", server_rec.get("deviceId"))

        if lost:
            return self._flag(base, key, merged, list(phone_changed), lost)
        new_version = self._write(key, merged, list(phone_changed))
        return dict(base, status="conflictMerged", newVersion=new_version, record=self.records[key]["record"])

    def _flag(self, base, key, merged, changed, lost):
        new_version = self._write(key, merged, changed)
        conflict_id = str(uuid.uuid4())
        self.conflicts.append({"id": conflict_id, "entity": key[0], "recordId": key[1],
                               "fields": lost, "status": "open", "createdAt": now_iso()})
        return dict(base, status="conflictFlagged", newVersion=new_version,
                    conflictId=conflict_id, record=self.records[key]["record"])

    def _write(self, key, record, changed) -> int:
        """Saves a record, raises its version, gives it the next change number."""
        current = self.records.get(key)
        new_version = (current["record"]["version"] if current else 0) + 1
        record = dict(record, version=new_version)
        self.change_seq += 1
        self.records[key] = {"record": record, "seq": self.change_seq}
        self.history.setdefault(key, []).append({
            "version": new_version, "changedFields": list(changed),
            "updatedAt": record.get("updatedAt", ""), "deleted": bool(record.get("deleted")),
        })
        return new_version

    # ------------------------------------------------------------- pull

    def pull(self, since: int, limit: int) -> Dict[str, Any]:
        newer = sorted((v["seq"], k, v["record"]) for k, v in self.records.items() if v["seq"] > since)
        page = newer[:limit]
        return {
            "changes": [{"entity": k[0], "record": rec} for _, k, rec in page],
            "cursor": page[-1][0] if page else max(since, 0),
            "hasMore": len(newer) > limit,
        }

    def stats(self) -> Dict[str, Any]:
        per_entity: Dict[str, int] = {}
        for (entity, _), _v in self.records.items():
            per_entity[entity] = per_entity.get(entity, 0) + 1
        return {"records": per_entity, "changeSeq": self.change_seq,
                "processedOperations": len(self.processed), "conflicts": self.conflicts}


STORE = Store()


class Handler(BaseHTTPRequestHandler):
    server_version = "LittleBloomMock/1.0"
    protocol_version = "HTTP/1.1"
    require_auth = True
    delay_ms = 0

    # ---------------------------------------------------------- helpers

    def _send(self, status: int, body: Optional[Dict[str, Any]], started: float) -> None:
        raw = b"" if body is None else json.dumps(body).encode("utf-8")
        self.send_response(status)
        if body is not None:
            content_type = "application/problem+json" if status >= 400 else "application/json"
            self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("X-Server-Time-Ms", str(int((time.perf_counter() - started) * 1000)))
        self.end_headers()
        self.wfile.write(raw)

    def _problem(self, status: int, code: str, title: str, started: float) -> None:
        self._send(status, {"type": "about:blank", "title": title, "status": status, "code": code}, started)

    def _json_body(self) -> Dict[str, Any]:
        length = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(length) or b"{}") if length else {}

    def _authorised(self) -> bool:
        if not self.require_auth:
            return True
        token = (self.headers.get("Authorization") or "").replace("Bearer ", "", 1)
        return token.startswith("mock-")

    def log_message(self, fmt: str, *args: Any) -> None:  # quieter console
        print("[mock] %s %s" % (self.address_string(), fmt % args))

    # ---------------------------------------------------------- routing

    def do_GET(self) -> None:
        started = time.perf_counter()
        if self.delay_ms:
            time.sleep(self.delay_ms / 1000)
        url = urlparse(self.path)
        if url.path == "/api/health":
            return self._send(200, {"status": "ok", "serverTime": now_iso()}, started)
        if url.path == "/mock/stats":
            with STORE.lock:
                return self._send(200, STORE.stats(), started)
        if url.path == "/api/sync/pull":
            if not self._authorised():
                return self._problem(401, "UNAUTHORIZED", "Sign in first", started)
            q = parse_qs(url.query)
            try:
                since = int(q.get("since", ["0"])[0])
                limit = min(int(q.get("limit", ["500"])[0]), 500)
            except ValueError:
                return self._problem(400, "VALIDATION_FAILED", "since and limit must be numbers", started)
            with STORE.lock:
                return self._send(200, STORE.pull(since, limit), started)
        return self._problem(404, "NOT_FOUND", "No such endpoint", started)

    def do_POST(self) -> None:
        started = time.perf_counter()
        if self.delay_ms:
            time.sleep(self.delay_ms / 1000)
        path = urlparse(self.path).path
        try:
            body = self._json_body()
        except (ValueError, UnicodeDecodeError):
            return self._problem(400, "VALIDATION_FAILED", "Body is not valid JSON", started)

        with STORE.lock:
            if path == "/mock/reset":
                STORE.reset()
                return self._send(200, {"status": "reset"}, started)

            if path == "/api/auth/otp/request":
                phone = body.get("phone", "")
                if phone not in DEV_USERS:
                    return self._problem(404, "PHONE_NOT_REGISTERED", "Ask your midwife to add this number", started)
                otp_id = str(uuid.uuid4())
                STORE.otps[otp_id] = phone
                print("[mock] OTP for %s is %s" % (phone, DEV_OTP_CODE))
                return self._send(202, {"otpRequestId": otp_id, "expiresInSeconds": 300}, started)

            if path == "/api/auth/otp/verify":
                phone = STORE.otps.get(body.get("otpRequestId", ""))
                if phone is None or body.get("code") != DEV_OTP_CODE:
                    return self._problem(401, "INVALID_CODE", "Wrong or expired code", started)
                return self._send(200, self._session(phone), started)

            if path == "/api/auth/refresh":
                phone = STORE.refresh_tokens.get(body.get("refreshToken", ""))
                if phone is None:
                    return self._problem(401, "UNAUTHORIZED", "Sign in again", started)
                return self._send(200, self._session(phone), started)

            if path == "/api/sync/push":
                if not self._authorised():
                    return self._problem(401, "UNAUTHORIZED", "Sign in first", started)
                if len(body.get("changes", [])) > MAX_PUSH_CHANGES:
                    return self._problem(413, "BATCH_TOO_LARGE", "At most 200 changes per push", started)
                return self._send(200, STORE.push(body), started)

        return self._problem(404, "NOT_FOUND", "No such endpoint", started)

    @staticmethod
    def _session(phone: str) -> Dict[str, Any]:
        user = DEV_USERS[phone]
        user_id = str(uuid.uuid5(uuid.NAMESPACE_URL, "littlebloom-mock/" + phone))
        refresh = "r-" + str(uuid.uuid4())
        STORE.refresh_tokens[refresh] = phone
        return {
            "accessToken": "mock-" + user_id,
            "expiresIn": 43200,
            "refreshToken": refresh,
            "user": {"id": user_id, "role": user["role"], "name": user["name"],
                     "areaId": user["areaId"], "mohId": "glg", "motherId": None},
        }


def make_server(host: str, port: int, require_auth: bool = True, delay_ms: int = 0) -> ThreadingHTTPServer:
    handler = type("ConfiguredHandler", (Handler,), {"require_auth": require_auth, "delay_ms": delay_ms})
    return ThreadingHTTPServer((host, port), handler)


def main() -> None:
    parser = argparse.ArgumentParser(description="Mock Little Bloom sync server")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--no-auth", action="store_true", help="accept sync calls without a token")
    parser.add_argument("--delay-ms", type=int, default=0, help="extra server delay per request")
    args = parser.parse_args()
    server = make_server(args.host, args.port, not args.no_auth, args.delay_ms)
    print("Mock sync server on http://%s:%d (emulator: http://10.0.2.2:%d)" % (args.host, args.port, args.port))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
