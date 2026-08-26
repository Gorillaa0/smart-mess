import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AuthLayout } from '../components/layout/AuthLayout';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { LoginPage } from '../pages/auth/LoginPage';
import { DashboardPage } from '../pages/manager/DashboardPage';
import { QRAttendancePage } from '../pages/manager/QRAttendancePage';
import { AttendanceLedgerPage } from '../pages/manager/AttendanceLedgerPage';
import { MealsPage } from '../pages/manager/MealsPage';
import { MessOffsPage } from '../pages/manager/MessOffsPage';
import { ComplaintsPage } from '../pages/manager/ComplaintsPage';
import { AnalyticsPage } from '../pages/manager/AnalyticsPage';
import { StudentsPage } from '../pages/admin/StudentsPage';
import { MessesPage } from '../pages/admin/MessesPage';
import { HostelsPage } from '../pages/admin/HostelsPage';
import { EventsPage } from '../pages/admin/EventsPage';
import { WastagePage, NotificationsPage, FoodPrepPage, SystemAnalyticsPage } from '../pages/manager/OtherPages';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Navigate to="/dashboard" replace />
  },
  {
    element: <AuthLayout />,
    children: [
      { path: 'login', element: <LoginPage /> }
    ]
  },
  {
    element: <DashboardLayout />,
    children: [
      // Manager Routes
      { path: 'dashboard', element: <DashboardPage /> },
      { path: 'meals', element: <MealsPage /> },
      { path: 'qr-attendance', element: <QRAttendancePage /> },
      { path: 'attendance-ledger', element: <AttendanceLedgerPage /> },
      { path: 'mess-offs', element: <MessOffsPage /> },
      { path: 'food-prep', element: <FoodPrepPage /> },
      { path: 'wastage', element: <WastagePage /> },
      { path: 'complaints', element: <ComplaintsPage /> },
      { path: 'notifications', element: <NotificationsPage /> },
      { path: 'analytics', element: <AnalyticsPage /> },
      
      // Admin Routes
      { path: 'admin/messes', element: <MessesPage /> },
      { path: 'admin/students', element: <StudentsPage /> },
      { path: 'admin/hostels', element: <HostelsPage /> },
      { path: 'admin/events', element: <EventsPage /> },
      { path: 'admin/analytics', element: <SystemAnalyticsPage /> }
    ]
  },
  {
    path: '*',
    element: <div className="flex h-screen items-center justify-center">404 - Not Found</div>
  }
]);
