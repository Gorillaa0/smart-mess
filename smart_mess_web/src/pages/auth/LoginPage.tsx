import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import { Mail, Lock, Eye, EyeOff, Shield, ArrowRight, Utensils, User, KeyRound, X, CheckCircle2 } from 'lucide-react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import { auth } from '../../lib/firebase';
import { sendPasswordResetEmail, signInWithEmailAndPassword } from 'firebase/auth';
import toast from 'react-hot-toast';

export const LoginPage: React.FC = () => {
  const [identifier, setIdentifier] = useState('6200432942'); // Default: Dhaneshwar Yadav
  const [password, setPassword] = useState('Pass@2942');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { setUser } = useAuthStore();

  // Email & Direct In-App Forgot Password Modal State
  const [isForgotModalOpen, setIsForgotModalOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState('');
  const [resetStep, setResetStep] = useState<1 | 2>(1);
  const [verifiedStudent, setVerifiedStudent] = useState<H4Student | null>(null);
  const [verifyRegNo, setVerifyRegNo] = useState('');
  const [newResetPassword, setNewResetPassword] = useState('');
  const [resetLoading, setResetLoading] = useState(false);
  const [resetSuccessMessage, setResetSuccessMessage] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const cleanId = identifier.trim().toLowerCase();
    const cleanPass = password.trim();

    await new Promise((resolve) => setTimeout(resolve, 400));

    // 1. Check if Super Admin
    if (cleanId === 'admin@smartmess.edu' || cleanId === 'admin') {
      if (cleanPass === 'Admin@1234' || cleanPass === '12345678' || cleanPass === 'admin') {
        setUser({
          uid: 'admin_master_01',
          email: 'admin@smartmess.edu',
          name: 'Super Administrator',
          role: 'admin'
        });
        toast.success('Welcome Super Admin');
        setLoading(false);
        navigate('/admin/students');
        return;
      } else {
        toast.error('Incorrect Super Admin password');
        setLoading(false);
        return;
      }
    }

    // 2. Check if Mess Manager Dhaneshwar Yadav (Mobile: 6200432942)
    const savedManager = localStorage.getItem('SMART_MESS_MANAGER_DATA');
    let managerPass = 'Pass@2942';
    let managerMobile = '6200432942';
    let managerName = 'Dhaneshwar Yadav';

    if (savedManager) {
      try {
        const parsed = JSON.parse(savedManager);
        managerPass = parsed.password || managerPass;
        managerMobile = parsed.mobile || managerMobile;
        managerName = parsed.name || managerName;
      } catch (err) {
        console.error(err);
      }
    }

    if (
      cleanId === managerMobile.toLowerCase() ||
      cleanId === '6200432942' ||
      cleanId === 'manager@smartmess.edu' ||
      cleanId === 'dhaneshwar' ||
      cleanId === 'manager'
    ) {
      if (cleanPass === managerPass || cleanPass === 'DY@2942' || cleanPass === 'Pass@2942' || cleanPass === '12345678') {
        setUser({
          uid: 'mgr_dhaneshwar_01',
          email: `${managerMobile}@smartmess.edu`,
          name: `${managerName} (Mess Manager)`,
          role: 'manager',
          messId: 'mess_h4'
        });
        toast.success(`Welcome ${managerName} (Mess Manager)`);
        setLoading(false);
        navigate('/dashboard');
        return;
      } else {
        toast.error('Incorrect password for Mess Manager Dhaneshwar Yadav');
        setLoading(false);
        return;
      }
    }

    // 3. Check Student Roster
    let studentsList = H4_STUDENTS_LIST;
    const savedStudents = localStorage.getItem('SMART_MESS_H4_STUDENTS');
    if (savedStudents) {
      try {
        studentsList = JSON.parse(savedStudents);
      } catch (e) {
        console.error(e);
      }
    }

    const student = studentsList.find(
      (s) =>
        s.registrationNo.toLowerCase() === cleanId ||
        s.rollNo.toLowerCase() === cleanId ||
        s.mobile === cleanId ||
        (s.email && s.email.toLowerCase() === cleanId)
    );

    // If identifier is an email or student has an email: check Firebase Auth first
    const targetEmail = student?.email || (cleanId.includes('@') ? cleanId : null);
    if (targetEmail) {
      try {
        const userCredential = await signInWithEmailAndPassword(auth, targetEmail, cleanPass);
        const loggedStudent = student || {
          name: userCredential.user.displayName || targetEmail.split('@')[0],
          registrationNo: userCredential.user.uid.slice(0, 11),
          roomNo: '101'
        };
        toast.success(`Welcome ${loggedStudent.name}!`);
        setUser({
          uid: userCredential.user.uid,
          email: targetEmail,
          name: loggedStudent.name,
          role: 'student' as any
        });
        setLoading(false);
        navigate('/dashboard');
        return;
      } catch (firebaseErr: any) {
        console.log('[AUTH] Firebase Auth login attempt result:', firebaseErr.code);
        // If the account exists in Firebase Auth but password was wrong -> REJECT (old password is invalid!)
        if (firebaseErr.code === 'auth/wrong-password' || firebaseErr.code === 'auth/invalid-credential') {
          toast.error(`❌ Incorrect password for ${student ? student.name : cleanId}. Please enter your new updated password.`);
          setLoading(false);
          return;
        }
        // If user is not yet created in Firebase Auth -> allow initial password from roster
        if (firebaseErr.code === 'auth/user-not-found') {
          if (student && cleanPass === student.password) {
            toast.success(`Welcome ${student.name} (Room ${student.roomNo})`);
            setUser({
              uid: `stu_${student.registrationNo}`,
              email: `${student.registrationNo}@smartmess.edu`,
              name: student.name,
              role: 'student' as any
            });
            setLoading(false);
            navigate('/dashboard');
            return;
          }
        }
      }
    }

    if (student) {
      if (cleanPass === student.password) {
        toast.success(`Welcome ${student.name} (Room ${student.roomNo})`);
        setUser({
          uid: `stu_${student.registrationNo}`,
          email: `${student.registrationNo}@smartmess.edu`,
          name: student.name,
          role: 'student' as any
        });
        setLoading(false);
        navigate('/dashboard');
        return;
      } else {
        toast.error(`Incorrect password for student ${student.name}`);
        setLoading(false);
        return;
      }
    }

    toast.error('Invalid ID / Mobile number or Password. Please try again.');
    setLoading(false);
  };

  const handlePasswordResetStep1 = async (e: React.FormEvent) => {
    e.preventDefault();
    const queryStr = resetEmail.trim().toLowerCase();

    if (!queryStr) {
      toast.error('Please enter your registered Email or Registration Number');
      return;
    }

    setResetLoading(true);

    // 1. Look up student in roster
    let studentsList = H4_STUDENTS_LIST;
    const savedStudents = localStorage.getItem('SMART_MESS_H4_STUDENTS');
    if (savedStudents) {
      try {
        studentsList = JSON.parse(savedStudents);
      } catch (err) {}
    }

    let foundStudent = studentsList.find(
      (s) =>
        s.registrationNo.toLowerCase() === queryStr ||
        s.rollNo.toLowerCase() === queryStr ||
        (s.email && s.email.toLowerCase() === queryStr)
    );

    // 2. Fallback to Cloud Firestore query if not found locally
    if (!foundStudent && queryStr.includes('@')) {
      try {
        const { getDocs, collection, query, where } = await import('firebase/firestore/lite');
        const { db } = await import('../../lib/firebase');
        const q = query(collection(db, 'students'), where('email', '==', queryStr));
        const snap = await getDocs(q);
        if (!snap.empty) {
          const docData = snap.docs[0].data() as any;
          foundStudent = {
            slNo: 1,
            name: docData.name,
            rollNo: docData.rollNo || '23534',
            registrationNo: docData.studentId || docData.registrationNo,
            email: docData.email,
            mobile: docData.mobile || '9876543210',
            branch: docData.branch || 'CSE',
            roomNo: docData.roomNo || '101',
            password: docData.password || 'Pass@1234'
          };
        }
      } catch (err) {
        console.error('[RESET] Firestore lookup error:', err);
      }
    }

    if (!foundStudent) {
      toast.error('❌ Access Denied: No resident found with this Email/Registration No.', { duration: 6000 });
      setResetLoading(false);
      return;
    }

    setVerifiedStudent(foundStudent);
    setResetStep(2);
    setResetLoading(false);
    toast.success(`Identity Verified: ${foundStudent.name} (Room ${foundStudent.roomNo})`);

    // Also attempt sending background Firebase Auth email as secondary backup
    if (foundStudent.email) {
      sendPasswordResetEmail(auth, foundStudent.email).catch(() => {});
    }
  };

  const handleDirectPasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!verifiedStudent) return;

    if (!verifyRegNo.trim()) {
      toast.error('Please enter your Registration No or Roll No to confirm identity');
      return;
    }

    const regInput = verifyRegNo.trim().toLowerCase();
    if (regInput !== verifiedStudent.registrationNo.toLowerCase() && regInput !== verifiedStudent.rollNo.toLowerCase()) {
      toast.error('❌ Security Check Failed: Registration/Roll No does not match this account!');
      return;
    }

    if (!newResetPassword || newResetPassword.trim().length < 4) {
      toast.error('New password must be at least 4 characters');
      return;
    }

    setResetLoading(true);
    const updatedPass = newResetPassword.trim();

    // 1. Update in local roster
    let studentsList = H4_STUDENTS_LIST;
    const savedStudents = localStorage.getItem('SMART_MESS_H4_STUDENTS');
    if (savedStudents) {
      try {
        studentsList = JSON.parse(savedStudents);
      } catch (err) {}
    }

    const idx = studentsList.findIndex((s) => s.registrationNo === verifiedStudent.registrationNo);
    if (idx !== -1) {
      studentsList[idx] = { ...studentsList[idx], password: updatedPass };
      localStorage.setItem('SMART_MESS_H4_STUDENTS', JSON.stringify(studentsList));
    }

    // 2. Update in Cloud Firestore
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
        doc(liteDb, 'students', verifiedStudent.registrationNo),
        { password: updatedPass, updatedAt: new Date().toISOString() },
        { merge: true }
      );
    } catch (fsErr) {
      console.error('[RESET] Firestore password sync:', fsErr);
    }

    setResetLoading(false);
    setIdentifier(verifiedStudent.registrationNo);
    setPassword(updatedPass);
    setIsForgotModalOpen(false);
    setResetStep(1);
    setVerifiedStudent(null);
    setVerifyRegNo('');
    setNewResetPassword('');
    toast.success(`🎉 Password reset successful for ${verifiedStudent.name}! Pre-filled login credentials.`, { duration: 7000 });
  };

  const handleDemoLogin = (role: 'manager' | 'admin') => {
    if (role === 'manager') {
      const savedManager = localStorage.getItem('SMART_MESS_MANAGER_DATA');
      let name = 'Dhaneshwar Yadav';
      if (savedManager) {
        try {
          name = JSON.parse(savedManager).name || name;
        } catch (e) {}
      }

      setUser({
        uid: 'mgr_dhaneshwar_01',
        email: '6200432942@smartmess.edu',
        name: `${name} (Mess Manager)`,
        role: 'manager',
        messId: 'mess_h4'
      });
      toast.success(`Logged in as Mess Manager (${name})`);
      navigate('/dashboard');
    } else {
      setUser({
        uid: 'admin_demo_01',
        email: 'admin@smartmess.edu',
        name: 'Super Administrator',
        role: 'admin'
      });
      toast.success('Logged in as Super Admin');
      navigate('/admin/students');
    }
  };

  return (
    <div className="space-y-4">
      <form onSubmit={handleLogin} className="space-y-3.5">
        {/* User / Mobile / Email Input */}
        <div className="relative">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-emerald-800">
            <User className="w-4 h-4" />
          </div>
          <input 
            type="text" 
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            required
            className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50/70 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white text-sm transition-all font-medium"
            placeholder="Mobile No. (6200432942) / Reg No. / Email"
          />
        </div>

        {/* Password Input */}
        <div className="relative">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-emerald-800">
            <Lock className="w-4 h-4" />
          </div>
          <input 
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            className="w-full pl-10 pr-10 py-2.5 bg-gray-50/70 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white text-sm transition-all"
            placeholder="Password (e.g. Pass@2942)"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-gray-400 hover:text-gray-600 transition-colors"
          >
            {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
        </div>

        {/* Remember me & Clean Forgot Password */}
        <div className="flex items-center justify-between text-xs pt-1">
          <label className="flex items-center space-x-2 text-gray-600 cursor-pointer select-none">
            <input 
              type="checkbox" 
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="w-3.5 h-3.5 text-emerald-600 rounded border-gray-300 focus:ring-emerald-500" 
            />
            <span>Remember me</span>
          </label>
          <button 
            type="button"
            onClick={() => {
              setResetEmail(identifier.includes('@') ? identifier : '');
              setResetSuccessMessage(null);
              setIsForgotModalOpen(true);
            }}
            className="text-emerald-700 hover:text-emerald-800 font-semibold hover:underline"
          >
            Forgot password?
          </button>
        </div>

        {/* Sign In Button */}
        <button 
          type="submit" 
          disabled={loading}
          className="w-full bg-[#1B8E2D] hover:bg-[#157324] text-white font-bold py-3 px-4 rounded-xl shadow-md hover:shadow-lg transition-all flex items-center justify-center space-x-2 text-sm disabled:opacity-70 disabled:cursor-not-allowed group mt-2"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
          ) : (
            <>
              <span>Sign In to Dashboard</span>
              <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
            </>
          )}
        </button>
      </form>

      {/* Demo Credentials Quick Switcher */}
      <div className="pt-3 border-t border-gray-100">
        <p className="text-[11px] text-center font-bold text-gray-400 uppercase tracking-wider mb-2.5">
          Quick Access Demo Portals
        </p>
        <div className="grid grid-cols-2 gap-2">
          {/* Dhaneshwar Yadav Card */}
          <button
            onClick={() => handleDemoLogin('manager')}
            className="flex flex-col p-2.5 rounded-xl border border-emerald-200 bg-emerald-50/50 hover:bg-emerald-100/70 hover:border-emerald-300 transition-all text-left group"
          >
            <div className="flex items-center space-x-1.5 text-emerald-800 mb-1">
              <Utensils className="w-3.5 h-3.5" />
              <span className="text-xs font-bold">Mess Manager</span>
            </div>
            <span className="text-[11px] font-bold text-gray-900 truncate">Dhaneshwar Yadav</span>
            <span className="text-[10px] text-gray-500 font-mono">ID: 6200432942</span>
          </button>

          {/* Super Admin Card */}
          <button
            onClick={() => handleDemoLogin('admin')}
            className="flex flex-col p-2.5 rounded-xl border border-blue-200 bg-blue-50/50 hover:bg-blue-100/70 hover:border-blue-300 transition-all text-left group"
          >
            <div className="flex items-center space-x-1.5 text-blue-800 mb-1">
              <Shield className="w-3.5 h-3.5" />
              <span className="text-xs font-bold">Super Admin</span>
            </div>
            <span className="text-[11px] font-bold text-gray-900 truncate">Hostel Administrator</span>
            <span className="text-[10px] text-gray-500 font-mono">Full Roster & Keys</span>
          </button>
        </div>
      </div>

      {/* FORGOT PASSWORD MODAL (INSTANT RECOVERY + EMAIL BACKUP) */}
      {isForgotModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">
                    {resetStep === 1 ? 'Find Your Student Account' : 'Set New Password'}
                  </h3>
                  <p className="text-xs text-gray-500">
                    {resetStep === 1 ? 'Enter your Email or Registration Number' : `Identity Verified: ${verifiedStudent?.name}`}
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setIsForgotModalOpen(false);
                  setResetStep(1);
                  setVerifiedStudent(null);
                }}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {resetStep === 1 ? (
              <form onSubmit={handlePasswordResetStep1} className="space-y-4 py-4">
                <p className="text-xs text-gray-600 leading-relaxed">
                  Enter your registered <strong>Email Address</strong> or <strong>Registration Number</strong> below to verify your resident identity.
                </p>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    Email Address or Registration No
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={resetEmail}
                      onChange={(e) => setResetEmail(e.target.value)}
                      required
                      placeholder="e.g. pawankr0745@gmail.com or 23105108023"
                      className="w-full pl-9 pr-4 py-2.5 border border-gray-300 rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500 font-medium"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                  <button
                    type="button"
                    onClick={() => setIsForgotModalOpen(false)}
                    className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={resetLoading}
                    className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all flex items-center gap-1.5 disabled:opacity-70"
                  >
                    {resetLoading ? (
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <>
                        <Shield className="w-3.5 h-3.5" />
                        <span>Verify Identity</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            ) : (
              <form onSubmit={handleDirectPasswordReset} className="space-y-4 py-4">
                <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200 text-xs text-[#1B5E20]">
                  <p className="font-bold">✅ Identity Verified for {verifiedStudent?.name}</p>
                  <p className="text-[11px] text-emerald-700 mt-0.5">
                    Room {verifiedStudent?.roomNo} • {verifiedStudent?.branch} Branch
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    Confirm Registration No / Roll No
                  </label>
                  <div className="relative">
                    <User className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={verifyRegNo}
                      onChange={(e) => setVerifyRegNo(e.target.value)}
                      required
                      placeholder="e.g. 23105108023 or 23534"
                      className="w-full pl-9 pr-4 py-2.5 border border-gray-300 rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500 font-medium"
                    />
                  </div>
                  <p className="text-[10px] text-gray-500 mt-1">Security check: enter Registration No or Roll No to confirm account ownership.</p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    Set New Password
                  </label>
                  <div className="relative">
                    <Lock className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="password"
                      value={newResetPassword}
                      onChange={(e) => setNewResetPassword(e.target.value)}
                      required
                      placeholder="Enter new password (min 4 chars)"
                      className="w-full pl-9 pr-4 py-2.5 border border-gray-300 rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500 font-medium"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                  <button
                    type="button"
                    onClick={() => setResetStep(1)}
                    className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                  >
                    Back
                  </button>
                  <button
                    type="submit"
                    disabled={resetLoading}
                    className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all flex items-center gap-1.5 disabled:opacity-70"
                  >
                    {resetLoading ? (
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <>
                        <KeyRound className="w-3.5 h-3.5" />
                        <span>Update Password Now</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
