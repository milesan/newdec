import { addDays, startOfWeek, endOfWeek, eachDayOfInterval } from 'date-fns';
import type { DailyBooking, WeeklyBooking } from '../types/booking';

export function dailyToWeekly(dailyBooking: DailyBooking): WeeklyBooking {
  const startWeek = startOfWeek(new Date(dailyBooking.startDate));
  const endWeek = startOfWeek(new Date(dailyBooking.endDate));
  
  const weeks: Date[] = [];
  let currentWeek = startWeek;
  
  while (currentWeek <= endWeek) {
    weeks.push(currentWeek);
    currentWeek = addDays(currentWeek, 7);
  }
  
  return {
    weeks,
    cabinId: dailyBooking.cabinId,
    status: dailyBooking.status
  };
}

export function weeklyToDaily(weeklyBooking: WeeklyBooking): DailyBooking {
  const firstWeek = weeklyBooking.weeks[0];
  const lastWeek = weeklyBooking.weeks[weeklyBooking.weeks.length - 1];
  
  return {
    id: '', // Will be assigned by the database
    startDate: firstWeek,
    endDate: endOfWeek(lastWeek),
    cabinId: weeklyBooking.cabinId,
    status: weeklyBooking.status
  };
}

export function isWeekAvailable(weekStart: Date, dailyBookings: DailyBooking[]): boolean {
  const weekEnd = endOfWeek(weekStart);
  const daysInWeek = eachDayOfInterval({ start: weekStart, end: weekEnd });
  
  return !daysInWeek.some(day => 
    dailyBookings.some(booking => 
      day >= new Date(booking.startDate) && 
      day <= new Date(booking.endDate)
    )
  );
}