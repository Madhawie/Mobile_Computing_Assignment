# Little Bloom – UI designs

Mobile UI designs for a child health monitoring app (birth to 5 years) built around Sri Lanka's Public Health Midwife (PHM) system.

**Live design canvas (view and play through the screens):** https://claude.ai/artifact/NURhC7tr1uniGHhBYBqdmb

The `screens/` folder holds the source of each screen (`.dc.html`) and the canvas layout (`canvas.json`). These files render on the design canvas; open the link above to view them.

## Colour rules
| Use | Colours |
|---|---|
| Boy's data | Blue `#DCEBFA` / `#6FA3D9` / text `#1F4166` |
| Girl's data | Pink `#FBE1EA` / `#E58FAE` / text `#7A2D4B` |
| Parent app | Lavender `#ECE6FA` / `#5E4E99` |
| PHM app | Mint `#DDF3EA` / `#2F7356` |
| MOH app | Butter `#FFF1CC` / `#8A5A12` |
| Background / text / muted | `#F8F7FC` / `#2B2D42` / `#646878` |

Font: Nunito, with Noto Sans Sinhala and Noto Sans Tamil for local languages.

## Screens (27)
**Everyone (5)**
- C1 Splash & language – `Main.dc.html`
- C2 Sign in (OTP) – `Login.dc.html`
- C3 Notifications – `Notifications.dc.html`
- C4 Profile & settings – `Settings.dc.html`
- C5 Help & contacts – `Help.dc.html`

**Parent (8)**
- P1 Home – `ParentHome.dc.html`
- P2 Child record – `ChildProfile.dc.html`
- P3 Growth chart – `Growth.dc.html`
- P4 Vaccination card – `Vaccines.dc.html`
- P5 Visits & clinics – `Visits.dc.html`
- P6 Milestones – `Milestones.dc.html`
- P7 Home log – `HomeLog.dc.html`
- P8 Advice by age – `Advice.dc.html`

**Public Health Midwife (10)**
- M1 Today – `PhmDashboard.dc.html`
- M2 Area register – `PhmRegister.dc.html`
- M3 Register newborn – `PhmNewborn.dc.html`
- M4 Child detail – `PhmChild.dc.html`
- M5 Record home visit – `PhmVisit.dc.html`
- M6 Record growth – `PhmGrowth.dc.html`
- M7 Record vaccination – `PhmVaccine.dc.html`
- M8 Due & overdue – `PhmDue.dc.html`
- M9 At-risk children – `PhmRisk.dc.html`
- M10 Offline sync – `PhmSync.dc.html`

**Supervisor / MOH (4)**
- S1 Area overview – `MohDashboard.dc.html`
- S2 PHMs & workload – `MohStaff.dc.html`
- S3 Reports & export – `MohReports.dc.html`
- S4 Users & settings – `MohAdmin.dc.html`

## Notes
- All names, numbers and dates are sample data. Never commit real patient data or screenshots.
- Vaccine and growth schedules follow FHB / Epidemiology Unit guidance; check the latest circular before release.
