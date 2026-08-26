export interface UserDocument {
  uid: string;
  email: string;
  name: string;
  role: 'student' | 'manager' | 'admin';
  status: 'active' | 'suspended';
  createdAt: string;
}

export interface StudentProfile {
  studentId: string;
  uid: string;
  name: string;
  email: string;
  messId: string;
  hostelId: string;
  roomNumber?: string;
  role: 'student';
}

export interface ManagerProfile {
  managerId: string;
  uid: string;
  name: string;
  email: string;
  messId: string;
  role: 'manager';
}

export interface Mess {
  messId: string;
  name: string;
  capacity: number;
}

export interface Hostel {
  hostelId: string;
  name: string;
}

export interface Meal {
  mealId: string;
  messId: string;
  type: 'breakfast' | 'lunch' | 'dinner';
  date: string;
  startTime: string;
  endTime: string;
  messOffDeadline: string;
  status: 'scheduled' | 'active' | 'completed';
}

export interface MessOff {
  messOffId: string;
  studentId: string;
  mealId: string;
  messId: string;
  date: string;
  status: 'active' | 'cancelled' | 'overridden';
  createdAt: string;
}

export interface MealAttendance {
  attendanceId: string;
  studentId: string;
  mealId: string;
  messId: string;
  scannedAt: string;
  status: 'attended';
}

export interface Prediction {
  predictionId: string;
  mealId: string;
  messId: string;
  date: string;
  type: 'breakfast' | 'lunch' | 'dinner';
  activeStudentsCount: number;
  messOffCount: number;
  dayOfWeek: number;
  events: string[];
  historicalAttendance: number[];
  predictedAttendance: number;
  confidenceInterval: [number, number];
  createdAt: string;
}

export interface FoodPreparation {
  prepId: string;
  mealId: string;
  messId: string;
  mlPrediction: number;
  recommendedQuantity: number;
  managerApprovedQuantity: number;
  approvedBy: string;
  approvedAt: string;
}

export interface Wastage {
  wastageId: string;
  mealId: string;
  messId: string;
  preparedQuantity: number;
  actualAttendance: number;
  wastedQuantity: number;
  enteredBy: string;
  enteredAt: string;
}

export interface Complaint {
  complaintId: string;
  studentId: string;
  messId: string;
  category: 'food_quality' | 'hygiene' | 'staff_behavior' | 'other';
  description: string;
  status: 'pending' | 'resolved';
  managerResponse?: string;
  createdAt: string;
  resolvedAt?: string;
  updatedAt?: string;
}

export interface Notification {
  notificationId: string;
  recipientUid: string;
  title: string;
  body: string;
  type: 'reminder' | 'update' | 'alert';
  read: boolean;
  createdAt: string;
  readAt?: string;
}

export interface Event {
  eventId: string;
  name: string;
  startDate: string;
  endDate: string;
  type: 'exam' | 'holiday' | 'special_dinner';
}

export interface Bill {
  billId: string;
  studentId: string;
  messId: string;
  month: string;
  baseFee: number;
  messOffDeductions: number;
  extraCharges: number;
  totalAmount: number;
  status: 'pending' | 'paid';
  createdAt: string;
}

export interface AuditLog {
  logId: string;
  actorUid: string;
  action: string;
  targetId: string;
  targetCollection: string;
  timestamp: string;
  metadata?: any;
  reason?: string;
}

export interface QRSession {
  sessionId: string;
  token: string;
  mealId: string;
  messId: string;
  expiresAt: string;
  createdBy: string;
  createdAt: string;
}
