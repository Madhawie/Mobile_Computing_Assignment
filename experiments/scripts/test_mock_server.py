#!/usr/bin/env python3
"""Tests for mock_server.py. Run from the repo root:
    python3 -m unittest experiments/scripts/test_mock_server.py -v
Synthetic data only.
"""
import json
import os
import sys
import threading
import unittest
import uuid
from urllib.error import HTTPError
from urllib.request import Request, urlopen

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mock_server  # noqa: E402


def op() -> str:
    return str(uuid.uuid4())


def mother(record_id: str, name: str = "Test Mother", weeks: int = 20, at: str = "2026-11-23T10:00:00.000Z",
           device: str = "phone-a") -> dict:
    return {"id": record_id, "version": 1, "updatedAt": at, "deviceId": device, "deleted": False,
            "fullName": name, "phone": "+94700000099", "age": 25, "address": "Test Road",
            "areaId": "glg-east", "isPregnant": True, "gestationWeeks": weeks, "dueDate": None}


def change(record: dict, base: int, fields=None, op_id=None, kind="upsert") -> dict:
    return {"operationId": op_id or op(), "entity": "mother", "op": kind, "recordId": record["id"],
            "baseVersion": base, "changedFields": fields, "data": record}


class MockServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = mock_server.make_server("127.0.0.1", 0, require_auth=True)
        cls.base = "http://127.0.0.1:%d" % cls.server.server_address[1]
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def setUp(self):
        self.call("POST", "/mock/reset", {})
        otp = self.call("POST", "/api/auth/otp/request", {"phone": "+94700000002"})[1]
        session = self.call("POST", "/api/auth/otp/verify",
                            {"otpRequestId": otp["otpRequestId"], "code": "000000", "deviceId": "test"})[1]
        self.token = session["accessToken"]

    def call(self, method, path, body=None, token=None):
        data = None if body is None else json.dumps(body).encode()
        req = Request(self.base + path, data=data, method=method, headers={"Content-Type": "application/json"})
        if token:
            req.add_header("Authorization", "Bearer " + token)
        try:
            with urlopen(req) as res:
                return res.status, json.loads(res.read() or b"null"), dict(res.headers)
        except HTTPError as e:
            return e.code, json.loads(e.read() or b"null"), dict(e.headers)

    def push(self, changes, strategy="S3"):
        status, body, _ = self.call("POST", "/api/sync/push",
                                    {"deviceId": "phone-a", "strategy": strategy, "batchId": op(),
                                     "changes": changes}, self.token)
        self.assertEqual(status, 200, body)
        return body["results"]

    def pull(self, since=0, limit=500):
        return self.call("GET", "/api/sync/pull?since=%d&limit=%d" % (since, limit), token=self.token)[1]

    # ------------------------------------------------------------ tests

    def test_sync_needs_a_token(self):
        status, body, _ = self.call("GET", "/api/sync/pull?since=0")
        self.assertEqual((status, body["code"]), (401, "UNAUTHORIZED"))

    def test_unknown_phone_is_404(self):
        status, body, _ = self.call("POST", "/api/auth/otp/request", {"phone": "+94711111111"})
        self.assertEqual((status, body["code"]), (404, "PHONE_NOT_REGISTERED"))

    def test_server_time_header(self):
        headers = self.call("GET", "/api/health")[2]
        self.assertIn("X-Server-Time-Ms", headers)

    def test_retry_returns_duplicate_not_a_copy(self):
        c = change(mother("m1"), 0)
        self.assertEqual(self.push([c])[0]["status"], "applied")
        again = self.push([c])[0]
        self.assertEqual(again["status"], "duplicate")
        self.assertEqual(again["newVersion"], 1)
        self.assertEqual(len(self.pull()["changes"]), 1)

    def test_batch_too_large(self):
        changes = [change(mother("m%d" % i), 0) for i in range(201)]
        status, body, _ = self.call("POST", "/api/sync/push",
                                    {"deviceId": "x", "strategy": "S3", "changes": changes}, self.token)
        self.assertEqual((status, body["code"]), (413, "BATCH_TOO_LARGE"))

    def test_unknown_entity_is_rejected_and_not_remembered(self):
        c = change(mother("m1"), 0)
        c["entity"] = "pet"
        self.assertEqual(self.push([c])[0]["error"]["code"], "UNKNOWN_ENTITY")
        self.assertEqual(self.push([c])[0]["status"], "rejected")  # not "duplicate"

    def test_s3_same_base_is_applied(self):
        self.push([change(mother("m1"), 0)])
        r = self.push([change(mother("m1", weeks=21), 1, ["gestationWeeks"])])[0]
        self.assertEqual((r["status"], r["newVersion"]), ("applied", 2))

    def test_s3_different_fields_are_merged(self):
        self.push([change(mother("m1"), 0)])
        self.push([change(mother("m1", weeks=22, device="clinic"), 1, ["gestationWeeks"])])  # clinic edit
        r = self.push([change(mother("m1", name="New Name"), 1, ["fullName"])])[0]           # phone edit, old base
        self.assertEqual(r["status"], "conflictMerged")
        self.assertEqual((r["record"]["fullName"], r["record"]["gestationWeeks"]), ("New Name", 22))

    def test_s3_same_field_newest_wins_and_is_flagged(self):
        self.push([change(mother("m1"), 0)])
        self.push([change(mother("m1", weeks=22, at="2026-11-23T11:00:00.000Z", device="clinic"),
                          1, ["gestationWeeks"])])
        r = self.push([change(mother("m1", weeks=24, at="2026-11-23T12:00:00.000Z"), 1, ["gestationWeeks"])])[0]
        self.assertEqual(r["status"], "conflictFlagged")
        self.assertEqual(r["record"]["gestationWeeks"], 24)  # newer phone edit kept
        conflict = self.call("GET", "/mock/stats")[1]["conflicts"][0]
        self.assertEqual(conflict["fields"][0]["lost"], 22)  # older value not lost

    def test_s3_delete_vs_update_keeps_the_record(self):
        self.push([change(mother("m1"), 0)])
        self.push([change(mother("m1", weeks=23, device="clinic"), 1, ["gestationWeeks"])])
        r = self.push([change(mother("m1"), 1, kind="delete")])[0]
        self.assertEqual(r["status"], "conflictFlagged")
        self.assertFalse(r["record"]["deleted"])

    def test_s2_last_upload_wins_and_loses_the_other_edit(self):
        self.push([change(mother("m1"), 0)], "S2")
        self.push([change(mother("m1", weeks=22, device="clinic"), 1, ["gestationWeeks"])], "S2")
        r = self.push([change(mother("m1", name="New Name", weeks=20), 1, ["fullName"])], "S2")[0]
        self.assertEqual(r["status"], "applied")
        self.assertEqual(self.pull()["changes"][0]["record"]["gestationWeeks"], 20)  # clinic edit lost

    def test_pull_pages_with_cursor_and_returns_tombstones(self):
        self.push([change(mother("m%d" % i), 0) for i in range(5)])
        self.push([change(mother("m0"), 1, kind="delete")])
        first = self.pull(0, 3)
        self.assertEqual((len(first["changes"]), first["hasMore"]), (3, True))
        rest = self.pull(first["cursor"], 3)
        self.assertFalse(rest["hasMore"])
        ids = [c["record"]["id"] for c in first["changes"] + rest["changes"]]
        self.assertEqual(sorted(ids), ["m0", "m1", "m2", "m3", "m4"])
        tomb = [c for c in rest["changes"] if c["record"]["id"] == "m0"][0]["record"]
        self.assertTrue(tomb["deleted"])
        self.assertEqual(self.pull(rest["cursor"])["changes"], [])


if __name__ == "__main__":
    unittest.main()
