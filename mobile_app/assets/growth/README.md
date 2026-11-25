# WHO weight-for-age table (growth zones)

The growth form colours a weight green / orange / red from its WHO z-score.
It needs `wfa_lms.json` in this folder. Added on 2026-11-25 from WHO's `weianthro.txt`
(WorldHealthOrganization/anthro, `data-raw/growthstandards/`). Without the file the form
would save the weight and show "Growth zone not shown".

How to add it (once, by a team member):
1. Get `weianthro.txt` from WHO's own repository
   https://github.com/WorldHealthOrganization/anthro (folder `data-raw/growthstandards/`).
   It holds the WHO Child Growth Standards weight-for-age LMS values by sex and age in days.
2. Convert it:
   `python3 mobile_app/tool/make_wfa_table.py weianthro.txt mobile_app/assets/growth/wfa_lms.json`
3. Run `flutter test` and commit both the JSON and the tool output message.

Format of `wfa_lms.json`: `{"source": "...", "boy": [[L, M, S], ...], "girl": [[L, M, S], ...]}`,
one row per age in days from 0 to 1826 (5 years).

## Source and checks
- Numbers: WHO Child Growth Standards (2006), weight-for-age LMS by sex and age in days.
  Source file: `weianthro.txt` from https://github.com/WorldHealthOrganization/anthro
  (WHO's official R package; the repository is GPL-3.0, the growth standards are published openly by WHO).
- `test/unit/who_table_test.dart` checks the table against the WHO printed charts:
  birth medians, and the −2 / −3 SD and median weights at birth and 12 months for boys and girls
  (within 0.05 kg, the charts' rounding).
- Zones use the plain LMS z-score. WHO's adjustment beyond ±3 SD changes how far past −3 a child is,
  not which zone, so it is not needed for green / orange / red.
