CREATE TABLE IF NOT EXISTS sections (
  id SERIAL PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(50) NOT NULL,
  in_core_total BOOLEAN NOT NULL DEFAULT FALSE,
  count_type VARCHAR(10) NOT NULL DEFAULT 'SINGLE',
  sort_order INT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS daily_entries (
  id BIGSERIAL PRIMARY KEY,
  entry_date DATE NOT NULL,
  section_id INT NOT NULL REFERENCES sections(id),
  slot VARCHAR(10) NOT NULL CHECK (slot IN ('MORNING','EVENING')),
  amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
  jobs_completed INT CHECK (jobs_completed >= 0),
  ongoing_jobs INT CHECK (ongoing_jobs >= 0),
  new_jobs INT CHECK (new_jobs >= 0),
  outstanding_jobs INT CHECK (outstanding_jobs >= 0),
  updated_by INT REFERENCES users(id),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (entry_date, section_id, slot)
);

CREATE INDEX IF NOT EXISTS idx_entries_date_slot ON daily_entries (entry_date, slot);

