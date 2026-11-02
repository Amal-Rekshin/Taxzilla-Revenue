-- Migration 004: ACCOUNTS redesign - add new_jobs_amount and outstanding_jobs_amount, remove constraints on job counts
ALTER TABLE daily_entries 
  ADD COLUMN IF NOT EXISTS new_jobs_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS outstanding_jobs_amount NUMERIC(12,2) DEFAULT 0;

ALTER TABLE entry_audit 
  ADD COLUMN IF NOT EXISTS new_jobs_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS outstanding_jobs_amount NUMERIC(12,2);

-- Allow ongoing_jobs, new_jobs, outstanding_jobs to be nullable
ALTER TABLE daily_entries ALTER COLUMN ongoing_jobs DROP NOT NULL;
ALTER TABLE daily_entries ALTER COLUMN new_jobs DROP NOT NULL;
ALTER TABLE daily_entries ALTER COLUMN outstanding_jobs DROP NOT NULL;

-- Backfill existing ACCOUNTS entries so new_jobs_amount equals amount if amount > 0 and new_jobs_amount = 0
UPDATE daily_entries de
SET new_jobs_amount = de.amount
FROM sections s
WHERE de.section_id = s.id 
  AND s.code = 'ACCOUNTS'
  AND (de.new_jobs_amount = 0 OR de.new_jobs_amount IS NULL)
  AND de.amount > 0;

