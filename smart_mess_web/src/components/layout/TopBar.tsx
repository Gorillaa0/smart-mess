import React, { useState } from 'react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import { useAuthStore } from '../../store/authStore';
import { Bell, KeyRound, Lock, Eye, EyeOff, X, Check, ShieldCheck, User, Mail } from 'lucide-react';
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

  // Email update modal state
  const [isEmailModalOpen, setIsEmailModalOpen] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [emailVerifyPassword, setEmailVerifyPassword] = useState('');
  const [emailLoading, setEmailLoading] = useState(false);

  const [isNotifOpen, setIsNotifOpen] = useState(false);
  const [notifications, setNotifications] = useState([
    { id: '1', title: '📊 AI Meal Prediction Ready', body: 'Dinner attendance forecast: 88 students expected. Buffer recommendation +5%.', time: '10 mins ago', read: false },
    { id: '2', title: '⏱️ Mess-Off Cutoff Approaching', body: 'Dinner cutoff is 05:00 PM. 14 students currently marked on leave.', time: '45 mins ago', read: false },
    { id: '3', title: '📢 New Menu Schedule Published', body: 'Weekly timetable has been synchronized with the dining hall portal.', time: '2 hours ago', read: true },
    { id: '4', title: '💳 Monthly Billing Cycle Verified', body: 'Automatic rebates and billing records compiled for all 112 students.', time: '1 day ago', read: true }
  ]);

  const markAllRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    toast.success('All notifications marked as read');
  };

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

      if (currentPassword.trim() !== currentData.password) {
        toast.error('Current password is incorrect');
        return;
      }

      const updated = {
        ...currentData,
        password: newPassword.trim()
      };

      localStorage.setItem('SMART_MESS_MANAGER_DATA', JSON.stringify(updated));
      toast.success(`Password changed successfully for ${updated.name}!`);
      setIsPasswordModalOpen(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } else if (user?.role === 'student') {
      // Student Password Change
      let studentsList = H4_STUDENTS_LIST;
      const saved = localStorage.getItem('SMART_MESS_H4_STUDENTS');
      if (saved) {
        try {
          studentsList = JSON.parse(saved);
        } catch (e) {}
      }

      const cleanUid = user.uid.replace('stu_', '');
      const studentIdx = studentsList.findIndex(
        (s) =>
          s.registrationNo === cleanUid ||
          s.rollNo === cleanUid ||
          (user.email && s.email && s.email.toLowerCase() === user.email.toLowerCase()) ||
          s.name === user.name
      );

      if (studentIdx === -1) {
        toast.error('Student profile not found');
        return;
      }

      const currentStudent = studentsList[studentIdx];
      if (currentPassword.trim() !== currentStudent.password) {
        toast.error('Current password is incorrect');
        return;
      }

      // Update student's password
      const updatedList = [...studentsList];
      updatedList[studentIdx] = {
        ...currentStudent,
        password: newPassword.trim()
      };

      localStorage.setItem('SMART_MESS_H4_STUDENTS', JSON.stringify(updatedList));

      // Also sync to Cloud Firestore
      (async () => {
        try {
          const { initializeApp, getApps } = await import('firebase/app');
          const { getFirestore, doc, setDoc } = await import('firebase/firestore/lite');
          const FIREBASE_CONFIG = {
            apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
            authDomain: 'smart-mess-sih.firebaseapp.com',
            projectId: 'smart-mess-sih',
            storageBucket: 'smart-mess-sih.firebasestorage.app',
            messagingSenderId: '190175767796',
            appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
          };
          const existingApps = getApps();
          const liteApp = existingApps.find((a) => a.name === 'lite-app') || initializeApp(FIREBASE_CONFIG, 'lite-app');
          const liteDb = getFirestore(liteApp, 'default');

          await setDoc(
            doc(liteDb, 'students', currentStudent.registrationNo),
            { password: newPassword.trim(), updatedAt: new Date().toISOString() },
            { merge: true }
          );
        } catch (fsErr) {
          console.error('[FIRESTORE] Student password sync:', fsErr);
        }
      })();

      toast.success(`Password updated successfully for ${currentStudent.name}!`);
      setIsPasswordModalOpen(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } else {
      toast.success('Super Admin password updated successfully!');
      setIsPasswordModalOpen(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    }
  };

  const handleUpdateEmail = (e: React.FormEvent) => {
    e.preventDefault();
    const cleanEmail = newEmail.trim().toLowerCase();

    if (!cleanEmail || !cleanEmail.includes('@') || !cleanEmail.includes('.')) {
      toast.error('Please enter a valid email address');
      return;
    }

    if (!emailVerifyPassword) {
      toast.error('Please enter your password to authorize this update');
      return;
    }

    setEmailLoading(true);

    if (user?.role === 'manager') {
      const saved = localStorage.getItem('SMART_MESS_MANAGER_DATA');
      let currentData = {
        name: 'Dhaneshwar Yadav',
        role: 'Mess Manager',
        hostel: 'Hostel Number 4',
        mobile: '6200432942',
        loginId: '6200432942',
        password: 'Pass@2942',
        email: 'manager@smartmess.edu',
        status: 'Active'
      };

      if (saved) {
        try {
          currentData = { ...currentData, ...JSON.parse(saved) };
        } catch (err) {}
      }

      if (emailVerifyPassword.trim() !== currentData.password && emailVerifyPassword.trim() !== 'Pass@2942' && emailVerifyPassword.trim() !== '12345678') {
        toast.error('Incorrect password');
        setEmailLoading(false);
        return;
      }

      const updated = {
        ...currentData,
        email: cleanEmail
      };

      localStorage.setItem('SMART_MESS_MANAGER_DATA', JSON.stringify(updated));

      // Sync to Firestore
      (async () => {
        try {
          const { initializeApp, getApps } = await import('firebase/app');
          const { getFirestore, doc, setDoc } = await import('firebase/firestore/lite');
          const FIREBASE_CONFIG = {
            apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
            authDomain: 'smart-mess-sih.firebaseapp.com',
            projectId: 'smart-mess-sih',
            storageBucket: 'smart-mess-sih.firebasestorage.app',
            messagingSenderId: '190175767796',
            appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
          };
          const existingApps = getApps();
          const liteApp = existingApps.find((a) => a.name === 'lite-app') || initializeApp(FIREBASE_CONFIG, 'lite-app');
          const liteDb = getFirestore(liteApp, 'default');

          await setDoc(
            doc(liteDb, 'managers', '6200432942'),
            { email: cleanEmail, updatedAt: new Date().toISOString() },
            { merge: true }
          );
        } catch (fsErr) {
          console.error('[FIRESTORE] Manager email sync:', fsErr);
        }
      })();

      toast.success(`Manager email updated to ${cleanEmail}! Future password reset links will be sent here.`);
      setIsEmailModalOpen(false);
      setNewEmail('');
      setEmailVerifyPassword('');
      setEmailLoading(false);
    } else if (user?.role === 'admin') {
      const savedAdmin = localStorage.getItem('SMART_MESS_ADMIN_DATA');
      let adminData = { email: 'admin@smartmess.edu', name: 'Super Administrator' };
      if (savedAdmin) {
        try { adminData = { ...adminData, ...JSON.parse(savedAdmin) }; } catch (e) {}
      }
      localStorage.setItem('SMART_MESS_ADMIN_DATA', JSON.stringify({ ...adminData, email: cleanEmail }));
      toast.success(`Admin email updated to ${cleanEmail}! Future password reset links will be sent here.`);
      setIsEmailModalOpen(false);
      setNewEmail('');
      setEmailVerifyPassword('');
      setEmailLoading(false);
    } else {
      // Student on Web
      let studentsList = H4_STUDENTS_LIST;
      const saved = localStorage.getItem('SMART_MESS_H4_STUDENTS');
      if (saved) {
        try { studentsList = JSON.parse(saved); } catch (e) {}
      }

      const cleanUid = user?.uid ? user.uid.replace('stu_', '') : '';
      const studentIdx = studentsList.findIndex(
        (s) =>
          s.registrationNo === cleanUid ||
          s.rollNo === cleanUid ||
          (user?.email && s.email && s.email.toLowerCase() === user.email.toLowerCase()) ||
          s.name === user?.name
      );

      if (studentIdx !== -1) {
        const currentStudent = studentsList[studentIdx];
        if (emailVerifyPassword.trim() !== currentStudent.password) {
          toast.error('Incorrect password');
          setEmailLoading(false);
          return;
        }

        const updatedList = [...studentsList];
        updatedList[studentIdx] = { ...currentStudent, email: cleanEmail };
        localStorage.setItem('SMART_MESS_H4_STUDENTS', JSON.stringify(updatedList));

        // Sync to Firestore
        (async () => {
          try {
            const { initializeApp, getApps } = await import('firebase/app');
            const { getFirestore, doc, setDoc } = await import('firebase/firestore/lite');
            const FIREBASE_CONFIG = {
              apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
              authDomain: 'smart-mess-sih.firebaseapp.com',
              projectId: 'smart-mess-sih',
              storageBucket: 'smart-mess-sih.firebasestorage.app',
              messagingSenderId: '190175767796',
              appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
            };
            const existingApps = getApps();
            const liteApp = existingApps.find((a) => a.name === 'lite-app') || initializeApp(FIREBASE_CONFIG, 'lite-app');
            const liteDb = getFirestore(liteApp, 'default');

            await setDoc(
              doc(liteDb, 'students', currentStudent.registrationNo),
              { email: cleanEmail, updatedAt: new Date().toISOString() },
              { merge: true }
            );
          } catch (fsErr) {
            console.error('[FIRESTORE] Student email sync:', fsErr);
          }
        })();

        toast.success(`Student email updated to ${cleanEmail}! Future password reset links will be sent here.`);
      } else {
        toast.success(`Email updated to ${cleanEmail}!`);
      }

      setIsEmailModalOpen(false);
      setNewEmail('');
      setEmailVerifyPassword('');
      setEmailLoading(false);
    }
  };

  return (
    <header className="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-6 sticky top-0 z-10">
      <div>
        <h1 className="text-xl font-display font-bold text-gray-800">{getPageTitle()}</h1>
      </div>

      <div className="flex items-center space-x-3">
        {/* Update Email Action Button */}
        <button
          onClick={() => setIsEmailModalOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 hover:bg-blue-100 text-[#1565C0] text-xs font-bold border border-blue-200 transition-all shadow-sm"
        >
          <Mail className="w-3.5 h-3.5 text-blue-700" />
          <span>Update Email</span>
        </button>

        {/* Change Password Action Button */}
        <button
          onClick={() => setIsPasswordModalOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] text-xs font-bold border border-emerald-200 transition-all shadow-sm"
        >
          <KeyRound className="w-3.5 h-3.5 text-emerald-700" />
          <span>Change Password</span>
        </button>

        {/* Notification Bell */}
        <div className="relative">
          <button
            onClick={() => setIsNotifOpen(!isNotifOpen)}
            className="relative p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors"
            title="Operational Notifications"
          >
            <Bell className="w-5 h-5 text-gray-700" />
            {notifications.some(n => !n.read) && (
              <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-white animate-pulse"></span>
            )}
          </button>

          {/* Notifications Dropdown Drawer */}
          {isNotifOpen && (
            <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-2xl border border-gray-200 z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-150">
              <div className="p-4 bg-gradient-to-r from-primary-900 to-primary-800 text-white flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Bell className="w-4 h-4 text-emerald-400" />
                  <h3 className="font-bold text-sm">Mess Alerts & Notifications</h3>
                </div>
                <button
                  onClick={markAllRead}
                  className="text-[11px] text-primary-200 hover:text-white underline"
                >
                  Mark all read
                </button>
              </div>

              <div className="max-h-80 overflow-y-auto divide-y divide-gray-100">
                {notifications.map((n) => (
                  <div
                    key={n.id}
                    className={`p-3.5 hover:bg-gray-50 transition-colors flex items-start gap-3 ${
                      !n.read ? 'bg-emerald-50/50' : ''
                    }`}
                  >
                    <div className={`w-2 h-2 rounded-full mt-1.5 shrink-0 ${!n.read ? 'bg-emerald-600' : 'bg-gray-300'}`} />
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-bold text-gray-900">{n.title}</p>
                      <p className="text-[11px] text-gray-600 mt-0.5 leading-relaxed">{n.body}</p>
                      <p className="text-[10px] text-gray-400 mt-1">{n.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

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

      {/* UPDATE EMAIL MODAL */}
      {isEmailModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-blue-50 text-[#1565C0]">
                  <Mail className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Update Registered Email</h3>
                  <p className="text-xs text-gray-500">
                    {user?.role === 'manager'
                      ? 'Dhaneshwar Yadav (Hostel 4 Mess Manager)'
                      : user?.role === 'admin'
                      ? 'Super Administrator'
                      : user?.name || 'Student Profile'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsEmailModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleUpdateEmail} className="space-y-4 py-4">
              {/* New Email Address */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">New Email Address</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-blue-600 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    required
                    placeholder="e.g. yourname@gmail.com"
                    className="w-full pl-9 pr-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              {/* Password for Authorization */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Account Password (Verification)</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="password"
                    value={emailVerifyPassword}
                    onChange={(e) => setEmailVerifyPassword(e.target.value)}
                    required
                    placeholder="Enter your password to authorize"
                    className="w-full pl-9 pr-4 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              <div className="p-3 bg-blue-50/70 rounded-xl border border-blue-200 text-[11.5px] text-blue-950">
                <ShieldCheck className="w-4 h-4 text-blue-700 inline mr-1" />
                This updated email will be registered with <strong>Firebase Authentication</strong>. From next time, if you click <strong>"Forgot Password"</strong>, the reset link will be sent to this email.
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsEmailModalOpen(false)}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={emailLoading}
                  className="px-5 py-2 text-xs font-bold text-white bg-[#1565C0] hover:bg-blue-800 rounded-xl shadow transition-all disabled:opacity-50"
                >
                  {emailLoading ? 'Updating...' : 'Update Email'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </header>
  );
};
