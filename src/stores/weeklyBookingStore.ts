import { create } from 'zustand';
import { addWeeks, isSameWeek, isAfter, isBefore } from 'date-fns';
import type { Accommodation } from '../types';

interface WeeklyBookingState {
  selectedWeeks: Date[];
  selectedCabin: string | null;
  actions: {
    selectWeek: (week: Date) => void;
    selectCabin: (cabinId: string) => void;
    clearSelection: () => void;
  };
}

export const useWeeklyBookingStore = create<WeeklyBookingState>((set) => ({
  selectedWeeks: [],
  selectedCabin: null,
  actions: {
    selectWeek: (week: Date) => {
      set((state) => {
        const { selectedWeeks } = state;

        if (selectedWeeks.length === 0) {
          return { selectedWeeks: [week] };
        }

        // If clicking an already selected week
        if (selectedWeeks.some(w => isSameWeek(w, week))) {
          // Only allow deselecting if it's an edge week
          if (isSameWeek(week, selectedWeeks[0]) || isSameWeek(week, selectedWeeks[selectedWeeks.length - 1])) {
            return {
              selectedWeeks: selectedWeeks.filter(w => !isSameWeek(w, week))
            };
          }
          return state;
        }

        // Get the earliest and latest dates
        const earliestDate = selectedWeeks[0];
        const latestDate = selectedWeeks[selectedWeeks.length - 1];

        // If selecting a week before the earliest date
        if (isBefore(week, earliestDate)) {
          const newWeeks = [];
          let currentWeek = week;
          while (isBefore(currentWeek, earliestDate) || isSameWeek(currentWeek, earliestDate)) {
            newWeeks.push(currentWeek);
            currentWeek = addWeeks(currentWeek, 1);
          }
          return { selectedWeeks: [...newWeeks, ...selectedWeeks.slice(1)] };
        }

        // If selecting a week after the latest date
        if (isAfter(week, latestDate)) {
          const newWeeks = [];
          let currentWeek = addWeeks(latestDate, 1);
          while (isBefore(currentWeek, week) || isSameWeek(currentWeek, week)) {
            newWeeks.push(currentWeek);
            currentWeek = addWeeks(currentWeek, 1);
          }
          return { selectedWeeks: [...selectedWeeks, ...newWeeks] };
        }

        return state;
      });
    },
    selectCabin: (cabinId: string) => set({ selectedCabin: cabinId }),
    clearSelection: () => set({ selectedWeeks: [], selectedCabin: null }),
  },
}));