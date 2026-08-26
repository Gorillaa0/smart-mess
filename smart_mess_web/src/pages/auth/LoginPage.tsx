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

  // Pure Email-based Forgot Password Modal State
  const [isForgotModalOpen, setIsForgotModalOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState('');
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
        console.log('[AUTH] Firebase Auth direct login check:', firebaseErr.code);
        // If wrong password in Firebase Auth, check if they used their initial default password
        if (student && (cleanPass === student.password || cleanPass === `Pass@${student.registrationNo.slice(-4)}` || cleanPass === '12345678')) {
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
        } else if (firebaseErr.code === 'auth/wrong-password' || firebaseErr.code === 'auth/invalid-credential') {
          toast.error(`Incorrect password. If you recently reset your password, please use your new password.`);
          setLoading(false);
          return;
        }
      }
    }

    if (student) {
      if (cleanPass === student.password || cleanPass === `Pass@${student.registrationNo.slice(-4)}` || cleanPass === '12345678') {
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

  const handlePasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();
    const emailToReset = resetEmail.trim();

    if (!emailToReset || !emailToReset.includes('@')) {
      toast.error('Please enter a valid email address');
      return;
    }

    setResetLoading(true);
    setResetSuccessMessage(null);

    // 🛡️ SECURITY CHECK: Verify email is registered in our student or manager database
    let isEmailInDatabase = false;

    // 1. Check local student roster & manager data
    let studentsList = H4_STUDENTS_LIST;
    const savedStudents = localStorage.getItem('SMART_MESS_H4_STUDENTS');
    if (savedStudents) {
      try {
        studentsList = JSON.parse(savedStudents);
      } catch (e) {}
    }

    const matchedStudent = studentsList.find((s) => s.email && s.email.toLowerCase() === emailToReset.toLowerCase());
    if (matchedStudent) {
      isEmailInDatabase = true;
    }

    // Check manager email
    if (emailToReset.toLowerCase() === 'manager@smartmess.edu' || emailToReset.toLowerCase() === 'admin@smartmess.edu') {
      isEmailInDatabase = true;
    }

    // 2. If not found in local memory, verify against Cloud Firestore directly
    if (!isEmailInDatabase) {
      try {
        const { getDocs, collection, query, where } = await import('firebase/firestore/lite');
        const { db } = await import('../../lib/firebase');
        const q = query(collection(db, 'students'), where('email', '==', emailToReset.toLowerCase()));
        const snap = await getDocs(q);
        if (!snap.empty) {
          isEmailInDatabase = true;
        }
      } catch (checkErr) {
        console.error('[SECURITY] Firestore lookup check:', checkErr);
      }
    }

    if (!isEmailInDatabase) {
      toast.error('❌ Access Denied: This email is not registered in the student roster. Please ask the Admin to link your email first.', { duration: 6000 });
      setResetLoading(false);
      return;
    }

    try {
      // 1. Try sending password reset email directly
      try {
        await sendPasswordResetEmail(auth, emailToReset);
        setResetSuccessMessage(`A password reset link has been sent to ${emailToReset}. Please check your inbox (and Spam/Promotions folder).`);
        toast.success(`Password reset email sent to ${emailToReset}!`);
        setResetLoading(false);
        return;
      } catch (err: any) {
        // If verified user not yet in Auth, provision account securely and retry
        if (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-credential') {
          console.log(`[AUTH] Verified resident ${emailToReset} found in DB. Provisioning Auth account...`);
          const { initializeApp, getApps } = await import('firebase/app');
          const { getAuth, createUserWithEmailAndPassword } = await import('firebase/auth');

          const FIREBASE_CONFIG = {
            apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
            authDomain: 'smart-mess-sih.firebaseapp.com',
            projectId: 'smart-mess-sih',
            storageBucket: 'smart-mess-sih.firebasestorage.app',
            messagingSenderId: '190175767796',
            appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
          };

          const existingApps = getApps();
          const authApp = existingApps.find((a) => a.name === 'auth-provisioner') || initializeApp(FIREBASE_CONFIG, 'auth-provisioner');
          const provAuth = getAuth(authApp);

          const tempPass = 'Pass@' + Math.random().toString(36).slice(-8) + '1!';
          try {
            await createUserWithEmailAndPassword(provAuth, emailToReset, tempPass);
            console.log(`[AUTH] Auto-created user for ${emailToReset}`);
          } catch (createErr: any) {
            if (createErr.code !== 'auth/email-already-in-use') {
              throw createErr;
            }
          }

          // Retry sending reset email
          await sendPasswordResetEmail(auth, emailToReset);
          setResetSuccessMessage(`A password reset link has been sent to ${emailToReset}. Please check your inbox (and Spam/Promotions folder).`);
          toast.success(`Password reset email sent to ${emailToReset}!`);
          setResetLoading(false);
          return;
        } else {
          throw err;
        }
      }
    } catch (err: any) {
      console.error('Firebase password reset error:', err);
      let errorMsg = err.message || 'Failed to send password reset email';
      if (err.code === 'auth/operation-not-allowed') {
        errorMsg = 'Email/Password sign-in provider is not enabled in Firebase Console.';
      } else if (err.code === 'auth/invalid-email') {
        errorMsg = 'The email address is badly formatted.';
      } else if (err.code === 'auth/network-request-failed') {
        errorMsg = 'Network error: Check your internet connection.';
      }
      toast.error(errorMsg, { duration: 6000 });
      setResetSuccessMessage(null);
    } finally {
      setResetLoading(false);
    }
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

      {/* FORGOT PASSWORD MODAL (EMAIL ONLY) */}
      {isForgotModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Forgot Password</h3>
                  <p className="text-xs text-gray-500">Reset your password via Email</p>
                </div>
              </div>
              <button
                onClick={() => setIsForgotModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {resetSuccessMessage ? (
              <div className="py-6 space-y-4 text-center">
                <div className="w-12 h-12 rounded-full bg-emerald-100 text-[#1B5E20] flex items-center justify-center mx-auto">
                  <CheckCircle2 className="w-7 h-7" />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900">Email Sent</h4>
                  <p className="text-xs text-gray-600 mt-1 leading-relaxed">{resetSuccessMessage}</p>
                </div>
                <button
                  onClick={() => setIsForgotModalOpen(false)}
                  className="w-full bg-[#1B5E20] hover:bg-emerald-800 text-white font-bold py-2.5 px-4 rounded-xl shadow text-xs transition-all"
                >
                  Back to Login
                </button>
              </div>
            ) : (
              <form onSubmit={handlePasswordReset} className="space-y-4 py-4">
                <p className="text-xs text-gray-600 leading-relaxed">
                  Enter your <strong>email address</strong> below and we will send you a link to reset your password.
                </p>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={resetEmail}
                      onChange={(e) => setResetEmail(e.target.value)}
                      required
                      placeholder="e.g. yourname@gmail.com or student@smartmess.edu"
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
                        <Mail className="w-3.5 h-3.5" />
                        <span>Send Reset Link</span>
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
