import React, { useState, useEffect } from 'react';
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
  const [liveScans, setLiveScans] = useState<any[]>([]);
  const [liveMessOffs, setLiveMessOffs] = useState<any[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchLiveFirestoreData = async () => {
    try {
      // Fetch live mealAttendance
      const resAtt = await fetch(
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
      if (resAtt.ok) {
        const dataAtt = await resAtt.json();
        if (Array.isArray(dataAtt)) {
          const scans: any[] = [];
          for (const item of dataAtt) {
            if (item.document?.fields) {
              const f = item.document.fields;
              scans.push({
                registrationNo: f.registrationNo?.stringValue || '',
                mealType: f.mealType?.stringValue || '',
                scannedAt: f.scannedAt?.stringValue || '',
                id: f.id?.stringValue || ''
              });
            }
          }
          setLiveScans(scans);
        }
      }

      // Fetch live messOffs
      const resOff = await fetch(
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
      if (resOff.ok) {
        const dataOff = await resOff.json();
        if (Array.isArray(dataOff)) {
          const offs: any[] = [];
          for (const item of dataOff) {
            if (item.document?.fields) {
              const f = item.document.fields;
              offs.push({
                registrationNo: f.registrationNo?.stringValue || '',
                mealType: f.mealType?.stringValue || '',
                date: f.date?.stringValue || ''
              });
            }
          }
          setLiveMessOffs(offs);
        }
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchLiveFirestoreData();
    const interval = setInterval(fetchLiveFirestoreData, 3000);
    return () => clearInterval(interval);
  }, []);

  // Compute attendance map dynamically for the 112 students
  const attendanceMap: Record<string, { status: StudentMealStatus; scannedAt?: string; token?: string }> = {};

  H4_STUDENTS_LIST.forEach((s) => {
    const scanMatch = liveScans.find((sc) => {
      const scanDate = sc.scannedAt ? sc.scannedAt.split('T')[0] : '';
      return (
        sc.registrationNo === s.registrationNo &&
        sc.mealType.toLowerCase() === selectedMeal.toLowerCase() &&
        (scanDate === selectedDate || !scanDate)
      );
    });

    const offMatch = liveMessOffs.find((mo) => {
      return (
        mo.registrationNo === s.registrationNo &&
        (mo.mealType.toLowerCase() === selectedMeal.toLowerCase() || mo.mealType.toLowerCase() === 'full day') &&
        mo.date === selectedDate
      );
    });

    if (scanMatch) {
      const scanTime = scanMatch.scannedAt ? new Date(scanMatch.scannedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Verified';
      attendanceMap[s.registrationNo] = {
        status: 'present',
        scannedAt: scanTime,
        token: `H4-${selectedMeal[0]}-${s.rollNo.slice(-4)}`
      };
    } else if (offMatch) {
      attendanceMap[s.registrationNo] = {
        status: 'mess-off'
      };
    } else {
      attendanceMap[s.registrationNo] = {
        status: 'absent'
      };
    }
  });

  const totalCount = H4_STUDENTS_LIST.length; // 112
  const presentCount = Object.values(attendanceMap).filter((a) => a.status === 'present').length;
  const messOffCount = Object.values(attendanceMap).filter((a) => a.status === 'mess-off').length;
  const absentCount = Object.values(attendanceMap).filter((a) => a.status === 'absent').length;
  const turnoutPercent = totalCount > 0 ? ((presentCount / totalCount) * 100).toFixed(1) : '0.0';

  const handleTogglePresent = async (student: H4Student) => {
    const current = attendanceMap[student.registrationNo]?.status || 'absent';
    const isNowPresent = current === 'present';
    const docId = `SCAN_MANUAL_${Date.now()}_${student.rollNo}`;

    if (!isNowPresent) {
      // Mark present
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
        toast.success(`Marked ${student.name} as PRESENT & EATEN`);
        fetchLiveFirestoreData();
      } catch (_) {}
    } else {
      toast(`Student is already recorded as present`, { icon: 'ℹ️' });
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
    
    // Status Filter
    if (statusFilter !== 'All' && att.status !== statusFilter.toLowerCase()) {
      return false;
    }
    
    // Branch Filter
    if (branchFilter !== 'All' && student.branch !== branchFilter) {
      return false;
    }

    // Search Query (Name, Roll, Reg, Room)
    if (searchQuery.trim() !== '') {
      const q = searchQuery.toLowerCase();
      return (
        student.name.toLowerCase().includes(q) ||
        student.rollNo.toLowerCase().includes(q) ||
        student.registrationNo.toLowerCase().includes(q) ||
        student.roomNo.toLowerCase().includes(q) ||
        student.branch.toLowerCase().includes(q)
      );
    }

    return true;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            <span>Hostel Number 4 • Central Dining Facility</span>
          </div>
          <h1 className="text-2xl font-bold font-display tracking-tight text-white mt-1">
            Master Attendance Ledger ({totalCount} Registered Students)
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Live real-time student dining records, QR plate scans & advance mess-off exemptions.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <button
            onClick={() => {
              setIsRefreshing(true);
              fetchLiveFirestoreData().finally(() => {
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
            className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm transition-all"
          >
            <Download className="w-3.5 h-3.5" />
            Export CSV ({selectedMeal})
          </button>
        </div>
      </div>

      {/* Meal & Date Selector Strip */}
      <div className="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        {/* Meal Type Tabs */}
        <div className="flex bg-gray-100 p-1 rounded-xl gap-1">
          {(['Breakfast', 'Lunch', 'Dinner'] as const).map((meal) => (
            <button
              key={meal}
              onClick={() => setSelectedMeal(meal)}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                selectedMeal === meal
                  ? 'bg-primary-800 text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <Utensils className="w-3.5 h-3.5" />
              {meal}
            </button>
          ))}
        </div>

        {/* Date Selector */}
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold text-gray-500">Date:</span>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="text-xs font-bold text-gray-800 bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 focus:ring-2 focus:ring-primary-600 focus:outline-none"
          />
        </div>
      </div>

      {/* 4 Stat Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3.5">
          <div className="p-3 bg-emerald-50 rounded-xl text-emerald-700">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Eaten / Present</span>
            <span className="text-2xl font-bold text-gray-900">{presentCount}</span>
            <span className="text-[11px] text-emerald-600 font-bold block mt-0.5">{turnoutPercent}% Turnout</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3.5">
          <div className="p-3 bg-amber-50 rounded-xl text-amber-700">
            <CalendarOff className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Mess-Off Opted</span>
            <span className="text-2xl font-bold text-gray-900">{messOffCount}</span>
            <span className="text-[11px] text-amber-700 font-bold block mt-0.5">{((messOffCount / totalCount) * 100).toFixed(1)}% Exempted</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3.5">
          <div className="p-3 bg-gray-100 rounded-xl text-gray-600">
            <Clock className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Pending / Unscanned</span>
            <span className="text-2xl font-bold text-gray-900">{absentCount}</span>
            <span className="text-[11px] text-gray-500 font-medium block mt-0.5">Awaiting counter scan</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3.5">
          <div className="p-3 bg-blue-50 rounded-xl text-blue-700">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold text-gray-500 block">Total Hostel 4</span>
            <span className="text-2xl font-bold text-gray-900">{totalCount}</span>
            <span className="text-[11px] text-blue-600 font-medium block mt-0.5">Enrolled Boarders</span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm space-y-3">
        <div className="flex flex-col md:flex-row items-center justify-between gap-3">
          {/* Search Box */}
          <div className="relative w-full md:w-80">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search by student name, roll, reg no, room..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full text-xs pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-600 focus:outline-none"
            />
          </div>

          {/* Status & Branch Filters */}
          <div className="flex items-center gap-2 flex-wrap w-full md:w-auto">
            {/* Status Filter */}
            <div className="flex items-center gap-1 bg-gray-50 p-1 rounded-xl border border-gray-200">
              {['All', 'Present', 'Mess-Off', 'Absent'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setStatusFilter(tab)}
                  className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
                    statusFilter === tab
                      ? 'bg-primary-800 text-white shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            {/* Branch Filter */}
            <select
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
              className="text-xs font-bold text-gray-700 bg-gray-50 border border-gray-200 rounded-xl px-3 py-1.5 focus:ring-2 focus:ring-primary-600 focus:outline-none"
            >
              <option value="All">All Branches</option>
              <option value="CSE">CSE</option>
              <option value="Civil">Civil</option>
              <option value="Mechanical">Mechanical</option>
              <option value="EE">EE</option>
              <option value="EC">EC</option>
            </select>
          </div>
        </div>
      </div>

      {/* Master 112 Students Attendance Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-gray-50 text-gray-600 font-bold border-b border-gray-200 uppercase tracking-wider">
              <tr>
                <th className="py-3 px-4 w-12 text-center">#</th>
                <th className="py-3 px-4">Student Name</th>
                <th className="py-3 px-4">Roll No</th>
                <th className="py-3 px-4">Registration No</th>
                <th className="py-3 px-4">Branch</th>
                <th className="py-3 px-4">Room</th>
                <th className="py-3 px-4 text-center">Status</th>
                <th className="py-3 px-4">Scan Time / Details</th>
                <th className="py-3 px-4 text-center">Quick Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 font-medium text-gray-700">
              {filteredList.map((student) => {
                const att = attendanceMap[student.registrationNo] || { status: 'absent' };
                const isPresent = att.status === 'present';
                const isMessOff = att.status === 'mess-off';

                return (
                  <tr
                    key={student.registrationNo}
                    className={`hover:bg-gray-50/80 transition-colors ${
                      isPresent ? 'bg-emerald-50/20' : isMessOff ? 'bg-amber-50/20' : ''
                    }`}
                  >
                    <td className="py-3 px-4 text-center text-gray-400 font-bold">{student.slNo}</td>
                    <td className="py-3 px-4 font-bold text-gray-900 flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-primary-50 text-primary-800 flex items-center justify-center font-bold text-xs shrink-0">
                        {student.name[0]}
                      </div>
                      <span>{student.name}</span>
                    </td>
                    <td className="py-3 px-4 font-mono text-gray-600">{student.rollNo}</td>
                    <td className="py-3 px-4 font-mono text-gray-500">{student.registrationNo}</td>
                    <td className="py-3 px-4">
                      <span className="bg-gray-100 text-gray-800 text-[10px] font-bold px-2 py-0.5 rounded-md">
                        {student.branch}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-bold text-gray-800">Room {student.roomNo}</td>
                    <td className="py-3 px-4 text-center">
                      {isPresent ? (
                        <span className="inline-flex items-center gap-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold px-2.5 py-0.5 rounded-full">
                          <Check className="w-3 h-3 text-emerald-600 stroke-[3]" />
                          EATEN
                        </span>
                      ) : isMessOff ? (
                        <span className="inline-flex items-center gap-1 bg-amber-100 text-amber-800 text-[11px] font-bold px-2.5 py-0.5 rounded-full">
                          <CalendarOff className="w-3 h-3 text-amber-700" />
                          MESS-OFF
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 bg-gray-100 text-gray-600 text-[11px] font-medium px-2 py-0.5 rounded-full">
                          <Clock className="w-3 h-3 text-gray-400" />
                          PENDING
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      {isPresent ? (
                        <div>
                          <span className="text-gray-900 font-bold block">{att.scannedAt}</span>
                          <span className="text-[10px] font-mono text-gray-400">{att.token}</span>
                        </div>
                      ) : isMessOff ? (
                        <span className="text-amber-800 text-xs">Exempted (Rebate Credited)</span>
                      ) : (
                        <span className="text-gray-400 text-xs italic">Not scanned</span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => handleTogglePresent(student)}
                        className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                          isPresent
                            ? 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                            : 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm'
                        }`}
                      >
                        {isPresent ? 'Verified' : 'Manual Scan'}
                      </button>
                    </td>
                  </tr>
                );
              })}

              {filteredList.length === 0 && (
                <tr>
                  <td colSpan={9} className="text-center py-8 text-gray-500 text-sm font-medium">
                    No student records matched your search or filters.
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
