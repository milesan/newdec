export interface SchedulingRule {
  id: string;
  start_date: string;
  end_date: string;
  arrival_day: string | null;
  departure_day: string | null;
  is_blocked: boolean;
  blocked_dates: string[];
  created_at: string;
  updated_at: string;
}