import React, { useState, useMemo } from 'react';
import { Calendar, Settings, ChevronDown } from 'lucide-react';
import { isSameWeek, addWeeks, isAfter, isBefore, startOfMonth, format, addMonths } from 'date-fns';
import { WeekSelector } from '../components/WeekSelector';
import { CabinSelector } from '../components/CabinSelector';
import { BookingSummary } from '../components/BookingSummary';
import { MaxWeeksModal } from '../components/MaxWeeksModal';
import { CalendarConfig } from '../components/admin/CalendarConfig';
import { generateWeeks, generateSquigglePath, getWeeksInRange } from '../utils/dates';
import { useWeeklyAccommodations } from '../hooks/useWeeklyAccommodations';
import { useSession } from '../hooks/useSession';
import { motion } from 'framer-motion';
import { convertToUTC1 } from '../utils/timezone';

const DESKTOP_WEEKS = 16;
const MOBILE_WEEKS = 12;
const BASE_RATE = 3;
const BACKGROUND_IMAGE = "https://images.unsplash.com/photo-1510798831971-661eb04b3739?q=80&w=2940&auto=format&fit=crop";

export function Book2Page() {
  const { accommodations, loading } = useWeeklyAccommodations();
  const [selectedWeeks, setSelectedWeeks] = useState<Date[]>([]);
  const [selectedAccommodation, setSelectedAccommodation] = useState<string | null>(null);
  const [currentMonth, setCurrentMonth] = useState(() => startOfMonth(convertToUTC1(new Date('2024-12-16'), 0)));
  const [showMaxWeeksModal, setShowMaxWeeksModal] = useState(false);
  const [showCalendarConfig, setShowCalendarConfig] = useState(false);
  const session = useSession();
  const isAdmin = session?.user?.email === 'andre@thegarden.pt';
  const isMobile = window.innerWidth < 768;
  
  const [squigglePaths] = useState(() => 
    Array.from({ length: DESKTOP_WEEKS }, () => generateSquigglePath())
  );

  const weeks = useMemo(() => 
    generateWeeks(currentMonth, isMobile ? MOBILE_WEEKS : DESKTOP_WEEKS),
    [currentMonth, isMobile]
  );

  const isConsecutiveWeek = (nextWeek: Date | undefined) => {
    if (!nextWeek || selectedWeeks.length === 0) return false;
    return selectedWeeks.some(week => 
      isSameWeek(addWeeks(week, 1), nextWeek)
    );
  };

  const isFirstOrLastSelected = (week: Date) => {
    if (selectedWeeks.length === 0) return false;
    return isSameWeek(week, selectedWeeks[0]) || 
           isSameWeek(week, selectedWeeks[selectedWeeks.length - 1]);
  };

  const toggleWeek = async (week: Date) => {
    setSelectedWeeks(prev => {
      const isSelected = prev.some(w => isSameWeek(w, week));
      
      if (isSelected && !isFirstOrLastSelected(week)) {
        return prev;
      }
      
      if (isSelected) {
        return prev.filter(w => !isSameWeek(w, week));
      }
      
      if (prev.length === 0) {
        return [week];
      }

      const earliestDate = prev[0];
      const latestDate = prev[prev.length - 1];

      let newWeeks: Date[];
      if (isBefore(week, earliestDate)) {
        newWeeks = [...getWeeksInRange(weeks, week, latestDate)];
      } else if (isAfter(week, latestDate)) {
        newWeeks = [...getWeeksInRange(weeks, earliestDate, week)];
      } else {
        return prev;
      }

      if (newWeeks.length > 12) {
        setShowMaxWeeksModal(true);
        return prev;
      }

      return newWeeks;
    });
  };

  const getPrevMonthName = () => {
    const prevMonth = addMonths(currentMonth, -1);
    return format(prevMonth, 'MMM');
  };

  const getNextMonthName = () => {
    const nextMonth = addMonths(currentMonth, 1);
    return format(nextMonth, 'MMM');
  };

  return (
    <div 
      className="min-h-screen p-4 md:p-8 tree-pattern"
      style={{
        backgroundImage: `linear-gradient(rgba(244, 240, 232, 0.9), rgba(244, 240, 232, 0.9)), url(${BACKGROUND_IMAGE})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }}
    >
      <div className="grid lg:grid-cols-[2fr,1fr] gap-8 max-w-6xl mx-auto">
        <section>
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => setCurrentMonth(prev => addMonths(prev, -1))}
              className="bg-white px-6 py-2 rounded-lg font-serif text-lg hover:bg-stone-50 transition-colors pixel-corners"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {getPrevMonthName()}
            </motion.button>
            
            <div className="flex items-center gap-4">
              <h2 className="text-3xl font-serif font-light">
                {format(currentMonth, `MMMM '''`)}
                {format(currentMonth, 'yy')}
              </h2>
              {isAdmin && (
                <button
                  onClick={() => setShowCalendarConfig(true)}
                  className="flex items-center gap-2 bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 transition-colors"
                >
                  <Settings className="w-4 h-4" />
                  <span>Configure Rules</span>
                </button>
              )}
            </div>
            
            <motion.button
              onClick={() => setCurrentMonth(prev => addMonths(prev, 1))}
              className="bg-white px-6 py-2 rounded-lg font-serif text-lg hover:bg-stone-50 transition-colors pixel-corners"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {getNextMonthName()}
            </motion.button>
          </div>

          <WeekSelector
            weeks={weeks}
            selectedWeeks={selectedWeeks}
            onToggleWeek={toggleWeek}
            isConsecutiveWeek={isConsecutiveWeek}
            isFirstOrLastSelected={isFirstOrLastSelected}
            currentMonth={currentMonth}
            isMobile={isMobile}
          />
          
          <div className="flex flex-col items-center mt-6">
            <ChevronDown className="w-8 h-8 text-stone-400 animate-bounce" />
          </div>
          
          <CabinSelector
            accommodations={accommodations}
            selectedAccommodation={selectedAccommodation}
            onSelectAccommodation={setSelectedAccommodation}
            selectedWeeks={selectedWeeks}
            currentMonth={currentMonth}
          />
        </section>

        <BookingSummary
          selectedWeeks={selectedWeeks}
          selectedAccommodation={selectedAccommodation ? 
            accommodations.find(a => a.id === selectedAccommodation) : null}
          baseRate={BASE_RATE}
          onClearWeeks={() => setSelectedWeeks([])}
          onClearAccommodation={() => setSelectedAccommodation(null)}
        />
      </div>

      <MaxWeeksModal 
        isOpen={showMaxWeeksModal}
        onClose={() => setShowMaxWeeksModal(false)}
      />

      {showCalendarConfig && (
        <CalendarConfig
          onClose={() => setShowCalendarConfig(false)}
          onSave={() => {
            setShowCalendarConfig(false);
            setSelectedWeeks([]);
          }}
        />
      )}
    </div>
  );
}