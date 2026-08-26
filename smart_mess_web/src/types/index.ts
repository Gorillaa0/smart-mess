export const TypesVersion = '1.0.0';

export type Role = 'manager' | 'admin' | 'student';

export interface User {
  uid: string;
  email: string;
  role: Role;
  name?: string;
  messId?: string;
}

export interface Mess {
  id: string;
  name: string;
  capacity: number;
}

export interface Meal {
  id: string;
  messId: string;
  type: 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack';
  date: string; // YYYY-MM-DD
  dayOfWeek?: string;
  items?: string;
  startTime: string; // HH:mm
  endTime: string; // HH:mm
  messOffDeadline: string; // HH:mm or ISO string
  status: 'scheduled' | 'active' | 'completed';
}

export interface MessOff {
  id: string;
  userId: string;
  userName: string;
  mealId: string;
  requestedAt: string;
  status: 'active' | 'cancelled' | 'overridden';
}

export interface Attendance {
  id: string;
  userId: string;
  userName: string;
  mealId: string;
  timestamp: string;
}

export interface Prediction {
  id: string;
  mealId: string;
  predictedCount: number;
  confidence: number;
  generatedAt: string;
  approvedCount?: number;
}

export interface Complaint {
  id: string;
  userId: string;
  messId: string;
  title: string;
  description: string;
  category: string;
  status: 'Pending' | 'In Progress' | 'Resolved';
  createdAt: string;
  response?: string;
}

export interface Event {
  id: string;
  title: string;
  type: 'exam' | 'holiday' | 'festival' | 'event';
  startDate: string;
  endDate: string;
  impactLevel: 'low' | 'medium' | 'high';
  description?: string;
}
