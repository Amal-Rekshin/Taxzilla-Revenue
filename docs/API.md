# Daily Revenue Tracker - API Specification

Base URL: `/api`

All routes except `POST /api/auth/login` require standard HTTP Bearer token authentication:
```http
Authorization: Bearer <JWT_TOKEN>
```

---

## 1. Unified Error Response Format

All error responses adhere to the standard error envelope:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description of error"
  }
}
```

Common error codes:
- `VALIDATION_ERROR` (HTTP 400): Schema or business rule validation failed.
- `UNAUTHORIZED` (HTTP 401): Missing, invalid, or expired JWT.
- `NOT_FOUND` (HTTP 404): Resource not found.
- `TOO_MANY_REQUESTS` (HTTP 429): Rate limit exceeded on login.
- `INTERNAL_SERVER_ERROR` (HTTP 500): Server error.

---

## 2. Authentication API

### POST `/api/auth/login`
Authenticates a user and issues a signed JWT token.
- **Rate Limit**: 20 requests per 15 minutes per IP.
- **Request Body**:
  ```json
  {
    "username": "admin",
    "password": "AdminPassword@123"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

---

## 3. Sections API

### GET `/api/sections`
Retrieves all 6 active sections ordered by `sort_order`. Used dynamically by the client to construct forms without hardcoding section names.
- **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "code": "EXIM",
      "name": "EXIM",
      "in_core_total": true,
      "count_type": "SINGLE",
      "sort_order": 1
    },
    {
      "id": 2,
      "code": "CRO",
      "name": "CRO",
      "in_core_total": true,
      "count_type": "SINGLE",
      "sort_order": 2
    },
    {
      "id": 3,
      "code": "GST",
      "name": "GST",
      "in_core_total": true,
      "count_type": "SINGLE",
      "sort_order": 3
    },
    {
      "id": 4,
      "code": "ACCOUNTS",
      "name": "ACCOUNTS",
      "in_core_total": false,
      "count_type": "TRIPLE",
      "sort_order": 4
    },
    {
      "id": 5,
      "code": "REGISTRATION",
      "name": "REGISTRATION",
      "in_core_total": true,
      "count_type": "SINGLE",
      "sort_order": 5
    },
    {
      "id": 6,
      "code": "MARKETING",
      "name": "MARKETING",
      "in_core_total": false,
      "count_type": "SINGLE",
      "sort_order": 6
    }
  ]
  ```

---

## 4. Daily Revenue & Job Entries API

### GET `/api/entries/:date`
Retrieves entry details for all 6 sections for both `AFTERNOON` and `EVENING` slots for a specified date (`YYYY-MM-DD`).
- **Path Parameters**:
  - `date`: `YYYY-MM-DD`
- **Success Response (200 OK)**:
  ```json
  {
    "date": "2026-10-28",
    "afternoon": [
      {
        "section_id": 1,
        "code": "EXIM",
        "name": "EXIM",
        "in_core_total": true,
        "count_type": "SINGLE",
        "amount": "1000.00",
        "jobs_completed": 5,
        "is_entered": true
      }
    ],
    "evening": [
      {
        "section_id": 1,
        "code": "EXIM",
        "name": "EXIM",
        "in_core_total": true,
        "count_type": "SINGLE",
        "amount": "2500.00",
        "jobs_completed": 12,
        "is_entered": true
      }
    ]
  }
  ```

### PUT `/api/entries/:date/:slot`
Saves all 6 section entries for the given date and slot in **one atomic database transaction**. Automatically records audit logs in `entry_audit` when modifying existing rows.
- **Path Parameters**:
  - `date`: `YYYY-MM-DD` (Future dates rejected according to `Asia/Kolkata` time).
  - `slot`: `'AFTERNOON'` (or `'MORNING'`) or `'EVENING'`.
- **Request Body**:
  ```json
  {
    "entries": [
      {
        "section_id": 1,
        "amount": 1000.00,
        "jobs_completed": 5
      },
      {
        "section_id": 2,
        "amount": 2000.00,
        "jobs_completed": 3
      },
      {
        "section_id": 3,
        "amount": 500.00,
        "jobs_completed": 2
      },
      {
        "section_id": 4,
        "amount": 300.00,
        "ongoing_jobs": 15,
        "new_jobs": 4,
        "outstanding_jobs": 7
      },
      {
        "section_id": 5,
        "amount": 700.00,
        "jobs_completed": 4
      },
      {
        "section_id": 6,
        "amount": 400.00,
        "jobs_completed": 1
      }
    ]
  }
  ```
- **Validation Rules**:
  - All 6 sections must be present without duplicates.
  - `SINGLE` sections must include `jobs_completed` and must not send triple counts.
  - `TRIPLE` section (`ACCOUNTS`) must include `ongoing_jobs`, `new_jobs`, and `outstanding_jobs`, and must not send `jobs_completed`.
  - `amount >= 0` with up to 2 decimal places.
  - Date cannot be in the future.
- **Success Response (200 OK)**:
  ```json
  {
    "message": "Entries saved successfully",
    "date": "2026-10-28",
    "slot": "EVENING",
    "entries": [...]
  }
  ```

### GET `/api/entries/:date/:slot/history`
Retrieves chronological audit trail records of changes made to that date and slot.
- **Success Response (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "entry_date": "2026-10-28",
      "section_id": 1,
      "section_code": "EXIM",
      "section_name": "EXIM",
      "slot": "EVENING",
      "old_values": { "amount": "1000.00", "jobs_completed": 5 },
      "new_values": { "amount": "2500.00", "jobs_completed": 12 },
      "changed_by": 1,
      "changed_by_username": "admin",
      "changed_at": "2026-10-28T22:30:00.000Z"
    }
  ]
  ```

### GET `/api/entries?month=YYYY-MM&filter=all|pending|edited`
Returns month-wise list of calendar days (newest first) for history listing.
- **Query Parameters**:
  - `month`: `YYYY-MM`
  - `filter`: `'all'` | `'pending'` | `'edited'`
- **Success Response (200 OK)**:
  ```json
  {
    "month": "2026-10",
    "filter": "all",
    "entries": [
      {
        "date": "2026-10-31",
        "morningDone": false,
        "eveningDone": false,
        "total1": 0,
        "total2": 0,
        "isSunday": false,
        "isPending": true,
        "isEdited": false,
        "lastUpdatedBy": null,
        "lastUpdatedAt": null
      },
      {
        "date": "2026-10-25",
        "morningDone": false,
        "eveningDone": false,
        "total1": 0,
        "total2": 0,
        "isSunday": true,
        "isPending": false,
        "isEdited": false,
        "lastUpdatedBy": null,
        "lastUpdatedAt": null
      }
    ]
  }
  ```

---

## 5. Dashboard API

### GET `/api/dashboard?month=YYYY-MM`
Retrieves all dashboard summary cards, trend chart points, today's entry status, and month-over-month comparison metrics (all computed strictly from evening entries).
- **Query Parameters**:
  - `month`: `YYYY-MM`
- **Success Response (200 OK)**:
  ```json
  {
    "month": "2026-10",
    "totals": {
      "total1": 4200.00,
      "total2": 4900.00
    },
    "sectionBreakdown": [
      {
        "code": "EXIM",
        "name": "EXIM",
        "in_core_total": true,
        "count_type": "SINGLE",
        "amount": 1000.00,
        "jobs": 5,
        "percentageShare": 20.41
      }
    ],
    "accounts": {
      "ongoing": 15,
      "newJobs": 4,
      "outstanding": 7
    },
    "dailyTrend": [
      { "date": "2026-10-01", "total1": 0.0, "total2": 0.0, "status": "PENDING" }
    ],
    "today": {
      "date": "2026-10-29",
      "morningDone": true,
      "eveningDone": false
    },
    "pendingDays": 4,
    "previousMonth": {
      "month": "2026-09",
      "total1": 3800.00,
      "total2": 4500.00,
      "diffTotal1": 400.00,
      "diffTotal2": 400.00,
      "percentageChangeTotal1": 10.53,
      "percentageChangeTotal2": 8.89
    }
  }
  ```

---

## 6. Monthly Report & Excel Export API

### GET `/api/reports/monthly?month=YYYY-MM`
Returns calendar day breakdown, status (`COMPLETE`, `PENDING`, or `SUNDAY`), daily section amounts, weekly subtotals (`weeks`), and monthly totals computed using the shared calculation engine.
- **Success Response (200 OK)**:
  ```json
  {
    "month": "2026-10",
    "days": [
      {
        "date": "2026-10-01",
        "status": "PENDING",
        "isSunday": false,
        "amounts": { "EXIM": 0.0, "CRO": 0.0, ... },
        "jobs": { "EXIM": 0, "CRO": 0, ... },
        "accounts": { "ongoing_jobs": 0, "new_jobs": 0, "outstanding_jobs": 0 },
        "total1": 0.0,
        "total2": 0.0
      },
      {
        "date": "2026-10-04",
        "status": "SUNDAY",
        "isSunday": true,
        "amounts": { "EXIM": 0.0, "CRO": 0.0, ... },
        "jobs": { "EXIM": 0, "CRO": 0, ... },
        "accounts": { "ongoing_jobs": 0, "new_jobs": 0, "outstanding_jobs": 0 },
        "total1": 0.0,
        "total2": 0.0
      }
    ],
    "weeks": [
      {
        "weekNumber": 1,
        "label": "Week 1",
        "startDate": "2026-10-01",
        "endDate": "2026-10-04",
        "dayCount": 4,
        "totals": {
          "total1": 0.0,
          "total2": 0.0,
          "amounts": { "EXIM": 0.0, ... },
          "jobs": { "EXIM": 0, ... },
          "accounts": { "ongoing_jobs": 0, "new_jobs": 0, "outstanding_jobs": 0 }
        }
      }
    ],
    "monthTotals": {
      "total1": 4200.00,
      "total2": 4900.00,
      "amounts": { "EXIM": 1000.00, ... },
      "jobs": { "EXIM": 5, ... },
      "accounts": {
        "ongoing_jobs": 15,
        "new_jobs": 4,
        "outstanding_jobs": 7
      }
    }
  }
  ```

### GET `/api/reports/monthly/export?month=YYYY-MM`
Generates and downloads a formatted Microsoft Excel spreadsheet (`.xlsx`).
- **Headers**:
  `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  `Content-Disposition: attachment; filename="Revenue_Report_YYYY-MM.xlsx"`
- **Structure**:
  - **Sheet 1 (`"MMM YYYY"`)**: Columns A through Q with active SUM and row formulas, Indian Rupee formatting, brand purple header styling (`#753C8D`), frozen header/date column, and **Weekly Subtotal Rows** (bold, highlighted in light purple/green) with `=SUM(...)` formulas between week start and end dates.
  - **Sheet 2 (`"Morning (reference)"`)**: Morning raw entries stored for reference only.
