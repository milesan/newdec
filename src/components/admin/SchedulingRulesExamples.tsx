import React from 'react';
import { supabase } from '../../lib/supabase';

export async function addExampleRules() {
  // Block November completely
  await supabase.from('scheduling_rules').insert({
    start_date: '2024-11-01',
    end_date: '2024-11-30',
    is_blocked: true
  });

  // December with Mon/Tues arrival/departure
  await supabase.from('scheduling_rules').insert({
    start_date: '2024-12-01',
    end_date: '2024-12-31',
    arrival_day: 'monday',
    departure_day: 'tuesday'
  });

  // Block specific dates in April
  await supabase.from('scheduling_rules').insert({
    start_date: '2024-04-01',
    end_date: '2024-04-30',
    blocked_dates: [
      '2024-04-10',
      '2024-04-11',
      '2024-04-12',
      '2024-04-13',
      '2024-04-14'
    ]
  });

  // January onwards with Tuesday/Monday pattern
  await supabase.from('scheduling_rules').insert({
    start_date: '2024-01-07',
    end_date: '2024-12-31',
    arrival_day: 'tuesday',
    departure_day: 'monday'
  });
}