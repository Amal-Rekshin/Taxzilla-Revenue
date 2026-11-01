/**
 * Timezone and date helper functions for Asia/Kolkata
 */

function getTodayInKolkata() {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return formatter.format(new Date()); // Formats as YYYY-MM-DD
}

function isValidDateFormat(dateStr) {
  if (typeof dateStr !== 'string') return false;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const [year, month, day] = dateStr.split('-').map(Number);
  const d = new Date(Date.UTC(year, month - 1, day));
  return (
    d.getUTCFullYear() === year &&
    d.getUTCMonth() === month - 1 &&
    d.getUTCDate() === day
  );
}

function isFutureDateInKolkata(dateStr) {
  const today = getTodayInKolkata();
  return dateStr > today;
}

function isSunday(dateStr) {
  if (!isValidDateFormat(dateStr)) return false;
  const [year, month, day] = dateStr.split('-').map(Number);
  const d = new Date(Date.UTC(year, month - 1, day));
  return d.getUTCDay() === 0;
}

module.exports = {
  getTodayInKolkata,
  isValidDateFormat,
  isFutureDateInKolkata,
  isSunday,
};

