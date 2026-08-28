import React, { useState, useEffect } from 'react';
import QRCode from 'qrcode';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import { Building2, Utensils, Printer, Download, CheckCircle2 } from 'lucide-react';
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
    generateStaticQR();
  }, []);

  const generateStaticQR = async () => {
    try {
      // Permanent Static QR payload for physical paper printout / wall mounting
      const staticPayload = JSON.stringify({
        system: 'SmartMess',
        hostel: 'Hostel Number 4',
        messId: 'mess_h4',
        counter: 'Main Dining Counter',
        type: 'static_counter_qr'
      });
      const url = await QRCode.toDataURL(staticPayload, {
        width: 320,
        margin: 1,
        color: { dark: '#1B5E20', light: '#FFFFFF' }
      });
      setQrCodeUrl(url);
    } catch (err) {
      console.error(err);
    }
  };

  const handlePrintQR = () => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Pop-up blocked. Please allow pop-ups to print the QR poster.');
      return;
    }
    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Smart Mess - Hostel 4 Counter QR Code</title>
          <style>
            @page { size: A4 portrait; margin: 20mm; }
            body {
              font-family: system-ui, -apple-system, sans-serif;
              text-align: center;
              padding: 30px;
              color: #1B5E20;
            }
            .border-box {
              border: 4px solid #1B5E20;
              border-radius: 24px;
              padding: 40px 20px;
              max-width: 500px;
              margin: 0 auto;
            }
            h1 { font-size: 28px; margin: 0 0 6px 0; color: #1B5E20; }
            h2 { font-size: 18px; margin: 0 0 20px 0; color: #43A047; font-weight: normal; }
            img { width: 300px; height: 300px; margin: 10px auto; display: block; }
            .badge {
              display: inline-block;
              background: #E8F5E9;
              color: #1B5E20;
              padding: 6px 16px;
              border-radius: 20px;
              font-weight: bold;
              font-size: 13px;
              margin-top: 15px;
            }
            .instructions {
              margin-top: 25px;
              font-size: 14px;
              color: #555;
              line-height: 1.5;
            }
          </style>
        </head>
        <body>
          <div class="border-box">
            <h1>SMART MESS</h1>
            <h2>Hostel Number 4 • Dining Hall Counter</h2>
            <img src="${qrCodeUrl}" alt="Permanent Counter QR Code" />
            <div class="badge">PERMANENT STATIC QR CODE</div>
            <div class="instructions">
              <strong>Instructions for Students:</strong><br/>
              Open the <b>Smart Mess Mobile App</b> &gt; Tap <b>Scan QR</b>.<br/>
              Align your camera with this code to verify your meal plate.
            </div>
          </div>
          <script>
            window.onload = () => { window.print(); };
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const handleDownloadQR = () => {
    if (!qrCodeUrl) return;
    const a = document.createElement('a');
    a.href = qrCodeUrl;
    a.download = 'SmartMess_Hostel4_Static_QR.png';
    a.click();
    toast.success('Downloaded Static QR Code image');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            <span>Hostel Number 4 • Physical Dining Counter</span>
          </div>
          <h1 className="text-2xl md:text-3xl font-bold font-display tracking-tight text-white mt-1">
            Permanent Static Counter QR Code
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Print or paste this permanent QR code on the mess counter for offline student camera scanning.
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
        {/* Left 5 Cols: Static Printable QR Code Display */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col items-center text-center space-y-4">
          <div className="flex items-center justify-between w-full border-b border-gray-100 pb-3">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Permanent Mess Counter QR
            </span>
            <div className="flex items-center gap-1.5 bg-emerald-50 text-emerald-800 text-xs font-bold px-2.5 py-1 rounded-full">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              Static (Never Expires)
            </div>
          </div>

          {/* QR Code Container */}
          <div className="p-4 bg-white rounded-2xl border-2 border-primary-800/30 shadow-sm flex flex-col items-center justify-center">
            {qrCodeUrl ? (
              <img src={qrCodeUrl} alt="Static Counter QR Code" className="w-64 h-64 rounded-lg" />
            ) : (
              <div className="w-64 h-64 bg-gray-100 flex items-center justify-center rounded-lg text-gray-400">
                Generating Static QR...
              </div>
            )}
            <span className="text-[11px] text-gray-500 font-mono mt-2">HOSTEL 4 • PERMANENT DINING TOKEN</span>
          </div>

          {/* Action Buttons: Print & Download Poster */}
          <div className="grid grid-cols-2 gap-3 w-full pt-1">
            <button
              onClick={handlePrintQR}
              className="py-2.5 px-3 bg-[#1B8E2D] hover:bg-[#157324] text-white text-xs font-bold rounded-xl shadow-sm hover:shadow transition-all flex items-center justify-center gap-1.5"
            >
              <Printer className="w-4 h-4" />
              Print Counter Poster
            </button>
            <button
              onClick={handleDownloadQR}
              className="py-2.5 px-3 bg-gray-100 hover:bg-gray-200 text-gray-800 text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-1.5"
            >
              <Download className="w-4 h-4" />
              Save Image
            </button>
          </div>

          <p className="text-[11px] text-gray-500 bg-gray-50 p-2.5 rounded-xl border border-gray-100 w-full text-left leading-relaxed">
            💡 <strong>Testing Mode:</strong> You can print this QR code on paper or show it from your phone. It never expires, eliminating the need for digital screens at the counter.
          </p>
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
              <span className="text-[11px] text-primary-700 font-bold block mt-0.5">H4 Roster</span>
            </div>
          </div>

          {/* Real-time Scanned Students Table */}
          <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <h3 className="font-bold text-gray-900 text-sm">
                  Live Attendance Feed • {selectedMeal}
                </h3>
              </div>
              <span className="text-xs text-gray-500 font-medium">Auto-refreshing (3s)</span>
            </div>

            <div className="overflow-x-auto max-h-[420px] overflow-y-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50 text-gray-600 font-bold sticky top-0 border-b border-gray-100 z-10">
                  <tr>
                    <th className="py-2.5 px-3">#</th>
                    <th className="py-2.5 px-3">Student Name</th>
                    <th className="py-2.5 px-3">Roll No.</th>
                    <th className="py-2.5 px-3">Room</th>
                    <th className="py-2.5 px-3">Time</th>
                    <th className="py-2.5 px-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 text-gray-800">
                  {scannedEntries.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-10 text-gray-400">
                        No students scanned for {selectedMeal} yet today.
                      </td>
                    </tr>
                  ) : (
                    scannedEntries.map((entry) => (
                      <tr key={entry.slNo} className="hover:bg-emerald-50/40 transition-colors">
                        <td className="py-2.5 px-3 font-mono text-gray-400">{entry.slNo}</td>
                        <td className="py-2.5 px-3 font-semibold text-gray-900">{entry.name}</td>
                        <td className="py-2.5 px-3 font-mono text-emerald-800 font-bold">{entry.rollNo}</td>
                        <td className="py-2.5 px-3 font-medium text-gray-600">Room {entry.roomNo}</td>
                        <td className="py-2.5 px-3 text-gray-500 font-mono">{entry.scannedAt}</td>
                        <td className="py-2.5 px-3 text-right">
                          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                            Verified
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
