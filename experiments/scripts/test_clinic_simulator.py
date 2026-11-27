#!/usr/bin/env python3
"""Tests for clinic_simulator.py and littlebloom_client.py (no server needed).
Run from the repo root:
    python3 -m unittest experiments/scripts/test_clinic_simulator.py -v
Synthetic data only.
"""
import os
import random
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clinic_simulator as sim  # noqa: E402
from littlebloom_client import ApiError, utc_now_iso  # noqa: E402


def growth(record_id: str, weight: float = 7.0, version: int = 3, deleted: bool = False) -> dict:
    return {"id": record_id, "version": version, "updatedAt": "2026-11-27T08:00:00.000Z", "deviceId": "emu-phm-01",
            "deleted": deleted, "childId": "c-1", "measuredOn": "2026-11-20", "weightKg": weight,
            "heightCm": 70.0, "notes": None}


class BuildChangeTests(unittest.TestCase):
    def test_change_edits_one_field_and_keeps_the_base_version(self):
        record = growth("g-1", weight=7.0, version=3)
        change = sim.build_change(record, "growthMeasurement", "weightKg", random.Random(1), 1, "2026-11-27T09:00:00.000Z")

        self.assertEqual(change["baseVersion"], 3)
        self.assertEqual(change["changedFields"], ["weightKg"])
        self.assertEqual(change["recordId"], "g-1")
        self.assertEqual(change["op"], "upsert")
        self.assertNotEqual(change["data"]["weightKg"], 7.0)
        self.assertEqual(change["data"]["deviceId"], sim.DEVICE_ID)
        self.assertEqual(change["data"]["updatedAt"], "2026-11-27T09:00:00.000Z")
        self.assertEqual(record["weightKg"], 7.0)  # the pulled record itself is not changed

    def test_every_change_has_its_own_operation_id(self):
        rng = random.Random(1)
        ids = {sim.build_change(growth("g-1"), "growthMeasurement", "notes", rng, n, "t")["operationId"] for n in range(50)}
        self.assertEqual(len(ids), 50)

    def test_new_values_stay_valid(self):
        rng = random.Random(5)
        for _ in range(200):
            weight = sim.edit_value("weightKg", 7.0, rng, 1)
            self.assertTrue(6.4 <= weight <= 7.6)
        self.assertEqual(sim.edit_value("bpSystolic", 118, rng, 1), 120)
        self.assertEqual(sim.edit_value("gestationWeeks", 42, rng, 1), 20)


class PickRecordsTests(unittest.TestCase):
    def setUp(self):
        self.pulled = [("growthMeasurement", growth(f"g-{i:03d}")) for i in range(20)]
        self.pulled += [("mother", {"id": "m-1", "version": 1, "deleted": False})]
        self.pulled += [("growthMeasurement", growth("g-deleted", deleted=True))]

    def test_same_seed_picks_the_same_records(self):
        a = [r["id"] for r in sim.pick_records(self.pulled, "growthMeasurement", 5, seed=3)]
        b = [r["id"] for r in sim.pick_records(self.pulled, "growthMeasurement", 5, seed=3)]
        self.assertEqual(a, b)

    def test_only_live_records_of_the_entity_are_picked(self):
        picked = sim.pick_records(self.pulled, "growthMeasurement", 20, seed=1)
        self.assertNotIn("g-deleted", [r["id"] for r in picked])
        self.assertNotIn("m-1", [r["id"] for r in picked])

    def test_asking_for_too_many_is_an_error(self):
        with self.assertRaises(ValueError):
            sim.pick_records(self.pulled, "growthMeasurement", 21, seed=1)


class HelperTests(unittest.TestCase):
    def test_batches_respect_the_push_limit(self):
        sizes = [len(b) for b in sim.batches(list(range(450)))]
        self.assertEqual(sizes, [200, 200, 50])

    def test_summary_counts_each_status(self):
        results = [{"status": "applied"}, {"status": "conflictFlagged"}, {"status": "conflictFlagged"}]
        self.assertEqual(sim.summarize(results),
                         {"applied": 1, "duplicate": 0, "conflictMerged": 0, "conflictFlagged": 2, "rejected": 0})

    def test_time_format_matches_the_api(self):
        self.assertRegex(utc_now_iso(), re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"))

    def test_api_error_keeps_the_problem_code(self):
        err = ApiError(409, {"code": "ALREADY_RESOLVED", "title": "x"})
        self.assertEqual(err.code, "ALREADY_RESOLVED")
        self.assertEqual(err.status, 409)


if __name__ == "__main__":
    unittest.main()
