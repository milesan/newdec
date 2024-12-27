import React, { useState, useEffect } from 'react';
import { format, addDays } from 'date-fns';
import { supabase } from '../lib/supabase';
import { Calendar, ChevronLeft, ChevronRight } from 'lucide-react';
import { StatusModal } from './StatusModal';
import type { AvailabilityStatus } from '../types/availability';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';

interface Event {
  id: string;
  title: string;
  start: string;
  end: string;
  backgroundColor: string;
  classNames: string[];
  extendedProps: {
    status: AvailabilityStatus;
    accommodationId: string;
  };
}

export function AvailabilityCalendar() {
  const [events, setEvents] = useState<Event[]>([]);
  const [accommodations, setAccommodations] = useState<any[]>([]);
  const [selectedAccommodation, setSelectedAccommodation] = useState<string>('all');
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [selectedDates, setSelectedDates] = useState<{ start: Date; end: Date } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadData();
  }, [selectedAccommodation]);

  async function loadData() {
    try {
      setError(null);
      setLoading(true);

      // Load accommodations
      const { data: accommodationsData, error: accommodationsError } = await supabase
        .from('accommodations')
        .select('*')
        .order('title');
      
      if (accommodationsError) throw accommodationsError;
      setAccommodations(accommodationsData || []);

      // Load availability
      let query = supabase
        .from('availability')
        .select('*');

      if (selectedAccommodation !== 'all') {
        query = query.eq('accommodation_id', selectedAccommodation);
      }

      const { data: availabilityData, error: availabilityError } = await query;
      
      if (availabilityError) throw availabilityError;

      // Convert availability data to calendar events
      const calendarEvents = availabilityData?.map(availability => ({
        id: availability.id,
        title: `${availability.status}`,
        start: availability.start_date,
        end: availability.end_date,
        backgroundColor: getStatusColor(availability.status as AvailabilityStatus),
        classNames: [`status-${availability.status.toLowerCase()}`, 'event-content'],
        extendedProps: {
          status: availability.status,
          accommodationId: availability.accommodation_id
        }
      })) || [];

      setEvents(calendarEvents);
    } catch (err) {
      console.error('Error loading data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  const getStatusColor = (status: AvailabilityStatus): string => {
    switch (status) {
      case 'AVAILABLE': return '#10B981';
      case 'HOLD': return '#F59E0B';
      case 'BOOKED': return '#EF4444';
      default: return '#6B7280';
    }
  };

  const handleSelect = (selectInfo: any) => {
    setSelectedDates({
      start: selectInfo.start,
      end: selectInfo.end
    });
    setShowStatusModal(true);
  };

  const handleStatusSave = async (status: AvailabilityStatus) => {
    if (!selectedDates) return;

    try {
      setError(null);
      const accommodationId = selectedAccommodation === 'all' 
        ? accommodations[0].id 
        : selectedAccommodation;

      const { error: insertError } = await supabase
        .from('availability')
        .insert({
          accommodation_id: accommodationId,
          start_date: selectedDates.start.toISOString(),
          end_date: selectedDates.end.toISOString(),
          status
        });

      if (insertError) throw insertError;

      await loadData();
      setShowStatusModal(false);
      setSelectedDates(null);
    } catch (err) {
      console.error('Error saving availability:', err);
      setError(err instanceof Error ? err.message : 'Failed to save availability');
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      {error && (
        <div className="mb-4 p-4 bg-red-50 border-l-4 border-red-500 rounded">
          <p className="text-red-700">{error}</p>
        </div>
      )}

      <div className="mb-4 flex items-center gap-4">
        <select
          value={selectedAccommodation}
          onChange={(e) => setSelectedAccommodation(e.target.value)}
          className="p-2 border rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
        >
          <option value="all">All Accommodations</option>
          {accommodations.map((acc) => (
            <option key={acc.id} value={acc.id}>
              {acc.title}
            </option>
          ))}
        </select>

        <div className="flex items-center gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-gradient-to-r from-green-500 to-blue-500"></div>
            <span>Available</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-gradient-to-r from-yellow-500 to-blue-500"></div>
            <span>Hold</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-gradient-to-r from-red-500 to-blue-500"></div>
            <span>Booked</span>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center items-center h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-500"></div>
        </div>
      ) : (
        <div className="h-[600px]">
          <FullCalendar
            plugins={[dayGridPlugin, interactionPlugin]}
            initialView="dayGridMonth"
            events={events}
            selectable={true}
            select={handleSelect}
            headerToolbar={{
              left: 'prev,next today',
              center: 'title',
              right: 'dayGridMonth'
            }}
            height="100%"
            selectMirror={true}
            dayMaxEvents={true}
          />
        </div>
      )}

      {showStatusModal && (
        <StatusModal
          onClose={() => {
            setShowStatusModal(false);
            setSelectedDates(null);
          }}
          onSave={handleStatusSave}
        />
      )}
    </div>
  );
}