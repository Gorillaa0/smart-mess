import { create } from 'zustand';
import type { User } from '../types';

interface AuthState {
  user: User | null;
  loading: boolean;
  setUser: (user: User | null) => void;
  setLoading: (loading: boolean) => void;
  logout: () => void;
}

const getInitialUser = (): User | null => {
  try {
    const saved = localStorage.getItem('SMART_MESS_AUTH_USER');
    if (saved) {
      return JSON.parse(saved);
    }
  } catch (e) {
    console.error('Error restoring auth session from localStorage:', e);
  }
  return null;
};

const initialUser = getInitialUser();

export const useAuthStore = create<AuthState>((set) => ({
  user: initialUser,
  loading: false,
  setUser: (user) => {
    try {
      if (user) {
        localStorage.setItem('SMART_MESS_AUTH_USER', JSON.stringify(user));
      } else {
        localStorage.removeItem('SMART_MESS_AUTH_USER');
      }
    } catch (e) {
      console.error('Error saving user to localStorage:', e);
    }
    set({ user, loading: false });
  },
  setLoading: (loading) => set({ loading }),
  logout: () => {
    try {
      localStorage.removeItem('SMART_MESS_AUTH_USER');
    } catch (_) {}
    set({ user: null, loading: false });
  }
}));
