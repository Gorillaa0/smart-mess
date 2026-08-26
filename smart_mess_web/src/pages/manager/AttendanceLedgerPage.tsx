import React, { useState } from 'react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import type { H4Student } from '../../data/h4StudentsData';
import { 
  Users, CheckCircle2, XCircle, CalendarOff, Search, Filter, 
  Download, Building2, Utensils, Clock, Check, RefreshCw, UserCheck
} from 'lucide-react';
import toast from 'react-hot-toast';

export type StudentMealStatus = 'present' | 'mess-off' | 'absent';

export interface StudentAttendanceEntry {
  student: H4Student;
  status: StudentMealStatus;
  scannedAt?: string;
  plateToken?: string;
}

export const AttendanceLedgerPage: React.FC = () => {
  const [selectedMeal, setSelectedMeal] = useState<'Breakfast' | 'Lunch' | 'Dinner'>('Lunch');
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [branchFilter, setBranchFilter] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');

  // Generate realistic initial attendance state for 112 students
  const [attendanceMap, setAttendanceMap] = useState<Record<string, { status: StudentMealStatus; scannedAt?: string; token?: string }>>(() => {
    const map: Record<string, { status: StudentMealStatus; scannedAt?: string; token?: string }> = {};
    H4_STUDENTS_LIST.forEach((s, idx) => {
      if (idx < 76) {
        // 76 students eaten
        const min = 10 + (idx % 45);
        map[s.registrationNo] = {
          status: 'present',
          scannedAt: `01:${min < 10 ? '0' + min : min} PM`,
          token: `H4-L-${(8100 + idx)}`
        };
      } else if (idx < 94) {
        // 18 students marked mess-off
        map[s.registrationNo] = {
          status: 'mess-off'
        };
      } else {
        // 18 students absent/pending
        map[s.registrationNo] = {
          status: 'absent'
        };
      }
    });
    return map;
  });

  const totalCount = H4_STUDENTS_LIST.length; // 112
  const presentCount = Object.values(attendanceMap).filter((a) => a.status === 'present').length;
  const messOffCount = Object.values(attendanceMap).filter((a) => a.status === 'mess-off').length;
  const absentCount = Object.values(attendanceMap).filter((a) => a.status === 'absent').length;
  const turnoutPercent = ((presentCount / totalCount) * 100).toFixed(1);

  const handleTogglePresent = (student: H4Student) => {
    const current = attendanceMap[student.registrationNo]?.status || 'absent';
    const nextStatus: StudentMealStatus = current === 'present' ? 'absent' : 'present';
    const nowStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const newToken = `H4-${selectedMeal[0]}-${Date.now().toString().slice(-4)}`;

    setAttendanceMap((prev) => ({
      ...prev,
      [student.registrationNo]: {
        status: nextStatus,
        scannedAt: nextStatus === 'present' ? nowStr : undefined,
        token: nextStatus === 'present' ? newToken : undefined
      }
    }));

    if (nextStatus === 'present') {
      toast.success(`Marked ${student.name} as PRESENT & EATEN`);
    } else {
      toast(`Marked ${student.name} as ABSENT`, { icon: 'ℹ️' });
    }
  };

  const handleExportCSV = () => {
    const headers = 'Sl No,Student Name,Roll No,Registration No,Branch,Room No,Status,Scan Time,Plate Token\n';
    const rows = H4_STUDENTS_LIST.map((s) => {
      const att = attendanceMap[s.registrationNo] || { status: 'absent' };
      return `"${s.slNo}","${s.name}","${s.rollNo}","${s.registrationNo}","${s.branch}","Room ${s.roomNo}","${att.status.toUpperCase()}","${att.scannedAt || '-'}","${att.token || '-'}"`;
    }).join('\n');

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `Hostel_4_Attendance_${selectedMeal}_${selectedDate}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success(`Downloaded ${selectedMeal} Attendance Report!`);
  };

  const filteredList = H4_STUDENTS_LIST.filter((student) => {
    const att = attendanceMap[student.registrationNo] || { status: 'absent' };
    const matchesStatus = statusFilter === 'All' || att.status === statusFilter.toLowerCase();
    const matchesBranch = branchFilter === 'All' || student.branch === branchFilter;
    const cleanQ = searchQuery.toLowerCase().trim();
    const matchesSearch =
      cleanQ === '' ||
      student.name.toLowerCase().includes(cleanQ) ||
      student.rollNo.toLowerCase().includes(cleanQ) ||
      student.registrationNo.includes(cleanQ) ||
      student.roomNo.includes(cleanQ);

    return matchesStatus && matchesBranch && matchesSearch;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            Smart Mess Dining System • Central Mess Hall
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Student Meal Attendance Ledger
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Real-time status of all 112 resident students: Present (Eaten), Mess-Off, and Absent
          </p>
        </div>

        {/* Meal & Date Switcher */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center bg-emerald-950/60 p-1.5 rounded-xl border border-emerald-500/30">
            {(['Breakfast', 'Lunch', 'Dinner'] as const).map((meal) => (
              <button
                key={meal}
                onClick={() => setSelectedMeal(meal)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  selectedMeal === meal
                    ? 'bg-emerald-500 text-white shadow'
                    : 'text-emerald-200 hover:text-white'
                }`}
              >
                {meal}
              </button>
            ))}
          </div>

          <button
            onClick={handleExportCSV}
            className="flex items-center gap-1.5 bg-white text-primary-900 px-3.5 py-2 rounded-xl font-bold text-xs shadow hover:bg-primary-50 transition-all"
          >
            <Download className="w-4 h-4 text-primary-800" />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      {/* 4 Summary Stat Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="flex items-center justify-between text-gray-500 text-xs font-semibold">
            <span>Total Capacity</span>
            <Users className="w-4 h-4 text-gray-400" />
          </div>
          <p className="text-2xl font-display font-bold text-gray-900 mt-1">{totalCount} Residents</p>
          <p className="text-xs text-gray-400 mt-0.5">Hostel Number 4</p>
        </div>

        <div className="bg-emerald-50 p-4 rounded-xl border border-emerald-200 shadow-sm">
          <div className="flex items-center justify-between text-emerald-800 text-xs font-bold">
            <span>🟢 Present & Eaten</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          </div>
          <p className="text-2xl font-display font-bold text-[#1B5E20] mt-1">{presentCount} Students</p>
          <p className="text-xs text-emerald-700 mt-0.5">{turnoutPercent}% Verified Turnout</p>
        </div>

        <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 shadow-sm">
          <div className="flex items-center justify-between text-amber-800 text-xs font-bold">
            <span>🟡 Approved Mess-Off</span>
            <CalendarOff className="w-4 h-4 text-amber-600" />
          </div>
          <p className="text-2xl font-display font-bold text-amber-900 mt-1">{messOffCount} Students</p>
          <p className="text-xs text-amber-700 mt-0.5">Fee Waived (₹50 credit)</p>
        </div>

        <div className="bg-red-50 p-4 rounded-xl border border-red-200 shadow-sm">
          <div className="flex items-center justify-between text-red-800 text-xs font-bold">
            <span>🔴 Absent / Pending</span>
            <XCircle className="w-4 h-4 text-red-600" />
          </div>
          <p className="text-2xl font-display font-bold text-red-900 mt-1">{absentCount} Students</p>
          <p className="text-xs text-red-700 mt-0.5">Yet to scan or skipped</p>
        </div>
      </div>

      {/* Filter & Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Search Input */}
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by Name, Roll, Reg, Room..."
            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:bg-white"
          />
        </div>

        {/* Status Filters */}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="text-xs font-bold text-gray-500 mr-1">Status:</span>
          {['All', 'Present', 'Mess-Off', 'Absent'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                statusFilter === st
                  ? st === 'Present'
                    ? 'bg-emerald-700 text-white'
                    : st === 'Mess-Off'
                    ? 'bg-amber-600 text-white'
                    : st === 'Absent'
                    ? 'bg-red-600 text-white'
                    : 'bg-[#1B5E20] text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {st}
            </button>
          ))}
        </div>

        {/* Branch Filter Tabs */}
        <div className="flex items-center gap-1 overflow-x-auto">
          <Filter className="w-3.5 h-3.5 text-gray-400 mr-1" />
          {['All', 'CSE', 'Civil', 'ECE', 'EE', 'ME'].map((b) => (
            <button
              key={b}
              onClick={() => setBranchFilter(b)}
              className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all ${
                branchFilter === b
                  ? 'bg-slate-800 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {b}
            </button>
          ))}
        </div>
      </div>

      {/* 112 Student Attendance Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-left">
            <thead className="bg-gray-50/80 text-gray-600 text-xs font-bold uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3.5">Sl</th>
                <th className="px-6 py-3.5">Student Name & Roll</th>
                <th className="px-4 py-3.5">Branch</th>
                <th className="px-6 py-3.5">Registration No.</th>
                <th className="px-4 py-3.5">Room</th>
                <th className="px-6 py-3.5">Meal Status ({selectedMeal})</th>
                <th className="px-4 py-3.5">Scan Details</th>
                <th className="px-4 py-3.5 text-center">Manager Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filteredList.length === 0 ? (
                <tr>
                  <td colSpan={8} className="p-8 text-center text-gray-400">
                    No resident found matching current filters.
                  </td>
                </tr>
              ) : (
                filteredList.map((s) => {
                  const att = attendanceMap[s.registrationNo] || { status: 'absent' };
                  return (
                    <tr key={s.registrationNo} className="hover:bg-gray-50/70 transition-colors">
                      <td className="px-4 py-3.5 text-xs font-bold text-gray-400">#{s.slNo}</td>
                      <td className="px-6 py-3.5">
                        <div className="font-bold text-gray-900">{s.name}</div>
                        <div className="text-xs text-gray-500">Roll: {s.rollNo}</div>
                      </td>
                      <td className="px-4 py-3.5">
                        <span className="inline-block px-2 py-0.5 rounded-full text-xs font-extrabold bg-gray-100 text-gray-800">
                          {s.branch}
                        </span>
                      </td>
                      <td className="px-6 py-3.5 font-mono text-xs font-bold text-gray-800">
                        {s.registrationNo}
                      </td>
                      <td className="px-4 py-3.5 text-xs font-semibold text-gray-700">
                        Room {s.roomNo}
                      </td>
                      <td className="px-6 py-3.5">
                        {att.status === 'present' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold border border-emerald-200">
                            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-700" />
                            <span>Present (Eaten)</span>
                          </span>
                        )}
                        {att.status === 'mess-off' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-100 text-amber-800 text-xs font-bold border border-amber-200">
                            <CalendarOff className="w-3.5 h-3.5 text-amber-700" />
                            <span>Mess-Off (Waived)</span>
                          </span>
                        )}
                        {att.status === 'absent' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-100 text-red-800 text-xs font-bold border border-red-200">
                            <XCircle className="w-3.5 h-3.5 text-red-700" />
                            <span>Absent / Not Eaten</span>
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        {att.status === 'present' ? (
                          <div>
                            <span className="font-mono font-bold text-emerald-800 block text-[11px]">{att.token}</span>
                            <span className="text-gray-400 text-[10px] flex items-center gap-1 mt-0.5">
                              <Clock className="w-3 h-3" /> {att.scannedAt}
                            </span>
                          </div>
                        ) : att.status === 'mess-off' ? (
                          <span className="text-[11px] text-amber-700 font-semibold">Pre-approved</span>
                        ) : (
                          <span className="text-[11px] text-gray-400">No scan recorded</span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <button
                          onClick={() => handleTogglePresent(s)}
                          className={`px-3 py-1 rounded-lg text-xs font-bold transition-all border ${
                            att.status === 'present'
                              ? 'bg-red-50 hover:bg-red-100 text-red-700 border-red-200'
                              : 'bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] border-emerald-200'
                          }`}
                          title="Click to toggle attendance manually"
                        >
                          {att.status === 'present' ? 'Mark Absent' : 'Mark Eaten'}
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
