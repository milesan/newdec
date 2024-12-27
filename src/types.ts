export interface Accommodation {
  id: string;
  title: string;
  location: string;
  price: number;
  rating: number;
  reviews: number;
  imageUrl: string;
  type: string;
  beds: number;
  bathrooms: number;
  superhost: boolean;
  inventory_count: number;
  is_fungible?: boolean;
  is_unlimited?: boolean;
  parent_accommodation_id?: string | null;
}

export interface CabinRates {
  [key: string]: number;
}

export interface Week {
  date: Date;
  isSelected: boolean;
  isFirstWeek: boolean;
  isLastWeek: boolean;
}