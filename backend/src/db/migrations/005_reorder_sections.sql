-- Migration 005: Reorder sections to EXIM, GST, REGISTRATION, CRO, ACCOUNTS, MARKETING
UPDATE sections SET sort_order = 1 WHERE code = 'EXIM';
UPDATE sections SET sort_order = 2 WHERE code = 'GST';
UPDATE sections SET sort_order = 3 WHERE code = 'REGISTRATION';
UPDATE sections SET sort_order = 4 WHERE code = 'CRO';
UPDATE sections SET sort_order = 5 WHERE code = 'ACCOUNTS';
UPDATE sections SET sort_order = 6 WHERE code = 'MARKETING';

