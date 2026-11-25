#!/usr/bin/env python3
"""Convert WHO's weianthro.txt (weight-for-age LMS by age in days) into the
compact JSON the app reads (assets/growth/wfa_lms.json).

    python3 mobile_app/tool/make_wfa_table.py weianthro.txt mobile_app/assets/growth/wfa_lms.json

Input: tab-separated with a header row containing sex, age, l, m, s
(sex 1 = boy, 2 = girl; age in days). The script stops with an error if
the columns, the sexes or the day range are not as expected, so a wrong
file can never slip into the app.
"""
import csv
import json
import sys

MAX_DAY = 1826  # 5 years (WHO table ends at day 1826)


def main(src: str, dst: str) -> None:
    tables = {1: {}, 2: {}}
    with open(src, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        cols = {c.strip().lower(): c for c in (reader.fieldnames or [])}
        for need in ("sex", "age", "l", "m", "s"):
            if need not in cols:
                sys.exit("missing column %r; found %s" % (need, reader.fieldnames))
        for row in reader:
            sex, age = int(row[cols["sex"]]), int(float(row[cols["age"]]))
            if sex not in tables or age > MAX_DAY:
                continue
            tables[sex][age] = [float(row[cols[k]]) for k in ("l", "m", "s")]

    out = {"source": "WHO Child Growth Standards, weight-for-age LMS (weianthro.txt, WorldHealthOrganization/anthro)"}
    for sex, name in ((1, "boy"), (2, "girl")):
        rows = tables[sex]
        missing = [d for d in range(MAX_DAY + 1) if d not in rows]
        if missing:
            sys.exit("%s: missing days %s..." % (name, missing[:5]))
        out[name] = [rows[d] for d in range(MAX_DAY + 1)]
        print("%s: %d rows, day 0 median %.4f kg, day %d median %.4f kg"
              % (name, len(out[name]), out[name][0][1], MAX_DAY, out[name][-1][1]))

    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, separators=(",", ":"))
    print("wrote", dst)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
