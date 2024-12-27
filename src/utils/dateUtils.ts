import { addDays, isSameDay, isWithinInterval, startOfDay } from 'date-fns';

export function getDayName(date: Date): string {
  return date.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
}

export function isValidArrivalDay(date: Date, arrivalDay: string): boolean {
  return getDayName(date) === arrivalDay;
}

export function isValidDepartureDay(date: Date, departureDay: string): boolean {
  return getDayName(date) === departureDay;
}

export function isDateSelectable(
  date: Date,
  selectedRange: { from?: Date; to?: Date } | undefined,
  arrivalDay: string,
  departureDay: string
): boolean {
  const dayName = getDayName(date);
  
  // If no dates are selected, only allow arrival days
  if (!selectedRange?.from) {
    return dayName === arrivalDay;
  }

  // If start date is selected but no end date
  if (selectedRange.from && !selectedRange.to) {
    // Allow selecting a new arrival day at any time
    if (dayName === arrivalDay) {
      return true;
    }
    
    // Allow selecting departure days after the arrival date
    if (dayName === departureDay) {
      return date > selectedRange.from;
    }
    
    return false;
  }

  // If both dates are selected, only allow arrival days to start a new selection
  return dayName === arrivalDay;
}