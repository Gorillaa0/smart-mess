import React from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { TopBar } from './TopBar';
import { useAuthStore } from '../../store/authStore';

export const DashboardLayout: React.FC = () => {
  const { user, loading } = useAuthStore();

  if (loading) {
    return <div className="h-screen min-w-[1200px] flex items-center justify-center bg-gray-50">Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="flex h-screen min-w-[1200px] w-full overflow-hidden bg-gray-50">
      {/* Fixed Full Desktop Sidebar */}
      <Sidebar />
      
      {/* Desktop Main Workspace Area */}
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        <TopBar />
        <main className="flex-1 overflow-y-auto overflow-x-auto p-6 min-w-[940px]">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
