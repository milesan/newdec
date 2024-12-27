export type BookingStatus = 'AVAILABLE' | 'HOLD' | 'BOOKED';

export interface DailyBooking {
  id: string;
  startDate: Date;
  endDate: Date;
  cabinId: string;
  status: BookingStatus;
}

export interface WeeklyBooking {
  weeks: Date[];  // Array of week start dates
  cabinId: string;
  status: BookingStatus;
}