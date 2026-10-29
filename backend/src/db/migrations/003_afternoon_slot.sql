-- Allow AFTERNOON in daily_entries and entry_audit slot constraints
ALTER TABLE daily_entries DROP CONSTRAINT IF EXISTS daily_entries_slot_check;
ALTER TABLE daily_entries ADD CONSTRAINT daily_entries_slot_check CHECK (slot IN ('MORNING', 'AFTERNOON', 'EVENING'));

ALTER TABLE entry_audit DROP CONSTRAINT IF EXISTS entry_audit_slot_check;
ALTER TABLE entry_audit ADD CONSTRAINT entry_audit_slot_check CHECK (slot IN ('MORNING', 'AFTERNOON', 'EVENING'));

UPDATE daily_entries SET slot = 'AFTERNOON' WHERE slot = 'MORNING';
UPDATE entry_audit SET slot = 'AFTERNOON' WHERE slot = 'MORNING';

