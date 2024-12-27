import React from 'react';
import { motion } from 'framer-motion';
import { format, addDays } from 'date-fns';
import clsx from 'clsx';

interface Props {
  week: Date;
  weekStart: Date;
  weekEnd: Date;
  index: number;
  isSelected: boolean;
  isConsecutive: boolean;
  isEdge: boolean;
  isFirstSelected?: boolean;
  isSelectable: boolean;
  onClick: () => void;
  selectedWeeksCount?: number;
}

export function WeekBox({
  week,
  weekStart,
  weekEnd,
  index,
  isSelected,
  isConsecutive,
  isEdge,
  isFirstSelected,
  isSelectable,
  onClick,
  selectedWeeksCount = 0
}: Props) {
  return (
    <motion.button
      onClick={onClick}
      className={clsx(
        'relative p-4 bg-white border-2 transition-all duration-300',
        'aspect-[1.5] shadow-sm hover:shadow-md',
        'pixel-corners',
        isSelected && 'border-emerald-600 shadow-lg',
        !isSelected && isConsecutive && 'border-emerald-600/20',
        !isSelected && !isConsecutive && 'border-stone-200',
        !isSelectable && 'opacity-50 cursor-not-allowed'
      )}
      whileHover={isSelectable ? { scale: 1.02 } : undefined}
      whileTap={isSelectable ? { scale: 0.98 } : undefined}
    >
      <div className="text-center flex flex-col justify-center h-full">
        {isSelected ? (
          isEdge ? (
            <>
              <div className="text-2xl font-display mb-1">
                {format(isFirstSelected ? weekStart : weekEnd, 'MMM d')}
              </div>
              <div className="font-mono text-sm text-emerald-700 font-medium">
                {isFirstSelected ? 
                  (selectedWeeksCount > 1 ? 'Arrival' : `→ ${format(weekEnd, 'MMM d')}`) : 
                  'Departure'}
              </div>
            </>
          ) : null
        ) : (
          <>
            <div className="text-2xl font-display mb-1">
              {format(weekStart, 'MMM d')}
            </div>
            <div className="font-mono text-sm text-stone-500 flex items-center justify-center gap-2">
              <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path d="M4 12h16m0 0l-6-6m6 6l-6 6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <span>{format(addDays(weekStart, 6), 'MMM d')}</span>
            </div>
          </>
        )}
      </div>

      {isSelected && !isEdge && (
        <>
          <div className="connecting-line left" />
          <div className="connecting-line right" />
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none"
            preserveAspectRatio="none"
            viewBox="0 0 100 30"
          >
            <path
              d="M 0 15 Q 25 5, 50 15 T 100 15"
              className="squiggle-path"
              stroke="rgb(5, 150, 105)"
              strokeWidth="2"
              fill="none"
              vectorEffect="non-scaling-stroke"
            />
          </svg>
        </>
      )}

      <div 
        className={clsx(
          'absolute bottom-0 left-0 right-0 transition-all duration-300',
          isSelected ? 'bg-emerald-600/40 h-1.5' : 'bg-stone-200/40'
        )}
      />
    </motion.button>
  );
}