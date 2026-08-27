import React, { useState, useEffect } from 'react';
import { 
  CalendarOff, Utensils, Users, DollarSign, Clock, AlertTriangle, 
  Download, Search, Filter, Building2, CheckCircle2, XCircle, Printer, ChefHat, RefreshCw
} from 'lucide-react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import toast from 'react-hot-toast';

export interface MessOffEntry {
  id: string;
  studentName: string;
  rollNo: string;
  registrationNo: string;
  roomNo: string;
  branch: string;
  mealType: string;
  date: string;
  requestedAt: string;
  reason?: string;
  status: string;
  refundCredited: number;
}

export const MessOffsPage: React.FC = () => {
  const [messOffs, setMessOffs] = useState<MessOffEntry[]>([]);
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [mealFilter, setMealFilter] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchLiveMessOffs = async () => {
    try {
      const res = await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'messOffs' }]
            }
          })
        }
      );
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          const list: MessOffEntry[] = [];
          for (const item of data) {
            if (item.document?.fields) {
              const f = item.document.fields;
              const id = f.id?.stringValue || item.document.name.split('/').pop() || 'mo';
              list.push({
                id,
                studentName: f.studentName?.stringValue || 'Student',
                rollNo: f.rollNo?.stringValue || '',
                registrationNo: f.registrationNo?.stringValue || '',
                roomNo: f.roomNo?.stringValue || '',
                branch: f.branch?.stringValue || '',
                mealType: f.mealType?.stringValue || 'Lunch',
                date: f.date?.stringValue || '',
                requestedAt: f.requestedAt?.stringValue ? new Date(f.requestedAt.stringValue).toLocaleString() : 'Recent',
                reason: f.reason?.stringValue || 'Advance Student Exemption',
                status: f.status?.stringValue || 'Approved',
                refundCredited: parseInt(f.refundCredited?.integerValue || '50', 10),
              });
            }
          }
          setMessOffs(list);
        }
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchLiveMessOffs();
    const interval = setInterval(fetchLiveMessOffs, 3000);
    return () => clearInterval(interval);
  }, []);

  const totalRegistered = H4_STUDENTS_LIST.length; // 112
  const totalMessOffCount = messOffs.length;
  const totalRebate = messOffs.reduce((sum, m) => sum + m.refundCredited, 0);

  const filtered = messOffs.filter((m) => {
    if (mealFilter !== 'All' && m.mealType.toLowerCase() !== mealFilter.toLowerCase()) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        m.studentName.toLowerCase().includes(q) ||
        m.rollNo.toLowerCase().includes(q) ||
        m.roomNo.toLowerCase().includes(q) ||
        m.branch.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleExportCSV = () => {
    const headers = 'ID,Student Name,Roll No,Registration No,Branch,Room No,Meal Type,Date,Requested At,Status,Rebate\n';
    const rows = filtered.map((m) =>
      `"${m.id}","${m.studentName}","${m.rollNo}","${m.registrationNo}","${m.branch}","Room ${m.roomNo}","${m.mealType}","${m.date}","${m.requestedAt}","${m.status}","₹${m.refundCredited}"`
    ).join('\n');

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `Hostel_4_MessOffs_${selectedDate}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success('Downloaded Mess-Off Report!');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-amber-950 via-amber-900 to-amber-950 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4 border border-amber-800/40">
        <div>
          <div className="flex items-center gap-2 text-amber-300 text-sm font-medium">
            <CalendarOff className="w-4 h-4" />
            <span>Hostel Number 4 • Mess-Off Exemption Desk</span>
          </div>
          <h1 className="text-2xl font-bold font-display tracking-tight text-white mt-1">
            Student Advance Mess-Off Requests
          </h1>
          <p className="text-amber-200 text-sm mt-1">
            Real-time feed of meal opt-outs submitted by students before strict cutoff deadlines.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => {
              setIsRefreshing(true);
              fetchLiveMessOffs().finally(() => {
                setTimeout(() => setIsRefreshing(false), 400);
              });
            }}
            className="bg-white/10 hover:bg-white/20 border border-white/20 text-white px-3.5 py-2 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-all"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
            Refresh
          </button>
          <button
            onClick={handleExportCSV}
            className="bg-amber-600 hover:bg-amber-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm transition-all"
          >
            <Download className="w-3.5 h-3.5" />
            Export CSV
          </button>
        </div>
      </div>

      {/* 3 Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-amber-50 rounded-xl text-amber-700">
            <CalendarOff className="w-7 h-7" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Total Active Mess-Offs</span>
            <span className="text-2xl font-bold text-gray-900">{totalMessOffCount}</span>
            <span className="text-xs text-amber-700 font-bold block mt-0.5">{((totalMessOffCount / totalRegistered) * 100).toFixed(1)}% of 112 Boarders</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-emerald-50 rounded-xl text-emerald-700">
            <DollarSign className="w-7 h-7" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Total Rebate Savings Credited</span>
            <span className="text-2xl font-bold text-emerald-700">₹{totalRebate}</span>
            <span className="text-xs text-emerald-600 font-medium block mt-0.5">Credited to student prepaid balance</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-blue-50 rounded-xl text-blue-700">
            <ChefHat className="w-7 h-7" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Kitchen Preparation Adjusted</span>
            <span className="text-2xl font-bold text-gray-900">{totalRegistered - totalMessOffCount} Portions</span>
            <span className="text-xs text-blue-600 font-medium block mt-0.5">Saved cooking wastage</span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Search student, roll, room..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full text-xs pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-amber-600 focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs font-bold text-gray-500">Meal:</span>
          {['All', 'Breakfast', 'Lunch', 'Dinner'].map((m) => (
            <button
              key={m}
              onClick={() => setMealFilter(m)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all ${
                mealFilter === m
                  ? 'bg-amber-800 text-white shadow-sm'
                  : 'bg-gray-100 text-gray-600 hover:text-gray-900'
              }`}
            >
              {m}
            </button>
          ))}
        </div>
      </div>

      {/* Mess-Offs Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-gray-50 text-gray-600 font-bold border-b border-gray-200 uppercase tracking-wider">
              <tr>
                <th className="py-3 px-4">Student Name</th>
                <th className="py-3 px-4">Roll No</th>
                <th className="py-3 px-4">Room</th>
                <th className="py-3 px-4">Meal Type</th>
                <th className="py-3 px-4">Exemption Date</th>
                <th className="py-3 px-4">Requested At</th>
                <th className="py-3 px-4 text-center">Status</th>
                <th className="py-3 px-4 text-right">Rebate</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 font-medium text-gray-700">
              {filtered.map((m) => (
                <tr key={m.id} className="hover:bg-gray-50/80 transition-colors">
                  <td className="py-3 px-4 font-bold text-gray-900">{m.studentName}</td>
                  <td className="py-3 px-4 font-mono text-gray-600">{m.rollNo}</td>
                  <td className="py-3 px-4 font-bold text-gray-800">Room {m.roomNo}</td>
                  <td className="py-3 px-4">
                    <span className="bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded-md text-[11px]">
                      {m.mealType}
                    </span>
                  </td>
                  <td className="py-3 px-4">{m.date}</td>
                  <td className="py-3 px-4 text-gray-500 text-[11px]">{m.requestedAt}</td>
                  <td className="py-3 px-4 text-center">
                    <span className="inline-flex items-center gap-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold px-2.5 py-0.5 rounded-full">
                      <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                      {m.status}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-right font-bold text-emerald-700">₹{m.refundCredited}</td>
                </tr>
              ))}

              {filtered.length === 0 && (
                <tr>
                  <td colSpan={8} className="text-center py-10 text-gray-500 text-sm font-medium">
                    No active mess-off requests. Student opt-outs will appear here in real-time.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
