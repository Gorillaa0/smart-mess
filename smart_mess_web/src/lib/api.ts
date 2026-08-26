/**
 * Smart Mess Backend API Client
 * Replaces Firebase Cloud Functions httpsCallable calls.
 * Points to the Express.js backend running on Google Cloud Run.
 */
import { auth } from './firebase';

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3001';

async function getAuthHeaders(): Promise<HeadersInit> {
  const token = await auth.currentUser?.getIdToken();
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

async function post<T = any>(path: string, body: Record<string, any>): Promise<T> {
  const headers = await getAuthHeaders();
  const res = await fetch(`${BACKEND_URL}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || `Request failed: ${res.status}`);
  return data as T;
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
export const api = {
  // Admin: create a single student account
  createStudent: (payload: { email: string; name: string; studentId: string; messId: string; hostelId: string; roomNumber?: string }) =>
    post('/auth/createStudent', payload),

  // Admin: create a mess manager account
  createManager: (payload: { email: string; name: string; managerId: string; messId: string }) =>
    post('/auth/createManager', payload),

  // Admin: bulk import students from CSV data
  importStudentsCSV: (students: any[]) =>
    post('/auth/importStudentsCSV', { students }),

  // Admin: activate or suspend a user
  setUserStatus: (uid: string, status: 'active' | 'suspended') =>
    post('/auth/setUserStatus', { uid, status }),

  // ─── Meals ─────────────────────────────────────────────────────────────────
  createMeal: (payload: { messId: string; type: string; date: string; startTime: string; endTime: string; messOffDeadline: string }) =>
    post('/meals/createMeal', payload),

  generateQR: (mealId: string, messId: string) =>
    post('/meals/generateQR', { mealId, messId }),

  verifyQR: (token: string, mealId: string, sessionId: string) =>
    post('/meals/verifyQR', { token, mealId, sessionId }),

  // ─── Mess-Off ──────────────────────────────────────────────────────────────
  markMessOff: (mealId: string) =>
    post('/messoff/mark', { mealId }),

  cancelMessOff: (messOffId: string) =>
    post('/messoff/cancel', { messOffId }),

  // ─── Prediction ────────────────────────────────────────────────────────────
  triggerPrediction: (mealId: string) =>
    post('/prediction/trigger', { mealId }),

  approvePrediction: (predictionId: string, managerApprovedQuantity: number) =>
    post('/prediction/approve', { predictionId, managerApprovedQuantity }),

  // ─── Wastage ───────────────────────────────────────────────────────────────
  enterWastage: (mealId: string, wastedQuantity: number) =>
    post('/wastage/enter', { mealId, wastedQuantity }),

  // ─── Billing ───────────────────────────────────────────────────────────────
  calculateBilling: (messId: string, month: string) =>
    post('/billing/calculate', { messId, month }),
};
