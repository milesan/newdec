import React, { useState } from 'react';
import { X, Info } from 'lucide-react';
import { DayPicker } from 'react-day-picker';
import { format } from 'date-fns';
import { useDayRules } from '../../hooks/useDayRules';
import type { DayRuleType } from '../../types/scheduling';

interface Props {
  onClose: () => void;
}

export function DayRulesModal({ onClose }: Props) {
  const [selectedDate, setSelectedDate] = useState<Date>();
  const [error, setError] = useState<string | null>(null);
  const { getDayRule, setDayRule, loading } = useDayRules();

  const handleDayClick = async (date: Date) => {
    if (!date) return;
    setSelectedDate(date);
  };

  const handleSetRule = async (type: DayRuleType) => {
    if (!selectedDate) return;

    try {
      setError(null);
      await setDayRule(selectedDate, type);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to set rule');
    }
  };

  const renderDayContent = (date: Date) => {
    const { isArrival, isDeparture, notArrival, notDeparture } = getDayRule(date);
    return (
      <div className="relative">
        <div>{date.getDate()}</div>
        {isArrival && (
          <div className="absolute bottom-0 left-0 w-full text-[8px] text-emerald-600 font-bold">
            ARRIVAL
          </div>
        )}
        {isDeparture && (
          <div className="absolute bottom-0 left-0 w-full text-[8px] text-blue-600 font-bold">
            DEPARTURE
          </div>
        )}
        {notArrival && (
          <div className="absolute bottom-0 left-0 w-full text-[8px] text-rose-600 font-bold">
            NO ARRIVAL
          </div>
        )}
        {notDeparture && (
          <div className="absolute bottom-0 left-0 w-full text-[8px] text-rose-600 font-bold">
            NO DEPARTURE
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-[60]">
      <div className="bg-white rounded-lg w-full max-w-2xl">
        <div className="p-6 border-b border-stone-200 flex justify-between items-center">
          <h3 className="text-xl font-medium">Manage Day Rules</h3>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-6">
          <div className="space-y-6">
            <div className="bg-stone-50 p-4 rounded-lg border border-stone-200">
              <div className="flex items-start gap-3">
                <Info className="w-5 h-5 text-emerald-900 flex-shrink-0 mt-0.5" />
                <div className="text-sm text-stone-600">
                  <p className="font-medium text-stone-900 mb-1">How Day Rules Work</p>
                  <ul className="space-y-2">
                    <li>• Click a date to select it</li>
                    <li>• Set it as an arrival or departure day</li>
                    <li>• Or explicitly mark it as not available for arrival/departure</li>
                    <li>• Clear a rule to revert to default behavior</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="flex gap-8">
              <div className="flex-1">
                <DayPicker
                  mode="single"
                  selected={selectedDate}
                  onSelect={(date) => date && handleDayClick(date)}
                  components={{
                    DayContent: ({ date }) => renderDayContent(date)
                  }}
                />
              </div>

              <div className="flex-1">
                {selectedDate ? (
                  <div className="space-y-4">
                    <h4 className="font-medium">
                      {format(selectedDate, 'MMMM d, yyyy')}
                    </h4>
                    
                    <div className="space-y-2">
                      <button
                        onClick={() => handleSetRule('arrival')}
                        className="w-full px-4 py-2 bg-emerald-100 text-emerald-900 rounded-lg hover:bg-emerald-200"
                      >
                        Set as Arrival Day
                      </button>
                      <button
                        onClick={() => handleSetRule('departure')}
                        className="w-full px-4 py-2 bg-blue-100 text-blue-900 rounded-lg hover:bg-blue-200"
                      >
                        Set as Departure Day
                      </button>
                      <button
                        onClick={() => handleSetRule('not_arrival')}
                        className="w-full px-4 py-2 bg-rose-100 text-rose-900 rounded-lg hover:bg-rose-200"
                      >
                        Not Available for Arrival
                      </button>
                      <button
                        onClick={() => handleSetRule('not_departure')}
                        className="w-full px-4 py-2 bg-rose-100 text-rose-900 rounded-lg hover:bg-rose-200"
                      >
                        Not Available for Departure
                      </button>
                      <button
                        onClick={() => handleSetRule(null)}
                        className="w-full px-4 py-2 bg-stone-100 text-stone-900 rounded-lg hover:bg-stone-200"
                      >
                        Clear Rule
                      </button>
                    </div>

                    {error && (
                      <div className="p-4 bg-rose-50 text-rose-600 rounded-lg text-sm">
                        {error}
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-center text-stone-500">
                    Select a date to manage its rules
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}