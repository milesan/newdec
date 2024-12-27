import { addHours, format, startOfDay, setHours, setMinutes } from 'date-fns';

// UTC+1 offset in hours
const UTC_PLUS_ONE = 1;

export function convertToUTC1(date: Date, hour: number): Date {
  // First convert to UTC midnight
  const utcDate = new Date(Date.UTC(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    0, 0, 0, 0
  ));
  
  // Then add hours to get to UTC+1 at the specified hour
  return addHours(utcDate, hour + UTC_PLUS_ONE);
}

export function formatDateUTC1(date: Date, formatString: string): string {
  // Add UTC+1 offset to the date
  const utc1Date = addHours(date, UTC_PLUS_ONE);
  return format(utc1Date, formatString);
}

export function getUTC1Date(date: Date): Date {
  const utcDate = new Date(Date.UTC(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    0, 0, 0, 0
  ));
  return addHours(utcDate, UTC_PLUS_ONE);
}

export const CHECK_IN_HOUR = 15; // 3 PM
export const CHECK_OUT_HOUR = 12; // 12 PM