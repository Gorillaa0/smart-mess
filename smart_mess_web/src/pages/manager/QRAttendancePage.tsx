import React, { useState, useEffect } from 'react';
import QRCode from 'qrcode';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import type { H4Student } from '../../data/h4StudentsData';
import { QrCode, Users, CheckCircle2, AlertCircle, RefreshCw, Cpu, Sparkles, Building2, Utensils, Check } from 'lucide-react';
import toast from 'react-hot-toast';

interface ScannedEntry {
  slNo: number;
  name: string;
  rollNo: string;
  registrationNo: string;
  branch: string;
  roomNo: string;
  scannedAt: string;
  token: string;
}

export const QRAttendancePage: React.FC = () => {
  const [selectedMeal, setSelectedMeal] = useState<'Breakfast' | 'Lunch' | 'Dinner'>('Lunch');
  const [qrCodeUrl, setQrCodeUrl] = useState<string>('');
  const [countdown, setCountdown] = useState(60);
  const [isCounterActive, setIsCounterActive] = useState(true);
  const [scannedEntries, setScannedEntries] = useState<ScannedEntry[]>([]);

  const totalStudents = H4_STUDENTS_LIST.length; // 112
  const scannedCount = scannedEntries.length;
  const pendingCount = Math.max(0, totalStudents - scannedCount);

  const fetchLiveScans = async () => {
    try {
      const res = await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'mealAttendance' }]
            }
          })
        }
      );
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          const list: ScannedEntry[] = [];
          let idx = 1;
          for (const item of data) {
            if (item.document?.fields) {
              const f = item.document.fields;
              const meal = f.mealType?.stringValue || '';
              if (meal.toLowerCase() === selectedMeal.toLowerCase()) {
                list.push({
                  slNo: idx++,
                  name: f.studentName?.stringValue || 'Student',
                  rollNo: f.rollNo?.stringValue || '',
                  registrationNo: f.registrationNo?.stringValue || '',
                  branch: f.branch?.stringValue || 'CSE',
                  roomNo: f.roomNo?.stringValue || '',
                  scannedAt: f.scannedAt?.stringValue ? new Date(f.scannedAt.stringValue).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Just now',
                  token: f.id?.stringValue || `H4-${selectedMeal[0]}`
                });
              }
            }
          }
          setScannedEntries(list);
        }
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchLiveScans();
    const interval = setInterval(fetchLiveScans, 3000);
    return () => clearInterval(interval);
  }, [selectedMeal]);

  useEffect(() => {
    generateQR();
  }, [selectedMeal]);

  useEffect(() => {
    let timer: any;
    if (isCounterActive && countdown > 0) {
      timer = setTimeout(() => setCountdown(countdown - 1), 1000);
    } else if (countdown === 0 && isCounterActive) {
      generateQR();
    }
    return () => clearTimeout(timer);
  }, [countdown, isCounterActive]);

  const generateQR = async () => {
    try {
      const uniquePayload = JSON.stringify({
        hostel: 'Hostel Number 4',
        meal: selectedMeal,
        timestamp: Date.now(),
        token: `H4_TOKEN_${Date.now()}_${Math.random().toString(36).substring(7).toUpperCase()}`
      });
      const url = await QRCode.toDataURL(uniquePayload, {
        width: 280,
        margin: 1,
        color: { dark: '#1B5E20', light: '#FFFFFF' }
      });
      setQrCodeUrl(url);
      setCountdown(60);
    } catch (err) {
      console.error(err);
    }
  };

  const handleManualScan = async (student: H4Student) => {
    const exists = scannedEntries.some((s) => s.registrationNo === student.registrationNo);
    if (exists) {
      toast.error(`${student.name} has already scanned for ${selectedMeal}!`);
      return;
    }

    const docId = `SCAN_MANUAL_${Date.now()}_${student.rollNo}`;
    try {
      await fetch(
        `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/mealAttendance/${docId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              id: { stringValue: docId },
              registrationNo: { stringValue: student.registrationNo },
              studentName: { stringValue: student.name },
              rollNo: { stringValue: student.rollNo },
              branch: { stringValue: student.branch },
              mealType: { stringValue: selectedMeal },
              scannedAt: { stringValue: new Date().toISOString() },
              roomNo: { stringValue: student.roomNo },
              hostelId: { stringValue: 'Hostel Number 4' }
            }
          })
        }
      );
      toast.success(`Plate verified for ${student.name} (Room ${student.roomNo})`);
      fetchLiveScans();
    } catch (_) {}
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            <span>Hostel Number 4 • Digital Counter Turnstile</span>
          </div>
          <h1 className="text-2xl md:text-3xl font-bold font-display tracking-tight text-white mt-1">
            Dynamic QR Meal Attendance Scanner
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Live auto-rotating security QR code for counter verification of 112 enrolled students.
          </p>
        </div>

        {/* Meal Selection Tabs */}
        <div className="flex bg-primary-950/60 p-1.5 rounded-xl border border-white/10 gap-1">
          {(['Breakfast', 'Lunch', 'Dinner'] as const).map((meal) => (
            <button
              key={meal}
              onClick={() => setSelectedMeal(meal)}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                selectedMeal === meal
                  ? 'bg-emerald-500 text-white shadow-sm'
                  : 'text-primary-200 hover:text-white'
              }`}
            >
              <Utensils className="w-3.5 h-3.5" />
              {meal}
            </button>
          ))}
        </div>
      </div>

      {/* Main Content Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left 5 Cols: QR Code Display Card */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col items-center text-center space-y-4">
          <div className="flex items-center justify-between w-full border-b border-gray-100 pb-3">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              {selectedMeal} Session • Counter Display
            </span>
            <div className="flex items-center gap-1.5 bg-emerald-50 text-emerald-800 text-xs font-bold px-2.5 py-1 rounded-full">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              Live Dynamic Token
            </div>
          </div>

          {/* QR Code Container with 60s Ring */}
          <div className="relative p-4 bg-white rounded-2xl border-2 border-primary-800/20 shadow-inner flex items-center justify-center">
            {qrCodeUrl ? (
              <img src={qrCodeUrl} alt="Counter QR Code" className="w-64 h-64 rounded-lg" />
            ) : (
              <div className="w-64 h-64 bg-gray-100 flex items-center justify-center rounded-lg text-gray-400">
                Generating QR...
              </div>
            )}
          </div>

          {/* 60-Second Rotation Progress */}
          <div className="w-full space-y-1.5">
            <div className="flex justify-between text-xs font-bold text-gray-600">
              <span>Token Refresh Countdown</span>
              <span className="text-primary-800">{countdown}s remaining</span>
            </div>
            <div className="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
              <div
                className="bg-primary-700 h-2 rounded-full transition-all duration-1000 ease-linear"
                style={{ width: `${(countdown / 60) * 100}%` }}
              ></div>
            </div>
          </div>

          <button
            onClick={generateQR}
            className="w-full py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-800 text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-1.5"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Force Refresh QR Code Now
          </button>
        </div>

        {/* Right 7 Cols: Live Attendance Feed */}
        <div className="lg:col-span-7 space-y-4">
          {/* Quick Metrics */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Scanned & Eaten</span>
              <span className="text-2xl font-bold text-emerald-700">{scannedCount}</span>
              <span className="text-[11px] text-emerald-600 font-bold block mt-0.5">
                {((scannedCount / totalStudents) * 100).toFixed(1)}% Turnout
              </span>
            </div>

            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Pending Boarders</span>
              <span className="text-2xl font-bold text-amber-700">{pendingCount}</span>
              <span className="text-[11px] text-gray-500 font-medium block mt-0.5">Remaining</span>
            </div>

            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Total Boarders</span>
              <span className="text-2xl font-bold text-gray-900">{totalStudents}</span>
              <span className="text-[11px] text-blue-600 font-medium block mt-0.5">Hostel 4 List</span>
            </div>
          </div>

          {/* Real-time Scanned Students Table */}
          <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-4 space-y-3">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                <h3 className="font-bold text-sm text-gray-900">
                  Live Verified Counter Scans ({scannedCount} Verified)
                </h3>
              </div>
              <span className="text-xs text-gray-400">Updates in real-time</span>
            </div>

            <div className="max-h-96 overflow-y-auto divide-y divide-gray-100">
              {scannedEntries.map((s) => (
                <div key={s.token} className="py-2.5 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-full bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold text-xs">
                      {s.name[0]}
                    </div>
                    <div>
                      <p className="font-bold text-gray-900">{s.name}</p>
                      <p className="text-[10.5px] text-gray-500">Roll: {s.rollNo} • Room {s.roomNo}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className="inline-flex items-center gap-1 text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded font-bold text-[11px]">
                      <Check className="w-3 h-3 text-emerald-600" />
                      {s.scannedAt}
                    </span>
                  </div>
                </div>
              ))}

              {scannedEntries.length === 0 && (
                <div className="py-12 text-center text-gray-400">
                  <Utensils className="w-10 h-10 mx-auto text-gray-300 mb-2 opacity-60" />
                  <p className="font-bold text-gray-600">No scans recorded yet for {selectedMeal}</p>
                  <p className="text-xs text-gray-400 mt-1">Student phone scans at counter will appear here live.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
