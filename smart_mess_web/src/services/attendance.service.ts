import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { Attendance } from '../types';

export const attendanceService = {
  subscribeToMealAttendance: (mealId: string, callback: (data: Attendance[]) => void) => {
    const q = query(collection(db, 'attendance'), where('mealId', '==', mealId));
    return onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Attendance));
      callback(data);
    });
  }
};
