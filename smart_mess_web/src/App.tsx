import React, { useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { router } from './router';
import { auth, db } from './lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { useAuthStore } from './store/authStore';
import type { User } from './types';

const queryClient = new QueryClient();

export const App: React.FC = () => {
  const { setUser, setLoading } = useAuthStore();

  // 1. Maintain strict desktop scaling across all dynamic route changes and device rotations
  useEffect(() => {
    const applyDesktopViewport = () => {
      const screenW = window.screen.width || window.innerWidth || 1280;
      const targetScale = Math.min(1, screenW / 1280);
      const safeScale = targetScale > 0.2 ? targetScale : 0.25;

      let meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        document.head.appendChild(meta);
      }
      meta.setAttribute(
        'content',
        `width=1280, initial-scale=${safeScale}, minimum-scale=0.1, maximum-scale=5.0, user-scalable=yes`
      );
    };

    applyDesktopViewport();
    window.addEventListener('resize', applyDesktopViewport);
    window.addEventListener('orientationchange', applyDesktopViewport);
    return () => {
      window.removeEventListener('resize', applyDesktopViewport);
      window.removeEventListener('orientationchange', applyDesktopViewport);
    };
  }, []);

  // 2. Auth session restoration
  useEffect(() => {
    try {
      const saved = localStorage.getItem('SMART_MESS_AUTH_USER');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed && parsed.role) {
          setUser(parsed);
          setLoading(false);
        }
      }
    } catch (err) {
      console.error('Error reading localStorage session:', err);
    }

    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid));
          if (userDoc.exists()) {
            setUser({ ...userDoc.data(), uid: firebaseUser.uid } as User);
          }
        } catch (error) {
          console.error("Error fetching user role:", error);
        }
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [setUser, setLoading]);

  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
      <Toaster position="top-right" />
    </QueryClientProvider>
  );
};
