# Child health monitoring app (Sri Lanka): users, requirements, pages

_Research date: 17 Nov 2026. Based on public Family Health Bureau (FHB), Epidemiology Unit and peer-reviewed sources (listed at the end). Verify the immunization schedule against the latest Epidemiology Unit circular before building, because the 2025 National Immunization Summit reviewed it._

## 1. How the Sri Lankan system works (context)
- Child health in the field is run by the MOH (Medical Officer of Health) office. The **Public Health Midwife (PHM)** is the front-line worker. Each PHM covers a fixed area of about 3,000–5,000 people and keeps a register of eligible families and children under 5.
- Every child gets a **Child Health Development Record (CHDR)**. It holds growth charts, immunizations, nutrition and milestones. The growth charts are sex-specific: **blue book for boys, pink book for girls**. The app's blue/pink rule follows the official record.
- **Monitoring window: birth to 5 years.** The PHM/MOH team tracks children until age 5. After that, immunization moves to schools under the Public Health Inspector (PHI).
- An existing national system, **eRHMIS**, has been running since 2017. It is built on DHIS2 and is mainly used for aggregate reporting. The app should export data in a format that fits it.

## 2. Monitoring timeline, birth to 5 years
| Item | Schedule |
|---|---|
| PHM postnatal home visits | Day 2–5, Day 6–10, Day 14–21; about Day 42 postpartum visit |
| Weight-for-age | Monthly until 2 years; every 3 months from 2 to 5 years |
| Length-for-age | 4, 9, 18 and 24 months |
| Height-for-age | Every 6 months from 2 to 5 years |
| Child with a nutrition problem | Weight monthly at any age; length every 2 months (under 2); height every 3 months (2–5 years) |
| Where | Child Welfare Clinic (CWC), field weighing post, home visit |
| Immunization (verify latest) | Birth: BCG · 2 months: Pentavalent 1 + OPV 1 + fIPV 1 · 4 months: Pentavalent 2 + OPV 2 + fIPV 2 · 6 months: Pentavalent 3 + OPV 3 · 9 months: MMR 1 · 12 months: Live JE · 18 months: DTP + OPV · 3 years: MMR 2 · 5 years: DT + OPV |
| Vitamin A megadose (2001 programme; verify) | 9 months and 18 months |

## 3. Users (roles)
1. **Parent / guardian** (mostly mothers): views their own children's digital CHDR, gets reminders and logs at home.
2. **Public Health Midwife (PHM)**: registers newborns, records visits, growth and vaccines, and sees due, overdue and at-risk lists. Works in the field, often offline.
3. **Supervisor / MOH officer** (SPHM, PHNS, MOH): views area dashboards and coverage, monitors PHM workload and exports reports.
4. **System admin**: manages users, MOH areas, PHM areas and the vaccine schedule master data.

## 4. Functional requirements
**Parent**
- Sign in with mobile number + OTP and link to children registered by the PHM.
- Digital CHDR per child: profile, growth charts (blue for boys, pink for girls) with WHO z-score bands, vaccine card, milestones.
- Reminders for vaccines, clinic dates and growth checks, by push and SMS.
- Home log (optional): feeding, sleep, illness notes.
- Age-based feeding and development advice.

**PHM**
- Area register: families, children under 5, pregnant mothers (optional later).
- Register a newborn (birth details, birth weight, low birth weight flag).
- Record a home visit, growth measurement and vaccination (batch, date, site).
- Auto-generated task list: due today, due this week, overdue.
- At-risk list: growth faltering, low birth weight, missed vaccines.
- Works offline and syncs when connected.

**Supervisor / MOH**
- Coverage dashboard by PHM area (vaccines, growth monitoring, visits).
- Defaulter and at-risk summaries.
- Monthly or quarterly report export.

**Admin**
- User and role management.
- Schedule configuration (vaccine and visit rules editable without a code change).

## 5. Non-functional requirements
- **Offline-first** for PHMs (rural coverage).
- **Languages:** Sinhala, Tamil, English.
- **Privacy:** role-based access (a parent sees only their own children; a PHM sees only their area); encryption; compliance with Sri Lanka's Personal Data Protection Act No. 9 of 2022.
- Runs on low-end Android phones; fast with large text; accessible colours (blue/pink must not be the only cue, so add labels).
- Audit trail for clinical entries.
- Interoperability: export compatible with DHIS2/eRHMIS.

## 6. Pages (27 total; MVP = 14, marked ★)
**Common (5):** Splash + language ★ · Login / OTP ★ · Notifications ★ · Profile & settings · Help

**Parent (8):** Home / children list ★ · Child profile (digital CHDR) ★ · Growth charts ★ · Vaccination card ★ · Visits & clinic schedule · Milestones · Health notes / home log · Advice by age

**PHM (10):** Dashboard / today's tasks ★ · Area register (families) ★ · Register newborn ★ · Child detail (PHM view) · Record home visit ★ · Record growth ★ · Record vaccination ★ · Due / overdue list · At-risk children · Sync status

**Supervisor / MOH (4):** Area coverage dashboard · PHM list & workload · Reports export · User & area admin

## Sources
- FHB MCH newsletter (CHDR, growth monitoring frequency): medicine.kln.ac.lk (MCH Quarterly, 2011)
- FHB postnatal care presentation (home visit days): content.sph.harvard.edu, Kapila-Jayaratne.pdf
- Yale SPH: Public Health Midwives in Sri Lanka
- UNICEF Sri Lanka: Strengthening the cold chain and access to immunization (2024)
- Epidemiology Unit: EPI and VPD review guidelines 2025; National Immunization Summit 2025; Poliomyelitis fact sheet (fIPV at 2 and 4 months)
- BMC Int Health Hum Rights (2012), Table 1: national immunization schedule
- Exemplars in Global Health: Sri Lanka DHIS2 / eRHMIS
- British Journal of Nutrition (2007): vitamin A supplementation programme
