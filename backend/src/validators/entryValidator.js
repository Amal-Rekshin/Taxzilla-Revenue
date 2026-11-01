const { z } = require('zod');
const { isValidDateFormat, isFutureDateInKolkata } = require('../utils/dateUtils');
const { getAllSections } = require('../services/sectionService');

const singleEntryInputSchema = z.object({
  section_id: z.number().int().positive(),
  amount: z.union([
    z.number().min(0, 'Amount must be non-negative'),
    z.string().regex(/^\d+(\.\d{1,2})?$/, 'Amount must be a valid non-negative number with up to 2 decimal places'),
  ]).optional().nullable(),
  new_jobs_amount: z.union([
    z.number().min(0, 'new_jobs_amount must be non-negative'),
    z.string().regex(/^\d+(\.\d{1,2})?$/, 'new_jobs_amount must be a valid non-negative number'),
  ]).optional().nullable(),
  outstanding_jobs_amount: z.union([
    z.number().min(0, 'outstanding_jobs_amount must be non-negative'),
    z.string().regex(/^\d+(\.\d{1,2})?$/, 'outstanding_jobs_amount must be a valid non-negative number'),
  ]).optional().nullable(),
  jobs_completed: z.number().int().min(0, 'jobs_completed must be non-negative').optional().nullable(),
  ongoing_jobs: z.number().int().min(0, 'ongoing_jobs must be non-negative').optional().nullable(),
  new_jobs: z.number().int().min(0, 'new_jobs must be non-negative').optional().nullable(),
  outstanding_jobs: z.number().int().min(0, 'outstanding_jobs must be non-negative').optional().nullable(),
});

const putEntriesSchema = z.object({
  entries: z.array(singleEntryInputSchema).min(1, 'Entries array cannot be empty'),
});

async function validatePutEntries(date, slot, body) {
  // 1. Validate date
  if (!isValidDateFormat(date)) {
    return {
      valid: false,
      error: 'Invalid date format. Expected YYYY-MM-DD.',
    };
  }
  if (isFutureDateInKolkata(date)) {
    return {
      valid: false,
      error: `Future dates cannot be entered or edited. Date ${date} is in the future.`,
    };
  }

  // 2. Validate slot
  if (slot !== 'MORNING' && slot !== 'AFTERNOON' && slot !== 'EVENING') {
    return {
      valid: false,
      error: 'Slot must be either AFTERNOON or EVENING.',
    };
  }

  // 3. Normalise entries array
  const entriesArray = Array.isArray(body) ? body : (body && body.entries ? body.entries : null);
  if (!entriesArray || !Array.isArray(entriesArray)) {
    return {
      valid: false,
      error: 'Request body must be an array or contain an entries array.',
    };
  }

  const parseResult = putEntriesSchema.safeParse({ entries: entriesArray });
  if (!parseResult.success) {
    return {
      valid: false,
      error: parseResult.error.errors.map(e => e.message).join(', '),
    };
  }

  const entries = parseResult.data.entries;

  // 4. Retrieve database sections to drive validation rules dynamically
  const sections = await getAllSections();
  const sectionMap = new Map(sections.map(s => [s.id, s]));

  if (entries.length !== sections.length) {
    return {
      valid: false,
      error: `Expected exactly ${sections.length} section entries, but received ${entries.length}.`,
    };
  }

  const seenSections = new Set();

  for (const entry of entries) {
    if (seenSections.has(entry.section_id)) {
      return {
        valid: false,
        error: `Duplicate entry for section_id ${entry.section_id}.`,
      };
    }
    seenSections.add(entry.section_id);

    const section = sectionMap.get(entry.section_id);
    if (!section) {
      return {
        valid: false,
        error: `Section ID ${entry.section_id} is not recognized.`,
      };
    }

    if (section.count_type === 'SINGLE') {
      if (entry.jobs_completed === undefined || entry.jobs_completed === null) {
        return {
          valid: false,
          error: `Section '${section.name}' (${section.code}) requires jobs_completed.`,
        };
      }
      if (entry.amount === undefined || entry.amount === null) {
        return {
          valid: false,
          error: `Section '${section.name}' (${section.code}) requires amount.`,
        };
      }
      entry.new_jobs_amount = 0;
      entry.outstanding_jobs_amount = 0;
    } else if (section.count_type === 'TRIPLE' || section.code === 'ACCOUNTS') {
      // ACCOUNTS: No jobs_completed, no ongoing_jobs required
      // Uses new_jobs_amount and outstanding_jobs_amount
      // Auto-compute amount = new_jobs_amount + outstanding_jobs_amount
      const nja = parseFloat(entry.new_jobs_amount != null ? entry.new_jobs_amount : (entry.amount || 0)) || 0;
      const oja = parseFloat(entry.outstanding_jobs_amount != null ? entry.outstanding_jobs_amount : 0) || 0;
      entry.new_jobs_amount = nja;
      entry.outstanding_jobs_amount = oja;
      entry.amount = (nja + oja).toFixed(2);
      entry.jobs_completed = null;
      entry.ongoing_jobs = null;
      entry.new_jobs = null;
      entry.outstanding_jobs = null;
    }
  }

  return {
    valid: true,
    data: entries.map(e => ({
      section_id: e.section_id,
      amount: typeof e.amount === 'number' ? e.amount.toFixed(2) : parseFloat(e.amount || 0).toFixed(2),
      new_jobs_amount: e.new_jobs_amount != null ? parseFloat(e.new_jobs_amount).toFixed(2) : '0.00',
      outstanding_jobs_amount: e.outstanding_jobs_amount != null ? parseFloat(e.outstanding_jobs_amount).toFixed(2) : '0.00',
      jobs_completed: e.jobs_completed ?? null,
      ongoing_jobs: null,
      new_jobs: null,
      outstanding_jobs: null,
    })),
  };
}

module.exports = { validatePutEntries };
