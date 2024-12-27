export type AvailabilityStatus = 'AVAILABLE' | 'BOOKED' | 'HOLD';

export interface Event {
  id: string;
  title: string;
  start: string;
  end: string;
  backgroundColor: string;
  borderColor: string;
  classNames: string[];
  extendedProps: {
    type: 'availability';
    status: AvailabilityStatus;
    accommodationId: string;
  };
}