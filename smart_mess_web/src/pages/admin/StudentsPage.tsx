import React, { useState, useEffect } from 'react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import type { H4Student } from '../../data/h4StudentsData';
import { 
  Search, Download, Upload, Plus, ShieldCheck, Filter, 
  Building2, KeyRound, Edit, Check, X, Lock, Phone, User, AlertCircle, Mail, AtSign, Database
} from 'lucide-react';
import toast from 'react-hot-toast';

export const StudentsPage: React.FC = () => {
  const [students, setStudents] = useState<H4Student[]>(() => {
    const saved = localStorage.getItem('SMART_MESS_H4_STUDENTS');
    if (saved) {
      try {
        const parsed: H4Student[] = JSON.parse(saved);
        return parsed.map((s) => {
          if (s.registrationNo === '23105108059' && !s.email) {
            return { ...s, email: 'priyanshugandhi64@gmail.com' };
          }
          if ((s.rollNo === '23534' || s.registrationNo === '23105108023') && !s.email) {
            return { ...s, email: 'pawankr0745@gmail.com' };
          }
          return s;
        });
      } catch (e) {
        console.error(e);
      }
    }
    return H4_STUDENTS_LIST;
  });

  const [query, setQuery] = useState('');
  const [selectedBranch, setSelectedBranch] = useState<string>('All');
  const [copiedPass, setCopiedPass] = useState<string | null>(null);

  // Edit Modal State
  const [editingStudent, setEditingStudent] = useState<H4Student | null>(null);
  const [editForm, setEditForm] = useState({
    name: '',
    rollNo: '',
    registrationNo: '',
    email: '',
    branch: 'CSE',
    roomNo: '',
    mobile: '',
    password: ''
  });

  // Add New Student Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addForm, setAddForm] = useState({
    name: '',
    rollNo: '',
    registrationNo: '',
    email: '',
    branch: 'CSE',
    roomNo: '',
    mobile: '',
    semester: '6th',
    cgpa: '8.00',
    password: ''
  });

  // Save to localStorage whenever students list changes
  useEffect(() => {
    localStorage.setItem('SMART_MESS_H4_STUDENTS', JSON.stringify(students));
  }, [students]);

  const filteredStudents = students.filter((student) => {
    const matchesQuery =
      query === '' ||
      student.name.toLowerCase().includes(query.toLowerCase()) ||
      student.rollNo.toLowerCase().includes(query.toLowerCase()) ||
      student.registrationNo.includes(query) ||
      (student.email && student.email.toLowerCase().includes(query.toLowerCase())) ||
      student.mobile.includes(query);
    const matchesBranch = selectedBranch === 'All' || student.branch === selectedBranch;
    return matchesQuery && matchesBranch;
  });

  const handleCopyPassword = (student: H4Student) => {
    navigator.clipboard.writeText(student.password);
    setCopiedPass(student.registrationNo);
    toast.success(`Copied password for ${student.name}: ${student.password}`);
    setTimeout(() => setCopiedPass(null), 2000);
  };

  const handleExportCSV = () => {
    const headers = 'Sl.No.,Name,Roll No.,Email,Mobile,Branch,Registration No.,Semester,CGPA,Hostel,Room No.,Password\n';
    const rows = students.map(
      (s) =>
        `"${s.slNo}","${s.name}","${s.rollNo}","${s.email || ''}","${s.mobile}","${s.branch}","${s.registrationNo}","${s.semester}","${s.cgpa}","${s.hostel}","${s.roomNo}","${s.password}"`
    ).join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', 'Hostel_4_Students_Master_Credentials.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success('Downloaded Master Student Credentials CSV!');
  };

  const handleImportCSV = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (evt) => {
      const text = evt.target?.result as string;
      const lines = text.split('\n').map((l) => l.trim()).filter((l) => l.length > 0);
      
      if (lines.length <= 1) {
        toast.error('CSV file seems empty or invalid');
        return;
      }

      const imported: H4Student[] = [];
      for (let i = 1; i < lines.length; i++) {
        const parts = lines[i].split(',').map((p) => p.replace(/^"|"$/g, '').trim());
        if (parts.length >= 7) {
          const sl = parseInt(parts[0]) || i;
          const name = parts[1] || `Student ${i}`;
          const roll = parts[2] || `23${500 + i}`;
          
          let email = '';
          let mobile = '';
          let branch = 'CSE';
          let reg = '';

          // Check if CSV has 12 columns with Email or 11 columns without Email
          if (parts.length >= 12) {
            email = parts[3] || '';
            mobile = parts[4] || '9876543210';
            branch = parts[5] || 'CSE';
            reg = parts[6] || `23105108${100 + i}`;
          } else {
            mobile = parts[3] || '9876543210';
            branch = parts[4] || 'CSE';
            reg = parts[5] || `23105108${100 + i}`;
          }

          const sem = parts[7] || '6th';
          const cgpa = parseFloat(parts[8]) || 7.5;
          const hostel = parts[9] || 'Hostel Number 4';
          const room = parts[10] || `${100 + (i % 50)}`;
          const pass = parts[11] || `Pass@${reg.slice(-4) || '1234'}`;

          imported.push({
            slNo: sl,
            name,
            rollNo: roll,
            email: email || undefined,
            mobile,
            branch: (branch as any) || 'CSE',
            registrationNo: reg,
            semester: sem,
            cgpa,
            hostel,
            roomNo: room,
            password: pass
          });
        }
      }

      if (imported.length > 0) {
        setStudents(imported);
        toast.success(`Successfully imported ${imported.length} students from CSV!`);
      } else {
        toast.error('Could not parse student rows. Please check CSV format.');
      }
    };
    reader.readAsText(file);
  };

  const handleOpenEdit = (student: H4Student) => {
    setEditingStudent(student);
    setEditForm({
      name: student.name,
      rollNo: student.rollNo,
      registrationNo: student.registrationNo,
      email: student.email || '',
      branch: student.branch,
      roomNo: student.roomNo,
      mobile: student.mobile,
      password: student.password
    });
  };

  const handleSaveEdit = () => {
    if (!editingStudent) return;
    if (!editForm.name || !editForm.registrationNo || !editForm.password) {
      toast.error('Name, Registration No, and Password are required');
      return;
    }

    const reg = editForm.registrationNo.trim();
    const newPassword = editForm.password.trim();
    const oldPassword = editingStudent.password; // password before admin changed it
    const passwordChanged = newPassword !== oldPassword;
    const studentEmail = editForm.email.trim()
      ? editForm.email.trim().toLowerCase()
      : `${reg}@smartmess.edu`;

    setStudents((prev) =>
      prev.map((s) =>
        s.registrationNo === editingStudent.registrationNo
          ? {
              ...s,
              name: editForm.name.trim(),
              rollNo: editForm.rollNo.trim(),
              registrationNo: reg,
              email: editForm.email.trim() ? editForm.email.trim() : undefined,
              branch: editForm.branch as any,
              roomNo: editForm.roomNo.trim(),
              mobile: editForm.mobile.trim(),
              password: newPassword
            }
          : s
      )
    );

    toast.success(`Updating ${editForm.name}...`);
    setEditingStudent(null);

    (async () => {
      const FIREBASE_CONFIG = {
        apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        authDomain: 'smart-mess-sih.firebaseapp.com',
        projectId: 'smart-mess-sih',
        storageBucket: 'smart-mess-sih.firebasestorage.app',
        messagingSenderId: '190175767796',
        appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
      };

      try {
        const { initializeApp, getApps, deleteApp } = await import('firebase/app');
        const { getAuth, signInWithEmailAndPassword, updatePassword, createUserWithEmailAndPassword, signOut } = await import('firebase/auth');
        const { getFirestore, doc, setDoc } = await import('firebase/firestore/lite');

        // ── STEP 1: Update Firebase Auth password
        // Use a secondary app so the admin session is never disrupted
        if (passwordChanged) {
          const secondaryAppName = `edit-student-${reg}-${Date.now()}`;
          const secondaryApp = initializeApp(FIREBASE_CONFIG, secondaryAppName);
          const secondaryAuth = getAuth(secondaryApp);

          try {
            // Try signing in with the OLD password first
            const userCred = await signInWithEmailAndPassword(secondaryAuth, studentEmail, oldPassword);
            // Success — now update to the NEW password in Firebase Auth
            await updatePassword(userCred.user, newPassword);
            toast.success(`✅ Firebase Auth password updated for ${editForm.name}`);
            console.log(`[AUTH] Password updated for ${studentEmail}`);
          } catch (signInErr: any) {
            if (signInErr.code === 'auth/user-not-found' || signInErr.code === 'auth/invalid-credential') {
              // No Firebase Auth account exists yet — create one with the new password
              try {
                await createUserWithEmailAndPassword(secondaryAuth, studentEmail, newPassword);
                toast.success(`✅ Firebase Auth account created for ${editForm.name}`);
                console.log(`[AUTH] New account provisioned for ${studentEmail}`);
              } catch (createErr: any) {
                if (createErr.code === 'auth/email-already-in-use') {
                  // Account exists but old password is stale (student already changed via email reset)
                  // We cannot force-update from client SDK — send reset email as fallback
                  const mainApps = getApps();
                  const mainApp = mainApps.find(a => a.name === '[DEFAULT]');
                  if (mainApp) {
                    const { sendPasswordResetEmail } = await import('firebase/auth');
                    const mainAuth = getAuth(mainApp);
                    await sendPasswordResetEmail(mainAuth, studentEmail);
                    toast.success(`🔑 Reset email sent to ${studentEmail} — student must reset via link`);
                  }
                } else {
                  console.error('[AUTH] Create error:', createErr);
                  toast.error(`⚠️ Auth error: ${createErr.message}`);
                }
              }
            } else if (signInErr.code === 'auth/wrong-password' || signInErr.code === 'auth/invalid-login-credentials') {
              // Account exists but student already changed their password themselves
              // Send a reset link so they can use the admin-set password
              try {
                const mainApps = getApps();
                const mainApp = mainApps.find(a => a.name === '[DEFAULT]');
                if (mainApp) {
                  const { sendPasswordResetEmail } = await import('firebase/auth');
                  const mainAuth = getAuth(mainApp);
                  await sendPasswordResetEmail(mainAuth, studentEmail);
                  toast.success(`🔑 Reset email sent to ${studentEmail}`);
                }
              } catch (_) {}
            } else {
              console.error('[AUTH] Sign-in error:', signInErr);
            }
          } finally {
            await signOut(secondaryAuth);
            await deleteApp(secondaryApp);
          }
        }

        // ── STEP 2: Write updated student data + password to Firestore
        // Use the Firestore REST API directly (bypasses Firestore SDK auth check)
        const API_KEY = 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E';
        const PROJECT_ID = 'smart-mess-sih';
        const docPath = `students/${reg}`;
        const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}?key=${API_KEY}&updateMask.fieldPaths=studentId&updateMask.fieldPaths=name&updateMask.fieldPaths=rollNo&updateMask.fieldPaths=email&updateMask.fieldPaths=mobile&updateMask.fieldPaths=branch&updateMask.fieldPaths=roomNo&updateMask.fieldPaths=password&updateMask.fieldPaths=updatedAt`;

        const mainApps = getApps();
        const mainApp = mainApps.find(a => a.name === '[DEFAULT]');
        let idToken = '';
        if (mainApp) {
          const { getAuth } = await import('firebase/auth');
          const mainAuth = getAuth(mainApp);
          const currentUser = mainAuth.currentUser;
          if (currentUser) {
            idToken = await currentUser.getIdToken(true);
          }
        }

        const firestoreBody = {
          fields: {
            studentId: { stringValue: reg },
            name: { stringValue: editForm.name.trim() },
            rollNo: { stringValue: editForm.rollNo.trim() },
            email: { stringValue: studentEmail },
            mobile: { stringValue: editForm.mobile.trim() },
            branch: { stringValue: editForm.branch },
            roomNo: { stringValue: editForm.roomNo.trim() },
            password: { stringValue: newPassword },
            updatedAt: { stringValue: new Date().toISOString() }
          }
        };

        const response = await fetch(
          `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/students/${reg}`,
          {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              ...(idToken ? { 'Authorization': `Bearer ${idToken}` } : {})
            },
            body: JSON.stringify(firestoreBody)
          }
        );

        if (response.ok) {
          console.log(`[FIRESTORE] Updated ${editForm.name} via REST API`);
          toast.success(`✅ ${editForm.name} updated in Firestore!`);
        } else {
          // Fallback: try Firestore SDK
          const existingApps = getApps();
          const liteApp = existingApps.find(a => a.name === 'lite-app') || initializeApp(FIREBASE_CONFIG, 'lite-app');
          const liteDb = getFirestore(liteApp, 'default');
          await setDoc(doc(liteDb, 'students', reg), {
            studentId: reg,
            name: editForm.name.trim(),
            rollNo: editForm.rollNo.trim(),
            email: studentEmail,
            mobile: editForm.mobile.trim(),
            branch: editForm.branch,
            roomNo: editForm.roomNo.trim(),
            password: newPassword,
            updatedAt: new Date().toISOString()
          }, { merge: true });
          toast.success(`✅ ${editForm.name} updated!`);
        }
      } catch (err: any) {
        console.error('[EDIT] Error:', err);
        toast.error(`❌ Update error: ${err.message}`);
      }
    })();
  };

  const handleResetToDefaultRoster = () => {
    setStudents(H4_STUDENTS_LIST);
    localStorage.removeItem('SMART_MESS_H4_STUDENTS');
    toast.success('Reset to official 112 H4 resident roster!');
  };

  const handleSaveNewStudent = () => {
    if (!addForm.name || !addForm.registrationNo) {
      toast.error('Please fill Name and Registration Number');
      return;
    }

    const reg = addForm.registrationNo.trim();
    const autoPass = addForm.password.trim() || `Pass@${reg.slice(-4) || '1234'}`;
    const studentEmail = addForm.email.trim()
      ? addForm.email.trim().toLowerCase()
      : `${reg}@smartmess.edu`;

    const newStudent: H4Student = {
      slNo: students.length + 1,
      name: addForm.name.trim(),
      rollNo: addForm.rollNo.trim() || '23599',
      registrationNo: reg,
      email: addForm.email.trim() ? addForm.email.trim() : undefined,
      branch: addForm.branch as any,
      roomNo: addForm.roomNo.trim() || '101',
      mobile: addForm.mobile.trim() || '9876543210',
      semester: addForm.semester || '6th',
      cgpa: parseFloat(addForm.cgpa) || 7.50,
      hostel: 'Hostel Number 4',
      password: autoPass
    };

    setStudents((prev) => [...prev, newStudent]);
    toast.success(`Added ${newStudent.name} — provisioning Firebase account...`);
    setIsAddModalOpen(false);
    setAddForm({
      name: '',
      rollNo: '',
      registrationNo: '',
      email: '',
      branch: 'CSE',
      roomNo: '',
      mobile: '',
      semester: '6th',
      cgpa: '8.00',
      password: ''
    });

    // Provision Firebase Auth account + save to Firestore (both in parallel)
    (async () => {
      const FIREBASE_CONFIG = {
        apiKey: 'AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        authDomain: 'smart-mess-sih.firebaseapp.com',
        projectId: 'smart-mess-sih',
        storageBucket: 'smart-mess-sih.firebasestorage.app',
        messagingSenderId: '190175767796',
        appId: '1:190175767796:web:9d8da3ec9adbe2fd9882a1'
      };

      try {
        const { initializeApp, getApps, deleteApp } = await import('firebase/app');
        const { getAuth, createUserWithEmailAndPassword, signOut } = await import('firebase/auth');
        const { getFirestore, doc, setDoc } = await import('firebase/firestore/lite');

        // ── Step 1: Create Firebase Auth account via a secondary app instance
        // (Using a secondary app so the current admin session is NOT disrupted)
        const secondaryAppName = `provision-student-${reg}-${Date.now()}`;
        const secondaryApp = initializeApp(FIREBASE_CONFIG, secondaryAppName);
        const secondaryAuth = getAuth(secondaryApp);

        try {
          await createUserWithEmailAndPassword(secondaryAuth, studentEmail, autoPass);
          console.log(`[AUTH] Firebase Auth account created for ${newStudent.name} (${studentEmail})`);
          toast.success(`✅ Firebase Auth account created for ${newStudent.name}`);
        } catch (authErr: any) {
          if (authErr.code === 'auth/email-already-in-use') {
            console.log(`[AUTH] Account already exists for ${studentEmail} — skipping creation`);
          } else {
            console.error('[AUTH] Failed to create Firebase Auth account:', authErr);
            toast.error(`⚠️ Auth account error for ${newStudent.name}: ${authErr.message}`);
          }
        } finally {
          // Always sign out and delete the secondary app to clean up
          await signOut(secondaryAuth);
          await deleteApp(secondaryApp);
        }

        // ── Step 2: Write full student record + password to Firestore
        const existingApps = getApps();
        const liteApp = existingApps.find(a => a.name === 'lite-app') || initializeApp(FIREBASE_CONFIG, 'lite-app');
        const liteDb = getFirestore(liteApp, 'default');

        await setDoc(doc(liteDb, 'students', reg), {
          studentId: reg,
          slNo: newStudent.slNo,
          name: newStudent.name,
          rollNo: newStudent.rollNo,
          mobile: newStudent.mobile,
          email: studentEmail,
          branch: newStudent.branch,
          registrationNo: reg,
          semester: newStudent.semester,
          cgpa: newStudent.cgpa,
          hostel: newStudent.hostel,
          roomNo: newStudent.roomNo,
          password: autoPass,          // ← stored for admin reference
          messId: 'mess_h4',
          status: 'active',
          role: 'student',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }, { merge: true });

        console.log(`[FIRESTORE] Saved ${newStudent.name} (${reg}) with password to Firestore`);
        toast.success(`✅ ${newStudent.name} fully provisioned in Firebase!`);
      } catch (err: any) {
        console.error('[PROVISION] Error provisioning student:', err);
        toast.error(`❌ Provisioning error: ${err.message}`);
      }
    })();
  };


  const [isSyncingCloud, setIsSyncingCloud] = useState(false);

  const handleSyncToCloudFirestore = async () => {
    setIsSyncingCloud(true);
    const toastId = toast.loading(`Syncing ${students.length} students to Firestore...`);
    console.log('[SYNC] Starting REST API sync for', students.length, 'students');

    try {
      // Get the admin's Firebase Auth ID token to authorize Firestore writes
      const { getApps } = await import('firebase/app');
      const { getAuth } = await import('firebase/auth');
      const mainApp = getApps().find(a => a.name === '[DEFAULT]');
      let idToken = '';
      if (mainApp) {
        const mainAuth = getAuth(mainApp);
        if (mainAuth.currentUser) {
          idToken = await mainAuth.currentUser.getIdToken(true);
        }
      }

      const PROJECT_ID = 'smart-mess-sih';
      let count = 0;
      let failed = 0;

      // Process students in parallel batches of 10 for speed
      const BATCH_SIZE = 10;
      for (let i = 0; i < students.length; i += BATCH_SIZE) {
        const batch = students.slice(i, i + BATCH_SIZE);
        const email = `${batch[0]?.registrationNo || ''}@smartmess.edu`;
        toast.loading(`Syncing... ${Math.min(i + BATCH_SIZE, students.length)}/${students.length}`, { id: toastId });

        await Promise.allSettled(batch.map(async (s) => {
          const studentEmail = s.email || `${s.registrationNo}@smartmess.edu`;
          const body = {
            fields: {
              studentId: { stringValue: s.registrationNo },
              slNo: { integerValue: String(s.slNo) },
              name: { stringValue: s.name },
              rollNo: { stringValue: s.rollNo },
              mobile: { stringValue: s.mobile || '' },
              email: { stringValue: studentEmail },
              branch: { stringValue: s.branch },
              registrationNo: { stringValue: s.registrationNo },
              semester: { stringValue: s.semester || '6th' },
              cgpa: { doubleValue: s.cgpa || 0 },
              hostel: { stringValue: s.hostel || 'Hostel Number 4' },
              roomNo: { stringValue: s.roomNo || '' },
              password: { stringValue: s.password || '' },
              messId: { stringValue: 'mess_h4' },
              status: { stringValue: 'active' },
              role: { stringValue: 'student' },
              updatedAt: { stringValue: new Date().toISOString() }
            }
          };

          const res = await fetch(
            `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/students/${s.registrationNo}`,
            {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                ...(idToken ? { 'Authorization': `Bearer ${idToken}` } : {})
              },
              body: JSON.stringify(body)
            }
          );
          if (res.ok) { count++; } else { failed++; }
        }));
      }

      // Sync hostel, mess, manager metadata
      const metadataDocs = [
        { path: 'hostels/hostel_h4', fields: { hostelId: { stringValue: 'hostel_h4' }, name: { stringValue: 'Hostel Number 4' }, capacity: { integerValue: '150' } } },
        { path: 'messes/mess_h4', fields: { messId: { stringValue: 'mess_h4' }, name: { stringValue: 'Hostel Number 4 Central Mess' }, hostelId: { stringValue: 'hostel_h4' }, managerId: { stringValue: 'manager_dhaneshwar' }, capacity: { integerValue: '150' } } },
        { path: 'managers/manager_dhaneshwar', fields: { managerId: { stringValue: 'manager_dhaneshwar' }, name: { stringValue: 'Dhaneshwar Yadav' }, mobile: { stringValue: '6200432942' }, messId: { stringValue: 'mess_h4' }, role: { stringValue: 'manager' }, status: { stringValue: 'active' } } }
      ];
      for (const meta of metadataDocs) {
        await fetch(
          `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${meta.path}`,
          {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', ...(idToken ? { 'Authorization': `Bearer ${idToken}` } : {}) },
            body: JSON.stringify({ fields: meta.fields })
          }
        );
      }

      toast.dismiss(toastId);
      if (failed === 0) {
        toast.success(`🎉 All ${count} students synced to Firestore!`, { duration: 6000 });
      } else {
        toast.success(`⚠️ ${count} synced, ${failed} failed. Check Firestore rules in Firebase Console.`, { duration: 8000 });
      }
      console.log(`[SYNC] ✅ Done — ${count} synced, ${failed} failed`);
    } catch (err: any) {
      console.error('[SYNC] ❌', err.code, err.message);
      toast.dismiss(toastId);
      toast.error(`Sync failed: ${err.code || err.message}`, { duration: 8000 });
    } finally {
      setIsSyncingCloud(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            Smart Mess Portal • Super Admin Console
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Student Data & Password Management
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Import records, assign unique credentials, emails, and manage passwords for registered residents ({students.length} Total)
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2.5">
          {/* 1-Click Cloud Sync */}
          <button
            onClick={handleSyncToCloudFirestore}
            disabled={isSyncingCloud}
            className="flex items-center gap-2 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-900 px-3.5 py-2 rounded-xl font-bold text-xs shadow-md transition-all disabled:opacity-50"
            title="Upload all student profiles to Google Cloud Firestore database"
          >
            <Database className="w-4 h-4 text-slate-900" />
            <span>{isSyncingCloud ? 'Syncing...' : 'Sync to Cloud Firestore'}</span>
          </button>

          {/* CSV Import */}
          <label className="cursor-pointer flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-3.5 py-2 rounded-xl font-bold text-xs shadow transition-all">
            <Upload className="w-4 h-4" />
            <span>Import CSV</span>
            <input type="file" accept=".csv" onChange={handleImportCSV} className="hidden" />
          </label>

          {/* Add Student */}
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center gap-2 bg-white text-primary-900 hover:bg-primary-50 px-3.5 py-2 rounded-xl font-bold text-xs shadow transition-all"
          >
            <Plus className="w-4 h-4 text-primary-700" />
            <span>Add Student</span>
          </button>

          {/* Export CSV */}
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 bg-primary-700/80 hover:bg-primary-700 text-white px-3.5 py-2 rounded-xl font-bold text-xs shadow transition-all border border-primary-500/30"
          >
            <Download className="w-4 h-4" />
            <span>Export Sheet</span>
          </button>

          {/* Reset Roster */}
          <button
            onClick={handleResetToDefaultRoster}
            className="text-xs text-primary-300 hover:text-white underline px-2 py-1"
            title="Reset to default 112 students"
          >
            Reset Roster
          </button>
        </div>
      </div>

      {/* Roster Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="text-xs font-bold text-gray-500 uppercase">Total Students</div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{students.length}</div>
          <div className="text-[11px] text-emerald-600 font-semibold mt-0.5">Hostel 4 Residents</div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="text-xs font-bold text-gray-500 uppercase">CSE Branch</div>
          <div className="text-2xl font-bold text-emerald-800 mt-1">
            {students.filter((s) => s.branch === 'CSE').length}
          </div>
          <div className="text-[11px] text-gray-500 font-semibold mt-0.5">Students</div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="text-xs font-bold text-gray-500 uppercase">Civil Branch</div>
          <div className="text-2xl font-bold text-blue-800 mt-1">
            {students.filter((s) => s.branch === 'Civil').length}
          </div>
          <div className="text-[11px] text-gray-500 font-semibold mt-0.5">Students</div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="text-xs font-bold text-gray-500 uppercase">ECE Branch</div>
          <div className="text-2xl font-bold text-purple-800 mt-1">
            {students.filter((s) => s.branch === 'ECE').length}
          </div>
          <div className="text-[11px] text-gray-500 font-semibold mt-0.5">Students</div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm col-span-2 md:col-span-1">
          <div className="text-xs font-bold text-gray-500 uppercase">Emails Linked</div>
          <div className="text-2xl font-bold text-emerald-700 mt-1">
            {students.filter((s) => !!s.email).length} / {students.length}
          </div>
          <div className="text-[11px] text-gray-500 font-semibold mt-0.5">Password Reset Ready</div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row gap-3 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search by name, roll, reg no, email, mobile..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none"
          />
        </div>

        {/* Branch Filter Tabs */}
        <div className="flex flex-wrap items-center gap-1.5 w-full md:w-auto">
          <span className="text-xs font-bold text-gray-500 mr-1 flex items-center gap-1">
            <Filter className="w-3.5 h-3.5" /> Branch:
          </span>
          {['All', 'CSE', 'Civil', 'ECE', 'EE', 'ME'].map((b) => (
            <button
              key={b}
              onClick={() => setSelectedBranch(b)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                selectedBranch === b
                  ? 'bg-[#1B5E20] text-white shadow-sm'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {b}
            </button>
          ))}
        </div>
      </div>

      {/* 112 Students Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-left">
            <thead className="bg-gray-50/80 text-gray-600 text-xs font-bold uppercase tracking-wider">
              <tr>
                <th className="px-3 py-3.5">Sl</th>
                <th className="px-5 py-3.5">Student Name & Roll</th>
                <th className="px-4 py-3.5">Branch & Sem</th>
                <th className="px-4 py-3.5">Registration No. (Login ID)</th>
                <th className="px-5 py-3.5">Email Address</th>
                <th className="px-3 py-3.5">Mobile</th>
                <th className="px-3 py-3.5">Room</th>
                <th className="px-5 py-3.5">Password</th>
                <th className="px-4 py-3.5 text-center">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filteredStudents.length === 0 ? (
                <tr>
                  <td colSpan={9} className="p-8 text-center text-gray-400">
                    No student found matching "{query}"
                  </td>
                </tr>
              ) : (
                filteredStudents.map((s) => (
                  <tr key={s.registrationNo} className="hover:bg-emerald-50/30 transition-colors">
                    <td className="px-3 py-3.5 text-xs font-bold text-gray-400">#{s.slNo}</td>
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-gray-900">{s.name}</div>
                      <div className="text-xs text-gray-500">Roll: {s.rollNo}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <span
                        className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-extrabold ${
                          s.branch === 'CSE'
                            ? 'bg-emerald-100 text-emerald-800'
                            : s.branch === 'Civil'
                            ? 'bg-blue-100 text-blue-800'
                            : s.branch === 'ECE'
                            ? 'bg-purple-100 text-purple-800'
                            : s.branch === 'EE'
                            ? 'bg-amber-100 text-amber-800'
                            : 'bg-orange-100 text-orange-800'
                        }`}
                      >
                        {s.branch} • {s.semester}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 font-mono text-xs font-bold text-gray-800">
                      {s.registrationNo}
                    </td>
                    <td className="px-5 py-3.5">
                      {s.email ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-900 font-medium text-xs border border-emerald-200">
                          <AtSign className="w-3 h-3 text-emerald-600 flex-shrink-0" />
                          <span className="truncate max-w-[180px]" title={s.email}>{s.email}</span>
                        </span>
                      ) : (
                        <button
                          onClick={() => handleOpenEdit(s)}
                          className="inline-flex items-center gap-1 text-[11px] text-gray-400 hover:text-emerald-700 bg-gray-50 hover:bg-emerald-50 px-2 py-0.5 rounded border border-dashed border-gray-300 hover:border-emerald-300 transition-all italic"
                          title="Click to add email"
                        >
                          <Plus className="w-2.5 h-2.5" />
                          <span>Null (Add Email)</span>
                        </button>
                      )}
                    </td>
                    <td className="px-3 py-3.5 text-xs text-gray-600 font-medium">{s.mobile}</td>
                    <td className="px-3 py-3.5 text-xs font-semibold text-gray-700">Room {s.roomNo}</td>
                    <td className="px-5 py-3.5">
                      <button
                        onClick={() => handleCopyPassword(s)}
                        className="inline-flex items-center gap-1.5 px-2 py-1 rounded-lg bg-gray-100 hover:bg-emerald-100 text-gray-800 hover:text-emerald-900 text-xs font-mono font-bold transition-all border border-gray-200"
                        title="Click to copy password"
                      >
                        <KeyRound className="w-3 h-3 text-emerald-600" />
                        <span>{copiedPass === s.registrationNo ? 'COPIED!' : s.password}</span>
                      </button>
                    </td>
                    <td className="px-4 py-3.5 text-center">
                      <button
                        onClick={() => handleOpenEdit(s)}
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] text-xs font-bold border border-emerald-200 transition-all"
                      >
                        <Edit className="w-3.5 h-3.5" />
                        <span>Edit</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* EDIT CREDENTIALS & EMAIL MODAL */}
      {editingStudent && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Edit Student Record</h3>
                  <p className="text-xs text-gray-500">Super Admin Override & Email Update</p>
                </div>
              </div>
              <button
                onClick={() => setEditingStudent(null)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3.5 py-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Student Name</label>
                <input
                  type="text"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                  className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                />
              </div>

              {/* Email Input */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Email Address <span className="text-gray-400 font-normal">(For Firebase Password Reset)</span>
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    value={editForm.email}
                    onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                    placeholder="e.g. priyanshugandhi64@gmail.com (Leave blank if not provided)"
                    className="w-full pl-9 pr-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none font-medium"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Registration No. (Login ID)</label>
                  <input
                    type="text"
                    value={editForm.registrationNo}
                    onChange={(e) => setEditForm({ ...editForm, registrationNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Roll No.</label>
                  <input
                    type="text"
                    value={editForm.rollNo}
                    onChange={(e) => setEditForm({ ...editForm, rollNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Room No.</label>
                  <input
                    type="text"
                    value={editForm.roomNo}
                    onChange={(e) => setEditForm({ ...editForm, roomNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Mobile No.</label>
                  <input
                    type="text"
                    value={editForm.mobile}
                    onChange={(e) => setEditForm({ ...editForm, mobile: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              {/* Password Override */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Assign Password <span className="text-emerald-700">(Student can also change after login)</span>
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={editForm.password}
                    onChange={(e) => setEditForm({ ...editForm, password: e.target.value })}
                    className="w-full pl-9 pr-3 py-2 border rounded-xl text-sm font-mono font-bold focus:ring-2 focus:ring-emerald-500 outline-none bg-amber-50/40 border-amber-200"
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-4 border-t border-gray-100">
              <button
                onClick={() => setEditingStudent(null)}
                className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all flex items-center gap-1.5"
              >
                <Check className="w-3.5 h-3.5" />
                <span>Save Changes</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ADD STUDENT MODAL */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <Plus className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Add New Student</h3>
                  <p className="text-xs text-gray-500">Hostel Number 4 Resident</p>
                </div>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3.5 py-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Student Full Name *</label>
                <input
                  type="text"
                  placeholder="e.g. Ramesh Kumar"
                  value={addForm.name}
                  onChange={(e) => setAddForm({ ...addForm, name: e.target.value })}
                  className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                />
              </div>

              {/* Email */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Email Address <span className="text-gray-400 font-normal">(Optional)</span>
                </label>
                <input
                  type="email"
                  placeholder="e.g. ramesh@gmail.com"
                  value={addForm.email}
                  onChange={(e) => setAddForm({ ...addForm, email: e.target.value })}
                  className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Registration No. *</label>
                  <input
                    type="text"
                    placeholder="e.g. 23105108099"
                    value={addForm.registrationNo}
                    onChange={(e) => setAddForm({ ...addForm, registrationNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Roll No.</label>
                  <input
                    type="text"
                    placeholder="e.g. 23599"
                    value={addForm.rollNo}
                    onChange={(e) => setAddForm({ ...addForm, rollNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Branch</label>
                  <select
                    value={addForm.branch}
                    onChange={(e) => setAddForm({ ...addForm, branch: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none bg-white"
                  >
                    <option value="CSE">CSE</option>
                    <option value="Civil">Civil</option>
                    <option value="ECE">ECE</option>
                    <option value="EE">EE</option>
                    <option value="ME">ME</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Room No.</label>
                  <input
                    type="text"
                    placeholder="e.g. 101"
                    value={addForm.roomNo}
                    onChange={(e) => setAddForm({ ...addForm, roomNo: e.target.value })}
                    className="w-full px-3 py-2 border rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Custom Password <span className="text-gray-400 font-normal">(Default: Pass@&lt;last4&gt;)</span>
                </label>
                <input
                  type="text"
                  placeholder="Leave blank for auto-generation"
                  value={addForm.password}
                  onChange={(e) => setAddForm({ ...addForm, password: e.target.value })}
                  className="w-full px-3 py-2 border rounded-xl text-sm font-mono focus:ring-2 focus:ring-emerald-500 outline-none"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-4 border-t border-gray-100">
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveNewStudent}
                className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all flex items-center gap-1.5"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Student</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
