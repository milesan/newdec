import { addWeeks, startOfWeek, addDays, addMonths } from 'date-fns';
import { convertToUTC1 } from './timezone';

export function getSeasonalDiscount(date: Date): number {
  const month = date.getMonth();
  const year = date.getFullYear();
  
  // Winter Season (November-May) - 40% discount for non-dorm rooms
  if (month <= 4 || month >= 10) return 0.40;
  
  // Shoulder Season (June, October) - 15% discount
  if (month === 5 || month === 9) return 0.15;
  
  // High Season (July, August, September) - No discount
  return 0;
}

export function getSeasonName(date: Date): string {
  const discount = getSeasonalDiscount(date);
  return discount === 0 ? 'High Season' : 
         discount === 0.15 ? 'Shoulder Season' : 
         'Winter Season';
}

export function getDurationDiscount(numberOfWeeks: number): number {
  if (numberOfWeeks < 3) return 0;
  
  // Graduated discount starting at 3 weeks
  const baseDiscount = 0.10; // 10%
  const extraWeeks = Math.min(numberOfWeeks - 3, 7); // Cap at 10 weeks total
  const extraDiscount = (extraWeeks * 0.015); // 1.5% per additional week
  
  return Math.min(baseDiscount + extraDiscount, 0.20); // Cap at 20% total
}