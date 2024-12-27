import React, { useState, useCallback } from 'react';
import { DayPicker, DateRange } from 'react-day-picker';
import { addDays, differenceInDays, isWithinInterval, addBusinessDays, addMonths, startOfMonth, format } from 'date-fns';
import { useMediaQuery } from '../hooks/useMediaQuery';
import { useArrivalRules } from '../hooks/useArrivalRules';
import { useSchedulingRules } from '../hooks/useSchedulingRules';
import { useDayRules } from '../hooks/useDayRules';
import { getDayName } from '../utils/dateUtils';
import { bookingRules } from '../utils/bookingRules';
import { convertToUTC1 } from '../utils/timezone';
import 'react-day-picker/dist/style.css';

interface DateRangePickerProps {
  selected: DateRange | undefined;
  onSelect: (range: DateRange | undefined) => void;
  isExtension?: boolean;
}

export function DateRangePicker({ selected, onSelect, isExtension = false }: DateRangePickerProps) {
  const isLarge = useMediaQuery('(min-width: 1024px)');
  const isMedium = useMediaQuery('(min-width: 768px)');
  const { rules, loading } = useArrivalRules();
  const { isDateBlocked, getArrivalDepartureForDate } = useSchedulingRules();
  const { getDayRule } = useDayRules();
  const [selectingDeparture, setSelectingDeparture] = useState(false);
  const [month, setMonth] = useState<Date>(convertToUTC1(new Date('2024-12-16'), 0));
  
  const numberOfMonths = isLarge ? 2 : isMedium ? 2 : 1;

  const handleDayClick = useCallback((day: Date | undefined) => {
    if (!day) {
      onSelect(undefined);
      setSelectingDeparture(false);
      return;
    }

    const dayName = getDayName(day);
    const { isArrival, isDeparture, notArrival, notDeparture } = getDayRule(day);
    const customDays = getArrivalDepartureForDate(day);

    // Special period check
    const isSpecialPeriod = isWithinInterval(day, {
      start: new Date('2024-12-16'),
      end: new Date('2025-01-05')
    });

    const effectiveArrivalDay = isSpecialPeriod ? 'monday' : (customDays.arrival || rules.arrival_day);
    const effectiveDepartureDay = isSpecialPeriod ? 'sunday' : (customDays.departure || rules.departure_day);

    // If clicking a disabled date, reset selection
    if (!isDateEnabled(day)) {
      onSelect(undefined);
      setSelectingDeparture(false);
      return;
    }

    // If we're selecting a departure date
    if (selectingDeparture && selected?.from) {
      // Check if it's a valid departure day
      const isValidDeparture = (isDeparture || (!notDeparture && dayName === effectiveDepartureDay)) && day > selected.from;
      
      if (isValidDeparture) {
        onSelect({ from: selected.from, to: day });
        setSelectingDeparture(false);
      } else {
        // If invalid departure, start new selection if it's a valid arrival day
        if (isArrival || (!notArrival && dayName === effectiveArrivalDay)) {
          onSelect({ from: day, to: undefined });
          setSelectingDeparture(true);
        } else {
          onSelect(undefined);
          setSelectingDeparture(false);
        }
      }
      return;
    }

    // Starting a new selection
    if (isArrival || (!notArrival && dayName === effectiveArrivalDay)) {
      onSelect({ from: day, to: undefined });
      setSelectingDeparture(true);
    } else {
      onSelect(undefined);
      setSelectingDeparture(false);
    }
  }, [rules, selected, selectingDeparture, getDayRule, getArrivalDepartureForDate]);

  const isDateEnabled = useCallback((date: Date) => {
    const dayName = getDayName(date);
    const minDate = new Date('2024-12-16');
    const { isArrival, isDeparture, notArrival, notDeparture } = getDayRule(date);
    const customDays = getArrivalDepartureForDate(date);

    // Special period check
    const isSpecialPeriod = isWithinInterval(date, {
      start: new Date('2024-12-16'),
      end: new Date('2025-01-05')
    });

    const effectiveArrivalDay = isSpecialPeriod ? 'monday' : (customDays.arrival || rules.arrival_day);
    const effectiveDepartureDay = isSpecialPeriod ? 'sunday' : (customDays.departure || rules.departure_day);

    // Don't allow dates before Dec 16th, 2024
    if (date < minDate) return false;

    // Don't allow past dates
    if (date < new Date()) return false;

    // Calculate business days ahead (counting weekends as 1 day)
    const today = new Date();
    let daysAhead = 0;
    let currentDate = new Date(today);
    while (currentDate < date) {
      currentDate.setDate(currentDate.getDate() + 1);
      if (currentDate.getDay() === 6 || currentDate.getDay() === 0) { // Weekend
        daysAhead += 0.5;
      } else {
        daysAhead += 1;
      }
    }
    if (daysAhead < 3) return false;

    // Check if date is blocked
    if (isDateBlocked(date)) return false;

    // If we're selecting a departure date
    if (selectingDeparture && selected?.from) {
      return (isDeparture || (!notDeparture && dayName === effectiveDepartureDay)) && date > selected.from;
    }

    // Otherwise, only enable arrival days
    return isArrival || (!notArrival && dayName === effectiveArrivalDay);
  }, [rules, selected, selectingDeparture, isDateBlocked, getDayRule, getArrivalDepartureForDate]);

  const modifiers = {
    arrival: (date: Date) => {
      const { isArrival, notArrival } = getDayRule(date);
      const customDays = getArrivalDepartureForDate(date);
      const isSpecialPeriod = isWithinInterval(date, {
        start: new Date('2024-12-16'),
        end: new Date('2025-01-05')
      });
      const effectiveArrivalDay = isSpecialPeriod ? 'monday' : (customDays.arrival || rules.arrival_day);
      return isArrival || (!notArrival && getDayName(date) === effectiveArrivalDay);
    },
    departureAvailable: (date: Date) => {
      if (!selectingDeparture || !selected?.from) return false;
      const { isDeparture, notDeparture } = getDayRule(date);
      const customDays = getArrivalDepartureForDate(date);
      const isSpecialPeriod = isWithinInterval(date, {
        start: new Date('2024-12-16'),
        end: new Date('2025-01-05')
      });
      const effectiveDepartureDay = isSpecialPeriod ? 'sunday' : (customDays.departure || rules.departure_day);
      return (isDeparture || (!notDeparture && getDayName(date) === effectiveDepartureDay)) && date > selected.from;
    },
    selected: (date: Date) => 
      (selected?.from && date.getTime() === selected.from.getTime()) ||
      (selected?.to && date.getTime() === selected.to.getTime()),
    inRange: (date: Date) => 
      selected?.from && selected?.to && 
      isWithinInterval(date, { start: selected.from, end: selected.to }),
    blocked: (date: Date) => isDateBlocked(date)
  };

  const formatDate = (date: Date) => {
    const formatter = new Intl.DateTimeFormat('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
    const parts = formatter.formatToParts(date);
    const month = parts.find(part => part.type === 'month')?.value;
    const day = parts.find(part => part.type === 'day')?.value;
    const year = parts.find(part => part.type === 'year')?.value;
    return `${month} ${day}${getOrdinalSuffix(parseInt(day || '0'))}, ${year}`;
  };

  const getOrdinalSuffix = (day: number) => {
    if (day > 3 && day < 21) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  const numberOfWeeks = selected?.from && selected?.to 
    ? Math.ceil(differenceInDays(selected.to, selected.from) / 7)
    : 0;

  return (
    <div className="space-y-6">
      <div className="overflow-x-auto">
        <style>
          {`
            .rdp {
              margin: 0 auto;
              width: fit-content;
            }
            .rdp-months {
              justify-content: center;
            }
            .rdp-day {
              border-radius: 0 !important;
            }
            .rdp-day_selected {
              border-radius: 0 !important;
            }
            .rdp-day_selected:not([aria-selected="true"]) {
              background-color: #111827 !important;
              color: white !important;
              opacity: 1 !important;
            }
            .rdp-day[aria-selected="true"]:first-of-type {
              background-color: #111827 !important;
              border-radius: 2rem 0 0 2rem !important;
            }
            .rdp-day[aria-selected="true"]:last-of-type {
              background-color: #111827 !important;
              border-radius: 0 2rem 2rem 0 !important;
            }
            .rdp-day_range_middle {
              color: white !important;
              opacity: 1 !important;
            }
            .rdp-day_today {
              font-weight: bold !important;
            }
            .rdp-day_disabled:not(.blocked) {
              opacity: 0.3 !important;
            }
            .rdp-day.blocked {
              text-decoration: line-through !important;
              background-color: #fee2e2 !important;
              color: #991b1b !important;
            }
            .rdp-day_selected {
              opacity: 1 !important;
            }
            .rdp-day_range_middle {
              opacity: 1 !important;
            }
            .rdp-day_outside {
              visibility: hidden !important;
            }
            .rdp-day.arrival {
              border-radius: 2rem 0 0 2rem !important;
              clip-path: inset(0 0 0 0 round 2rem 0 0 2rem) !important;
              mask-image: radial-gradient(circle at left, black 100%, transparent 100%) !important;
              -webkit-mask-image: radial-gradient(circle at left, black 100%, transparent 100%) !important;
            }
            .rdp-day.arrival[aria-selected="true"] {
              border-radius: 2rem 0 0 2rem !important;
              clip-path: inset(0 0 0 0 round 2rem 0 0 2rem) !important;
            }
            .rdp-day.departureAvailable {
              border-radius: 0 2rem 2rem 0 !important;
              clip-path: inset(0 0 0 0 round 0 2rem 2rem 0) !important;
            }
          `}
        </style>
        <DayPicker
          mode="range"
          selected={selected}
          onDayClick={handleDayClick}
          numberOfMonths={numberOfMonths}
          showOutsideDays={false}
          disabled={date => !isDateEnabled(date)}
          modifiers={modifiers}
          modifiersStyles={{
            arrival: {
              color: 'white',
              backgroundColor: '#065F46',
              fontWeight: 'bold'
            },
            departureAvailable: {
              color: 'white',
              backgroundColor: '#1E40AF',
              fontWeight: 'bold'
            },
            selected: {
              color: 'white',
              fontWeight: 'bold'
            },
            inRange: {
              color: 'white',
              backgroundColor: '#111827',
              fontWeight: 'bold',
              opacity: '1'
            }
          }}
          fromDate={new Date('2024-12-16')}
          month={month}
          onMonthChange={setMonth}
        />
      </div>

      <div className="border-t border-stone-200 pt-6 space-y-4">
        <div className="bg-stone-50 rounded-lg p-4">
          <h3 className="font-display text-lg text-stone-900 mb-2">Stay Details</h3>
          {selected?.from ? (
            <div className="space-y-2 text-sm">
              <p>
                You may arrive {formatDate(selected.from)} from 3-6PM
              </p>
              {selected.to && (
                <p>
                  You may depart {formatDate(selected.to)} by 12PM Noon
                </p>
              )}
              {selected.to && (
                <p>
                  <span className="text-stone-600">Length:</span>{' '}
                  <span className="font-medium">
                    {numberOfWeeks} {numberOfWeeks === 1 ? 'week' : 'weeks'}
                  </span>
                </p>
              )}
            </div>
          ) : (
            <p className="text-stone-600 text-sm">
              Select your check-in date (highlighted in green)
            </p>
          )}
        </div>
        <div className="text-sm text-stone-600 space-y-1">
          <p>• Minimum stay: 7 days</p>
          <p>• Check-in: {rules.arrival_day.charAt(0).toUpperCase() + rules.arrival_day.slice(1)} at 3 PM</p>
          <p>• Check-out: {rules.departure_day.charAt(0).toUpperCase() + rules.departure_day.slice(1)} at 12 PM</p>
          {!isExtension && (
            <p className="text-emerald-700">• {bookingRules.minAdvance}</p>
          )}
        </div>
      </div>
    </div>
  );
}