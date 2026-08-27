import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import { useMessStore } from '../../store/messStore';
import { 
  LayoutDashboard, Utensils, QrCode, CalendarOff, 
  TrendingUp, ChefHat, Trash2, MessageSquare, 
  Bell, BarChart3, Users, Building, Calendar, LogOut
} from 'lucide-react';
import { auth } from '../../lib/firebase';
import clsx from 'clsx';

export const Sidebar: React.FC = () => {
  const { user } = useAuthStore();
  const { currentMess } = useMessStore();
  const navigate = useNavigate();

  const managerLinks = [
    { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/meals', icon: Utensils, label: 'Meals' },
    { to: '/qr-attendance', icon: QrCode, label: 'QR Attendance' },
    { to: '/attendance-ledger', icon: Users, label: 'Student Attendance' },
    { to: '/mess-offs', icon: CalendarOff, label: 'Mess-Offs' },
    { to: '/food-prep', icon: ChefHat, label: 'Food Prep' },
    { to: '/wastage', icon: Trash2, label: 'Wastage' },
    { to: '/complaints', icon: MessageSquare, label: 'Complaints' },
    { to: '/notifications', icon: Bell, label: 'Notifications' },
    { to: '/analytics', icon: BarChart3, label: 'Analytics' },
  ];

  const adminLinks = [
    { to: '/notifications', icon: Bell, label: 'Broadcasts & Notices' },
    { to: '/admin/complaints', icon: MessageSquare, label: 'Hostel Complaints' },
    { to: '/admin/events', icon: Calendar, label: 'Events' },
    { to: '/admin/students', icon: Users, label: 'Students' },
    { to: '/admin/hostels', icon: Building, label: 'Hostels' },
    { to: '/admin/messes', icon: Building, label: 'Messes' },
    { to: '/admin/analytics', icon: BarChart3, label: 'System Analytics' },
  ];

  const links = user?.role === 'admin' ? adminLinks : managerLinks;

  const handleLogout = async () => {
    await auth.signOut();
    navigate('/login');
  };

  return (
    <div className="flex flex-col h-screen w-64 bg-primary-900 text-white shrink-0">
      <div className="p-4 flex items-center space-x-3 border-b border-primary-800">
        <Utensils className="w-8 h-8 text-primary-300" />
        <span className="text-xl font-display font-bold">Smart Mess</span>
      </div>
      
      <div className="flex-1 overflow-y-auto py-4 space-y-1">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            className={({ isActive }) => clsx(
              'flex items-center px-4 py-3 text-sm font-medium transition-colors',
              isActive ? 'bg-primary-800 border-r-4 border-primary-400' : 'hover:bg-primary-800/50'
            )}
          >
            <link.icon className="w-5 h-5 mr-3 shrink-0" />
            {link.label}
          </NavLink>
        ))}
      </div>

      <div className="p-4 border-t border-primary-800 bg-primary-950">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 rounded-full bg-primary-700 flex items-center justify-center font-bold">
            {user?.name?.[0] || 'U'}
          </div>
          <div className="flex-1 overflow-hidden">
            <p className="text-sm font-medium truncate">{user?.name}</p>
            <p className="text-xs text-primary-300 truncate">
              {user?.role === 'manager' ? currentMess?.name : 'Administrator'}
            </p>
          </div>
        </div>
        <button 
          onClick={handleLogout}
          className="w-full flex items-center px-3 py-2 text-sm text-primary-200 hover:bg-primary-800 rounded transition-colors"
        >
          <LogOut className="w-4 h-4 mr-2" />
          Logout
        </button>
      </div>
    </div>
  );
};
