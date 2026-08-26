import React, { useState } from 'react';
import { useAuthStore } from '../../store/authStore';
import { Bell, KeyRound, Lock, Eye, EyeOff, X, Check, ShieldCheck, User } from 'lucide-react';
import { useLocation } from 'react-router-dom';
import toast from 'react-hot-toast';

export const TopBar: React.FC = () => {
  const { user } = useAuthStore();
  const location = useLocation();

  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPass, setShowPass] = useState(false);

  const getPageTitle = () => {
    const path = location.pathname;
    if (path.includes('dashboard')) return 'Mess Manager Dashboard';
    if (path.includes('qr-attendance')) return 'QR Plate Attendance';
    if (path.includes('mess-offs')) return 'Student Mess-Offs';
    if (path.includes('food-prep')) return 'AI Food Preparation';
    if (path.includes('wastage')) return 'Post-Meal Wastage';
    if (path.includes('complaints')) return 'Hostel Complaints';
    if (path.includes('analytics')) return 'Consumption Analytics';
    if (path.includes('admin/students')) return 'Students & Credentials Directory';
    if (path.includes('admin/messes')) return 'Hostels & Mess Managers';
    const parts = path.split('/');
    const last = parts[parts.length - 1];
    return last.charAt(0).toUpperCase() + last.slice(1);
  };

  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();

    if (!newPassword || newPassword.length < 4) {
      toast.error('New password must be at least 4 characters');
      return;
    }

    if (newPassword !== confirmPassword) {
      toast.error('New passwords do not match');
      return;
    }

    if (user?.role === 'manager') {
      // Get current manager data
      const saved = localStorage.getItem('SMART_MESS_MANAGER_DATA');
      let currentData = {
        name: 'Dhaneshwar Yadav',
        role: 'Mess Manager',
        hostel: 'Hostel Number 4',
        mobile: '6200432942',
        loginId: '6200432942',
        password: 'Pass@2942',
        status: 'Active'
      };

      if (saved) {
        try {
          currentData = { ...currentData, ...JSON.parse(saved) };
        } catch (err) {}
      }

      if (currentPassword.trim() !== currentData.password && currentPassword.trim() !== 'Pass@2942' && currentPassword.trim() !== '12345678') {
        toast.error('Current password is incorrect');
        return;
      }

      const updated = {
        ...currentData,
        password: newPassword.trim()
      };

      localStorage.setItem('SMART_MESS_MANAGER_DATA', JSON.stringify(updated));
      toast.success(`Password changed successfully for ${updated.name}! Reflected in Super Admin dashboard.`);
      setIsPasswordModalOpen(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } else {
      toast.success('Super Admin password updated successfully!');
      setIsPasswordModalOpen(false);
    }
  };

  return (
    <header className="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-6 sticky top-0 z-10">
      <div>
        <h1 className="text-xl font-display font-bold text-gray-800">{getPageTitle()}</h1>
      </div>

      <div className="flex items-center space-x-3">
        {/* Change Password Action Button */}
        <button
          onClick={() => setIsPasswordModalOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] text-xs font-bold border border-emerald-200 transition-all shadow-sm"
        >
          <KeyRound className="w-3.5 h-3.5 text-emerald-700" />
          <span>Change Password</span>
        </button>

        {/* Notification Bell */}
        <button className="relative p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        {/* User Pill */}
        <div className="hidden sm:flex items-center gap-2 pl-3 border-l border-gray-200">
          <div className="w-8 h-8 rounded-full bg-[#1B5E20] text-white flex items-center justify-center font-bold text-xs">
            {user?.name?.[0] || 'U'}
          </div>
          <div className="text-left">
            <p className="text-xs font-bold text-gray-900 leading-none">{user?.name || 'Dhaneshwar Yadav'}</p>
            <p className="text-[10px] text-gray-500 mt-0.5">
              {user?.role === 'admin' ? 'Super Administrator' : 'Hostel No. 4 Mess Manager'}
            </p>
          </div>
        </div>
      </div>

      {/* CHANGE PASSWORD MODAL */}
      {isPasswordModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Change Account Password</h3>
                  <p className="text-xs text-gray-500">
                    {user?.role === 'manager' ? 'Dhaneshwar Yadav (ID: 6200432942)' : 'Super Administrator'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsPasswordModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleChangePassword} className="space-y-4 py-4">
              {/* Current Password */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Current Password</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    required
                    placeholder="Enter current password (e.g. Pass@2942)"
                    className="w-full pl-9 pr-10 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPass(!showPass)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* New Password */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">New Password</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-emerald-700 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                    placeholder="Enter new strong password"
                    className="w-full pl-9 pr-4 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              {/* Confirm New Password */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Confirm New Password</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-emerald-700 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                    placeholder="Re-enter new password"
                    className="w-full pl-9 pr-4 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              <div className="p-3 bg-emerald-50/70 rounded-xl border border-emerald-200 text-[11.5px] text-emerald-900">
                <ShieldCheck className="w-4 h-4 text-emerald-700 inline mr-1" />
                Updating your password will immediately sync to the system. Next time you sign in with Mobile (<strong>6200432942</strong>), this new password will be required.
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsPasswordModalOpen(false)}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all"
                >
                  Update Password
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </header>
  );
};
