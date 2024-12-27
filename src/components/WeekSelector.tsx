import React from 'react';
import { addDays } from 'date-fns';
import { WeekBox } from './WeekBox';
import clsx from 'clsx';

interface Props {
  weeks: Date[];
  selectedWeeks: Date[];
  onToggleWeek: (week: Date) => void;
  isConsecutiveWeek: (week: Date | undefined) => boolean;
  isFirstOrLastSelected: (week: Date) => boolean;
  currentMonth: Date;
  isMobile?: boolean;
}

export function WeekSelector({
  weeks,
  selectedWeeks,
  onToggleWeek,
  isConsecutiveWeek,
  isFirstOrLastSelected,
  currentMonth,
  isMobile = false
}: Props) {
  return (
    <div className={clsx(
      'grid gap-4',
      isMobile ? 'grid-cols-3' : 'grid-cols-4'
    )}>
      {weeks.map((week) => {
        const isSelected = selectedWeeks.some(w => week.getTime() === w.getTime());
        const isFirstSelected = selectedWeeks.length > 0 && week.getTime() === selectedWeeks[0].getTime();
        const isSelectable = true; // You can add your availability logic here
        
        return (
          <WeekBox
            key={week.toISOString()}
            week={week}
            weekStart={week}
            weekEnd={addDays(week, 6)}
            index={weeks.indexOf(week)}
            isSelected={isSelected}
            isConsecutive={isConsecutiveWeek(week)}
            isEdge={isFirstOrLastSelected(week)}
            isFirstSelected={isFirstSelected}
            isSelectable={isSelectable}
            onClick={() => isSelectable && onToggleWeek(week)}
            selectedWeeksCount={selectedWeeks.length}
          />
        );
      })}
    </div>
  );
}