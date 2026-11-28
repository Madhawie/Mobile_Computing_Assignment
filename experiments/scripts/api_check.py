#!/usr/bin/env python3
"""Checks a running Little Bloom API against the app's sync contract.

It sends exactly the JSON the Flutter app sends (docs/architecture/api.md),
as two devices of the same PHM (device A in the field, device B at the
clinic), and prints PASS / WARN / FAIL / SKIP per check. Run it before
connecting phones, and again after backend changes.

    # .NET API on the partner's Windows PC (Development, dev code 000000)
    python3 experiments/scripts/api_check.py --base http://192.168.1.20:5000
    # the Python mock (server-only checks are skipped)
    python3 experiments/scripts/api_check.py --base http://localhost:5000 --mock

Python standard library only. Creates synthetic records only (random
phone numbers in the +9470 test range); never use real patient data.
Exit code 1 if any check failed.
"""
import argparse
import json
import random
import re
import sys
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple
from urllib import request as urlrequest
from urllib.error import HTTPError, URLError

PHM_PHONE = "+94700000002"  # dev seed: PHM, area glg-east
DEV_CODE = "000000"
AREA = "glg-east"
ZONE = re.compile(r"T.*(Z|[+-]\d\d:?\d\d)$", re.I)

results: List[Tuple[str, str, str]] = []


def check(name: str, ok: Optional[bool], detail: str = "", warn: bool = False) -> None:
    status = "SKIP" if ok is None else "PASS" if ok else ("WARN" if warn else "FAIL")
    results.append((status, name, detail))
    print("%-4s  %s%s" % (status, name, ("  - " + detail) if detail else ""))


def ts(minutes_ago: int = 0) -> str:
    t = datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)
    return t.strftime("%Y-%m-%dT%H:%M:%S.%f") + "Z"


class Api:
    def __init__(self, base: str) -> None:
        self.base = base.rstrip("/")
        self.token: Optional[str] = None

    def call(self, method: str, path: str, body: Any = None, auth: bool = True) -> Tuple[int, Any]:
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urlrequest.Request(self.base + path, data=data, method=method)
        req.add_header("Accept", "application/json")
        if data is not None:
            req.add_header("Content-Type", "application/json; charset=utf-8")
        if auth and self.token:
            req.add_header("Authorization", "Bearer " + self.token)
        try:
            with urlrequest.urlopen(req, timeout=15) as res:
                text = res.read().decode("utf-8")
                return res.status, (json.loads(text) if text else None)
        except HTTPError as e:
            text = e.read().decode("utf-8", "replace")
            try:
                return e.code, json.loads(text)
            except ValueError:
                return e.code, {"code": "HTTP_%d" % e.code}


class Device:
    """One phone: its own deviceId and tokens, like the app."""

    def __init__(self, base: str, name: str) -> None:
        self.api = Api(base)
        self.device_id = "check-%s-%s" % (name, uuid.uuid4().hex[:6])
        self.refresh_token: Optional[str] = None
        self.user: Dict[str, Any] = {}

    def sign_in(self, phone: str) -> bool:
        s, otp = self.api.call("POST", "/api/auth/otp/request", {"phone": phone}, auth=False)
        if s != 202:
            return False
        s, session = self.api.call("POST", "/api/auth/otp/verify", {
            "otpRequestId": otp["otpRequestId"], "code": DEV_CODE, "deviceId": self.device_id}, auth=False)
        if s != 200:
            return False
        self._take(session)
        return True

    def _take(self, session: Dict[str, Any]) -> None:
        self.api.token = session["accessToken"]
        self.refresh_token = session["refreshToken"]
        self.user = session["user"]

    def push(self, strategy: str, changes: List[Dict[str, Any]]) -> Tuple[int, Any]:
        return self.api.call("POST", "/api/sync/push", {
            "deviceId": self.device_id, "strategy": strategy, "batchId": str(uuid.uuid4()), "changes": changes})

    def push_one(self, strategy: str, change: Dict[str, Any]) -> Dict[str, Any]:
        s, body = self.push(strategy, [change])
        if s != 200:
            return {"status": "HTTP_%d" % s, "error": body}
        return body["results"][0]

    def pull(self, since: int = 0, limit: int = 500) -> Tuple[int, Any]:
        return self.api.call("GET", "/api/sync/pull?since=%d&limit=%d" % (since, limit))


def mother(record_id: str, device: Device, version: int, minutes_ago: int = 0, **fields: Any) -> Dict[str, Any]:
    m = {
        "id": record_id, "version": version, "updatedAt": ts(minutes_ago), "deviceId": device.device_id,
        "deleted": False, "fullName": "Check Mother", "phone": "+9470%07d" % random.randint(0, 9999999),
        "age": 27, "address": "Field Road", "areaId": AREA, "isPregnant": False,
        "gestationWeeks": None, "dueDate": None,
    }
    m.update(fields)
    return m


def change(entity: str, data: Dict[str, Any], base: int, fields: List[str], op: str = "upsert",
           operation_id: Optional[str] = None) -> Dict[str, Any]:
    return {"operationId": operation_id or str(uuid.uuid4()), "entity": entity, "op": op,
            "recordId": data["id"], "baseVersion": base, "changedFields": fields, "data": data}


def find(pulled: Any, record_id: str) -> Optional[Dict[str, Any]]:
    for c in (pulled or {}).get("changes", []):
        if c["record"]["id"] == record_id:
            return c["record"]
    return None


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--base", default="http://localhost:5000")
    p.add_argument("--mock", action="store_true", help="skip checks only the .NET API supports")
    args = p.parse_args()
    server_only = None if args.mock else True

    a, b = Device(args.base, "field"), Device(args.base, "clinic")
    try:
        s, _ = a.api.call("GET", "/api/health", auth=False)
    except URLError as e:
        print("Cannot reach %s: %s" % (args.base, e.reason))
        print("Is the API running with --urls http://0.0.0.0:5000, and is port 5000 open in the firewall?")
        return 1
    check("health answers 200", s == 200)

    check("sign in: PHM by SMS code, two devices",
          a.sign_in(PHM_PHONE) and b.sign_in(PHM_PHONE), "role=%s area=%s" % (a.user.get("role"), a.user.get("areaId")))
    check("sign in: token says role phm and area " + AREA, a.user.get("role") == "phm" and a.user.get("areaId") == AREA)

    anon = Api(args.base)
    s, body = anon.call("GET", "/api/sync/pull?since=0")
    check("sync without a token: 401 UNAUTHORIZED", s == 401 and body.get("code") == "UNAUTHORIZED", "got %s" % s)

    # ---- push, idempotency
    m_id = str(uuid.uuid4())
    m1 = mother(m_id, a, 1, minutes_ago=10)
    first = change("mother", m1, 0, [])
    r = a.push_one("S3", first)
    check("S3 new record: applied, version 1", r.get("status") == "applied" and r.get("newVersion") == 1, str(r))
    r = a.push_one("S3", first)
    check("same operationId again: duplicate, same version", r.get("status") == "duplicate" and r.get("newVersion") == 1, str(r))

    # ---- pull and time format
    s, pulled = b.pull()
    rec = find(pulled, m_id)
    check("pull from 0: B gets A's record with version 1", s == 200 and rec is not None and rec.get("version") == 1)
    stamp = (rec or {}).get("updatedAt", "")
    check("record times carry a zone (Z)", bool(ZONE.search(stamp)), "updatedAt=%r; the app reads a time without a zone as UTC" % stamp, warn=True)

    # ---- S3 same field on both devices → flagged, newest kept
    r = b.push_one("S3", change("mother", {**rec, "version": 2, "updatedAt": ts(5), "deviceId": b.device_id,
                                           "address": "Clinic Road"}, 1, ["address"]))
    check("S3: B edits address from v1: applied v2", r.get("status") == "applied" and r.get("newVersion") == 2, str(r))
    r = a.push_one("S3", change("mother", {**m1, "version": 2, "updatedAt": ts(1), "address": "Field Road 2"}, 1, ["address"]))
    conflict_id = r.get("conflictId")
    check("S3: A edits address from v1 too: conflictFlagged with conflictId", r.get("status") == "conflictFlagged" and bool(conflict_id), str(r)[:160])
    check("S3: newest edit (A, later updatedAt) kept", (r.get("record") or {}).get("address") == "Field Road 2", str((r.get("record") or {}).get("address")))
    v_after_flag = r.get("newVersion") or 0

    # ---- S3 different fields → merged
    r = b.push_one("S3", change("mother", {**rec, "version": 3, "updatedAt": ts(0), "deviceId": b.device_id,
                                           "address": "Clinic Road", "age": 28}, 2, ["age"]))
    merged = r.get("record") or {}
    check("S3: B edits age from v2 (address changed since): conflictMerged",
          r.get("status") == "conflictMerged" and merged.get("age") == 28 and merged.get("address") == "Field Road 2", str(r)[:160])

    # ---- conflict review
    s, open_list = a.api.call("GET", "/api/conflicts?status=open")
    if s == 404 and args.mock:
        check("conflict list has the flagged conflict", None, "mock has no /api/conflicts")
        check("resolve keep=previous writes the lost value back", None)
    else:
        mine = [c for c in (open_list or []) if c.get("id") == conflict_id]
        fields = mine[0]["fields"] if mine else []
        check("conflict list has the flagged conflict with both values",
              s == 200 and bool(mine) and fields and fields[0].get("field") == "address"
              and fields[0].get("lost") == "Clinic Road", str(fields)[:160])
        s, res = a.api.call("POST", "/api/conflicts/%s/resolve" % conflict_id, {"keep": "previous"})
        check("resolve keep=previous writes the lost value back as a new version",
              s == 200 and (res or {}).get("record", {}).get("address") == "Clinic Road"
              and (res or {}).get("version", 0) > v_after_flag, str(res)[:160])

    # ---- S2: last upload wins, no conflict (the lost update E5 measures)
    m2_id = str(uuid.uuid4())
    m2 = mother(m2_id, a, 1, minutes_ago=10)
    a.push_one("S2", change("mother", m2, 0, []))
    b.push_one("S2", change("mother", {**m2, "version": 2, "deviceId": b.device_id, "address": "Clinic Road"}, 1, ["address"]))
    r = a.push_one("S2", change("mother", {**m2, "version": 2, "address": "Field Road 3"}, 1, ["address"]))
    check("S2: same field edited on both: applied, no conflict (B's edit silently lost)", r.get("status") == "applied", str(r))

    s, page = b.pull(0, 1)  # several records exist by now
    check("pull limit=1: one change and hasMore true", s == 200 and page.get("hasMore") is True and len(page.get("changes", [])) == 1)

    # ---- tombstone
    s, before = b.pull()
    cursor = (before or {}).get("cursor", 0)
    r = a.push_one("S3", change("mother", {**m2, "version": 3, "address": "Field Road 3", "deleted": True},
                                r.get("newVersion", 3), [], op="delete"))
    s, after = b.pull(cursor)
    tomb = find(after, m2_id)
    check("delete: B's next pull gets a tombstone (deleted: true)", tomb is not None and tomb.get("deleted") is True, str(tomb)[:120])

    # ---- rejections (per change, the batch still answers 200)
    child = {"id": str(uuid.uuid4()), "version": 1, "updatedAt": ts(), "deviceId": a.device_id, "deleted": False,
             "motherId": str(uuid.uuid4()), "name": "Check Baby", "sex": "girl", "dateOfBirth": "2026-05-01",
             "birthWeightKg": 3.1, "bornAt": None, "chdrNumber": None}
    r = a.push_one("S3", change("child", child, 0, []))
    check("child of an unknown mother: rejected PARENT_NOT_FOUND",
          (r.get("error") or {}).get("code") == "PARENT_NOT_FOUND" if server_only else None, str(r)[:120])
    r = a.push_one("S3", change("mother", mother(str(uuid.uuid4()), a, 1, areaId="glg-west"), 0, []))
    check("mother in another PHM's area: rejected OUT_OF_AREA",
          (r.get("error") or {}).get("code") == "OUT_OF_AREA" if server_only else None, str(r)[:120])
    many = [change("mother", mother(str(uuid.uuid4()), a, 1), 0, []) for _ in range(201)]
    s, body = a.push("S3", many)
    check("201 changes in one push: 413 BATCH_TOO_LARGE", s == 413 and (body or {}).get("code") == "BATCH_TOO_LARGE", "got %s" % s)

    # ---- refresh token rotation
    old = a.refresh_token
    s, session = a.api.call("POST", "/api/auth/refresh", {"refreshToken": old, "deviceId": a.device_id}, auth=False)
    check("refresh: new tokens", s == 200 and session.get("refreshToken") not in (None, old))
    s, _ = a.api.call("POST", "/api/auth/refresh", {"refreshToken": old, "deviceId": a.device_id}, auth=False)
    check("refresh token used twice: 401 (rotation)", s == 401, "got %s" % s)

    failed = sum(1 for r in results if r[0] == "FAIL")
    warned = sum(1 for r in results if r[0] == "WARN")
    print("\n%d checks: %d failed, %d warnings" % (len(results), failed, warned))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
