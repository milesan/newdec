export interface ApplicationQuestion {
  id: string;
  order_number: number;
  text: string;
  type: 'text' | 'radio' | 'date' | 'email' | 'tel' | 'file' | 'textarea' | 'password';
  options?: string[];
  required: boolean;
  section?: string;
}

export interface ApplicationSection {
  id: string;
  title: string;
  description?: string;
  order: number;
}