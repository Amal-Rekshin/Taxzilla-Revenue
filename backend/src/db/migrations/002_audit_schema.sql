CREATE TABLE IF NOT EXISTS entry_audit (
  id BIGSERIAL PRIMARY KEY,
  entry_date DATE NOT NULL,
  section_id INT NOT NULL REFERENCES sections(id),
  slot VARCHAR(10) NOT NULL CHECK (slot IN ('MORNING','EVENING')),
  old_values JSONB,
  new_values JSONB NOT NULL,
  changed_by INT REFERENCES users(id),
  changed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_entry_audit_date_slot ON entry_audit (entry_date, slot);

