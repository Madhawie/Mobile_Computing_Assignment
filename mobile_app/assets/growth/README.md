# WHO weight-for-age table (growth zones)

The growth form colours a weight green / orange / red from its WHO z-score.
It needs `wfa_lms.json` in this folder. **Not added yet**: until it is, the form
saves the weight and shows "Growth zone not shown".

How to add it (once, by a team member):
1. Get `weianthro.txt` from WHO's own repository
   https://github.com/WorldHealthOrganization/anthro (folder `data-raw/growthstandards/`).
   It holds the WHO Child Growth Standards weight-for-age LMS values by sex and age in days.
2. Convert it:
   `python3 mobile_app/tool/make_wfa_table.py weianthro.txt mobile_app/assets/growth/wfa_lms.json`
3. Run `flutter test` and commit both the JSON and the tool output message.

Format of `wfa_lms.json`: `{"source": "...", "boy": [[L, M, S], ...], "girl": [[L, M, S], ...]}`,
one row per age in days from 0 to 1856 (5 years).
