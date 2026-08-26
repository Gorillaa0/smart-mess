import { collection, getDocs, addDoc, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { Event } from '../types';

export const eventsService = {
  getEvents: async () => {
    const q = collection(db, 'events');
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Event));
  },
  createEvent: async (event: Omit<Event, 'id'>) => {
    const docRef = await addDoc(collection(db, 'events'), event);
    return { id: docRef.id, ...event };
  },
  deleteEvent: async (id: string) => {
    await deleteDoc(doc(db, 'events', id));
  }
};
