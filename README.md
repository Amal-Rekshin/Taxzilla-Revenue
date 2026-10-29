# RevPulse (Daily Revenue Tracker)

A full-stack mobile application and RESTful backend service for daily revenue recording, job count monitoring, and monthly financial reporting.

---

## 1. Tech Stack

- **Mobile App**: Flutter (Android first), Riverpod, Dio, GoRouter, `fl_chart`, `intl` (`en_IN`, `₹`), `flutter_secure_storage`, `path_provider`, `open_filex`.
- **Backend API**: Node.js 20, Express, `pg`, `zod`, `jsonwebtoken`, `bcrypt`, `exceljs`, `helmet`, `cors`, `express-rate-limit`.
- **Database**: PostgreSQL 15 with plain SQL migration runner.
- **Brand Colors**:
  - **Purple**: `#753C8D` (Primary)
  - **Green**: `#85C041` (Secondary)

---

## 2. Business Rules Reference

There are 6 sections: `EXIM`, `CRO`, `GST`, `ACCOUNTS`, `REGISTRATION`, `MARKETING`.

1. **Twice-Daily Entry**: Every day, amounts and jobs are entered for `MORNING` and `EVENING`.
2. **Evening Data Only**: Both entries are stored, but **only the EVENING entry is used in every total, calculation, report, and Excel export**. Morning data is preserved for reference only.
3. **Two Daily Totals** (Evening only):
   - **Total 1 (Core)** = CRO + GST + REGISTRATION + EXIM (`in_core_total = true`).
   - **Total 2 (Grand)** = EXIM + CRO + GST + ACCOUNTS + REGISTRATION + MARKETING (Sum of all 6).
4. **Job Counts**:
   - `EXIM`, `CRO`, `GST`, `REGISTRATION`, `MARKETING`: Each has its own single `jobs_completed` count (`count_type = 'SINGLE'`).
   - `ACCOUNTS`: Does **not** have `jobs_completed`. Instead has 3 counts: `ongoing_jobs`, `new_jobs`, and `outstanding_jobs` (`count_type = 'TRIPLE'`).
5. **No Monthly Reset Job**: Months are separated purely by date filtering (`YYYY-MM`). Each month starts from zero automatically.
6. **Monthly Running Balances**:
   - Sum of section amounts, Total 1, Total 2, jobs completed, and ACCOUNTS `new_jobs`.
   - ACCOUNTS `ongoing_jobs` and `outstanding_jobs` are running balances resolved by the **last day of that month that has an evening entry** (handled in one dedicated function: `calculateAccountsRunningBalances`).
7. **Sunday Handling**:
   - Sundays are non-working / off days.
   - Status is marked as `SUNDAY` with zero values.
   - Sundays do not count toward pending days in the dashboard or history filter.
   - In the Monthly Report table, Sundays are designated with an off-day badge.
   - In the Daily Entry form, a warning banner reminds the user if they are viewing or editing a Sunday.
8. **Weekly Totals Calculation**:
   - The month is divided into natural 7-day calendar weeks (Week 1, Week 2, Week 3, Week 4, Week 5).
   - In both the Flutter Monthly Report and the Excel export (`.xlsx`), each week calculates subtotals for Total 1, Total 2, individual sections, and Accounts counts.
   - In Excel, weekly subtotals are highlighted and compute live using Excel `=SUM(...)` formulas.
9. **Pending Days**: A day with no evening entry displays as "Pending" and counts as 0 in totals (excluding Sundays). Future dates cannot be entered; past dates can be edited.
10. **Audit Trail**: Any modification to existing entries generates an audit record in `entry_audit` capturing user, timestamp, and field-by-field values ($Old \rightarrow New$).
11. **Currency & Timezone**:
   - Timezone: `Asia/Kolkata`.
   - Money: `NUMERIC(12,2)`, formatted with Indian grouping (`₹1,23,456.00`).

---

## 3. Directory Layout

```text
/
├── backend/
│   ├── src/
│   │   ├── controllers/         # Auth, Sections, Entries, Dashboard, Reports
│   │   ├── db/
│   │   │   ├── migrations/      # 001_initial_schema.sql, 002_audit_schema.sql
│   │   │   ├── client.js        # pg connection pool
│   │   │   ├── migrate.js       # Migration runner
│   │   │   └── seed.js          # Seed 6 sections and admin user
│   │   ├── middleware/          # JWT auth, rate limiter, error handler
│   │   ├── routes/              # Express API routers
│   │   ├── services/            # Shared calculationService, excelService, sectionService
│   │   ├── utils/               # Date & timezone helpers, errors
│   │   ├── validators/          # Zod schemas (SINGLE vs TRIPLE validation)
│   │   ├── app.js               # Express application
│   │   └── server.js            # Server entrypoint
│   ├── tests/                   # Jest + Supertest suites
│   ├── package.json
│   └── .env.example
├── app/
│   ├── lib/
│   │   ├── core/                # Config, Dio client, interceptors, storage, theme
│   │   └── features/
│   │       ├── auth/            # Login screen & session provider
│   │       ├── dashboard/       # Dashboard screen, cards, fl_chart line trend
│   │       ├── entry/           # Daily Entry form, dynamic cards, live totals
│   │       ├── history/         # Entries list, day detail, audit history modal
│   │       └── report/          # Monthly report table & Excel download
│   ├── test/                    # Flutter unit & widget tests
│   └── pubspec.yaml
├── docs/
│   └── API.md                   # Complete REST API specification
├── docker-compose.yml           # PostgreSQL 15 configuration
└── README.md
```

---

## 4. Setup & Running Instructions

### Step 1: Database Setup
You can run PostgreSQL via Docker or your local Postgres service:

**Using Docker:**
```bash
docker compose up -d
```

**Using Local PostgreSQL:**
Ensure PostgreSQL is running locally on port `5432` with database `revenue_tracker` and user `revenue_user` (or customize credentials in `backend/.env`).

### Step 2: Backend Setup
```bash
cd backend
cp .env.example .env
npm install
npm run migrate
npm run seed
# Optional: remove all entered data while preserving users and sections:
# npm run clean:entries
```

### Step 3: Run Backend Tests
Run the comprehensive Jest test suite:
```bash
npm test
```
*Expected: 22/22 unit and integration tests pass.*

### Step 4: Start Backend API
```bash
npm run dev
# Server running at http://localhost:3000
```

### Step 5: Launch Flutter Application
```bash
cd ../app
flutter pub get
flutter test
flutter run
```

To configure custom backend IP (e.g. for physical devices):
```bash
flutter run --dart-define=API_URL=http://<YOUR_IP>:3000/api
```

---

## 5. Seed Credentials
- **Username**: `admin`
- **Password**: `AdminPassword@123`
*(Configurable via `ADMIN_USERNAME` and `ADMIN_PASSWORD` in `.env`)*
# Taxzilla-Revenue
