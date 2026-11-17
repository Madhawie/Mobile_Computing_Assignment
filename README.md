# Little Bloom – Child Health Monitoring App (Sri Lanka)

Mobile app that digitises the Child Health Development Record (CHDR) for children from birth to 5 years,
for parents, Public Health Midwives (PHM) and MOH supervisors.

| Part | Technology | Folder |
|---|---|---|
| Mobile app | Flutter | `mobile/` |
| Backend API | ASP.NET Core (.NET) | `backend/` |
| Database | MySQL | `database/` |
| Docs | Requirements, UI designs, architecture | `docs/` |

## Folder structure
```
mobile_computing/
├── docs/
│   ├── requirements/          users, requirements, page list
│   ├── ui/                    27 screen designs + colour rules
│   └── architecture/          architecture notes (draft)
├── backend/
│   ├── src/
│   │   ├── LittleBloom.Api/              Controllers/
│   │   ├── LittleBloom.Application/      DTOs/ · Interfaces/ · Services/
│   │   ├── LittleBloom.Domain/           Entities/ · Enums/
│   │   └── LittleBloom.Infrastructure/   Persistence/ · Repositories/ · Sms/ · Export/
│   └── tests/
├── database/
│   └── seed/
└── mobile/
    ├── lib/
    │   ├── app/
    │   ├── core/              constants/ · network/ · storage/ · sync/ · theme/
    │   ├── data/              models/ · repositories/
    │   ├── features/          common/ · parent/ · phm/ · moh/  (one folder per screen)
    │   ├── shared/widgets/
    │   └── l10n/
    ├── assets/                fonts/ · images/
    └── test/unit/
```

Empty folders hold a `.gitkeep` file so git keeps them. Delete it once the folder has real files.

## Getting started
```bash
git clone <repo-url>
cd mobile_computing
```
- **Backend:** create the .NET projects inside `backend/src/` using the folder names above.
- **Mobile:** run `flutter create --project-name little_bloom .` inside `mobile/`.

## Working together
- Work on a branch, for example `feature/children-api`, and merge to `main` through a pull request.
- Commit every day with clear messages, for example `feat(api): add children controller`.
- Never commit real child or parent data, passwords or connection strings.
