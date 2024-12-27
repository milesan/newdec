import React, { useState } from 'react';
import { Trees } from 'lucide-react';
import { motion } from 'framer-motion';
import { WeekSelector } from '../components/WeekSelector';
import { CabinSelector } from '../components/CabinSelector';
import { BookingSummary } from '../components/BookingSummary';
import { useWeeklyAccommodations } from '../hooks/useWeeklyAccommodations';

const WEEKS_TO_SHOW = 16;
const BACKGROUND_IMAGE = "https://images.unsplash.com/photo-1510798831971-661eb04b3739?q=80&w=2940&auto=format&fit=crop";

export function FinalPage() {
  const { accommodations, loading } = useWeeklyAccommodations();
  const [selectedWeeks, setSelectedWeeks] = useState<Date[]>([]);
  const [selectedAccommodation, setSelectedAccommodation] = useState<string | null>(null);

  const toggleWeek = (week: Date) => {
    setSelectedWeeks(prev => {
      if (prev.length === 0) {
        return [week];
      }
      return [];
    });
  };

  const isConsecutiveWeek = () => false;
  const isFirstOrLastSelected = () => false;

  return (
    <div 
      className="min-h-screen p-4 md:p-8 tree-pattern"
      style={{
        backgroundImage: `linear-gradient(rgba(244, 240, 232, 0.9), rgba(244, 240, 232, 0.9)), url(${BACKGROUND_IMAGE})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }}
    >
      <header className="max-w-6xl mx-auto mb-12">
        <div className="flex items-center gap-3 mb-2">
          <Trees className="w-6 h-6 text-emerald-600" />
          <h1 className="text-2xl font-mono">the Garden</h1>
        </div>
        <p className="text-stone-600 font-mono">Escape to reality</p>
      </header>

      <div className="grid lg:grid-cols-[2fr,1fr] gap-8 max-w-6xl mx-auto">
        <section>
          <WeekSelector
            weeks={[]}
            selectedWeeks={selectedWeeks}
            onToggleWeek={toggleWeek}
            isConsecutiveWeek={isConsecutiveWeek}
            isFirstOrLastSelected={isFirstOrLastSelected}
            currentMonth={new Date()}
          />
          
          <CabinSelector
            accommodations={accommodations}
            selectedAccommodation={selectedAccommodation}
            onSelectAccommodation={setSelectedAccommodation}
            selectedWeeks={selectedWeeks}
            currentMonth={new Date()}
          />
        </section>

        <BookingSummary
          selectedWeeks={selectedWeeks}
          selectedAccommodation={selectedAccommodation ? 
            accommodations.find(a => a.id === selectedAccommodation) : null}
          baseRate={190}
          onClearWeeks={() => setSelectedWeeks([])}
          onClearAccommodation={() => setSelectedAccommodation(null)}
        />
      </div>
    </div>
  );
}