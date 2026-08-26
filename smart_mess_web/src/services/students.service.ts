import { collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { User } from '../types';

export const studentsService = {
  getStudents: async () => {
    const q = collection(db, 'users'); // Note: add where role == student if needed
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as User));
  },
  updateStudent: async (id: string, data: Partial<User>) => {
    await updateDoc(doc(db, 'users', id), data);
  }
};
