import { create } from 'zustand';
import type { Mess } from '../types';

interface MessState {
  currentMess: Mess | null;
  setCurrentMess: (mess: Mess | null) => void;
}

export const useMessStore = create<MessState>((set) => ({
  currentMess: null,
  setCurrentMess: (mess) => set({ currentMess: mess }),
}));
