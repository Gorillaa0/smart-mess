import React, { useState, useEffect } from 'react';
import { H4_STUDENTS_LIST } from '../../data/h4StudentsData';
import type { H4Student } from '../../data/h4StudentsData';
import { 
  Users, CheckCircle2, CalendarOff, Search,
  Download, Building2, Utensils, Clock, Check, RefreshCw,
  Receipt, X, CreditCard, ChevronRight, ShieldCheck, DollarSign
} from 'lucide-react';
import toast from 'react-hot-toast';

export type StudentMealStatus = 'present' | 'mess-off' | 'absent';

export interface DailyBillItem {
  date: string;
  dayName: string;
  dateFormatted: string;
  breakfast: { eaten: boolean; price: number };
  lunch: { eaten: boolean; price: number };
  dinner: { eaten: boolean; price: number };
  dayTotal: number;
}

export const AttendanceLedgerPage: React.FC = () => {
  const [selectedMeal, setSelectedMeal] = useState<'Breakfast' | 'Lunch' | 'Dinner'>('Lunch');
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [statusFilter, setStatusFilter] = useState<string>('Present'); // Default to eaten only
  const [branchFilter, setBranchFilter] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [liveScans, setLiveScans] = useState<any[]>([]);
  const [liveMessOffs, setLiveMessOffs] = useState<any[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedStudentForBill, setSelectedStudentForBill] = useState<H4Student | null>(null);

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
                rollNo: f.rollNo?.stringValue || '',
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
        (sc.registrationNo === s.registrationNo || sc.rollNo === s.rollNo) &&
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

  const computeStudentBill = (student: H4Student) => {
    const cleanReg = student.registrationNo.trim().toLowerCase();
    const cleanRoll = student.rollNo.trim().toLowerCase();

    const studentScans = liveScans.filter((s: any) => {
      const sr = (s.registrationNo || '').trim().toLowerCase();
      const sl = (s.rollNo || '').trim().toLowerCase();
      return sr === cleanReg || sr === cleanRoll || sl === cleanReg || sl === cleanRoll;
    });

    const studentMessOffs = liveMessOffs.filter((m: any) => {
      const mr = (m.registrationNo || '').trim().toLowerCase();
      return mr === cleanReg || mr === cleanRoll;
    });

    // Group by unique calendar dates
    const datesMap: Record<string, any[]> = {};
    studentScans.forEach((s: any) => {
      const d = s.scannedAt ? s.scannedAt.split('T')[0] : new Date().toISOString().split('T')[0];
      if (!datesMap[d]) datesMap[d] = [];
      datesMap[d].push(s);
    });

    const dailyItems: DailyBillItem[] = [];
    Object.entries(datesMap).forEach(([dateStr, dayScans]) => {
      const dateObj = new Date(dateStr);
      const dayOfWeek = dateObj.getDay(); // 0 = Sun, 3 = Wed
      const isSunday = dayOfWeek === 0;
      const isWednesday = dayOfWeek === 3;

      const bEaten = dayScans.some((s: any) => (s.mealType || '').toLowerCase().includes('breakfast'));
      const lEaten = dayScans.some((s: any) => (s.mealType || '').toLowerCase().includes('lunch'));
      const dEaten = dayScans.some((s: any) => (s.mealType || '').toLowerCase().includes('dinner'));

      const bPrice = isSunday ? 0 : 25;
      const lPrice = isSunday ? 100 : 50;
      const dPrice = isWednesday ? 100 : 50;

      const dayTotal = (bEaten ? bPrice : 0) + (lEaten ? lPrice : 0) + (dEaten ? dPrice : 0);

      dailyItems.push({
        date: dateStr,
        dayName: dateObj.toLocaleDateString('en-US', { weekday: 'long' }),
        dateFormatted: dateObj.toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' }),
        breakfast: { eaten: bEaten, price: bPrice },
        lunch: { eaten: lEaten, price: lPrice },
        dinner: { eaten: dEaten, price: dPrice },
        dayTotal,
      });
    });

    dailyItems.sort((a, b) => b.date.localeCompare(a.date));

    const totalMealsEaten = dailyItems.reduce(
      (sum, d) => sum + (d.breakfast.eaten ? 1 : 0) + (d.lunch.eaten ? 1 : 0) + (d.dinner.eaten ? 1 : 0),
      0
    );
    const totalMonthAmount = dailyItems.reduce((sum, d) => sum + d.dayTotal, 0);
    const breakfastCount = dailyItems.filter((d) => d.breakfast.eaten).length;
    const lunchCount = dailyItems.filter((d) => d.lunch.eaten).length;
    const dinnerCount = dailyItems.filter((d) => d.dinner.eaten).length;
    const messOffRebate = studentMessOffs.length * 50;
    const advanceDeposit = 3000;
    const netBalance = advanceDeposit - totalMonthAmount;

    return {
      totalMealsEaten,
      totalMonthAmount,
      breakfastCount,
      lunchCount,
      dinnerCount,
      messOffCount: studentMessOffs.length,
      messOffRebate,
      advanceDeposit,
      netBalance,
      dailyItems,
    };
  };

  const filteredList = H4_STUDENTS_LIST.filter((student) => {
    const att = attendanceMap[student.registrationNo] || { status: 'absent' };
    
    // Status Filter (Default 'Present' shows only eaten students)
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

  const selectedBillDetails = selectedStudentForBill ? computeStudentBill(selectedStudentForBill) : null;

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
            Student Attendance & Bill Ledger ({totalCount} Boarders)
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Showing students who have eaten. Click on any student to inspect their live mess bill and deductions.
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
              placeholder="Search eaten students by name, roll, reg no, room..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full text-xs pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-600 focus:outline-none"
            />
          </div>

          {/* Status & Branch Filters */}
          <div className="flex items-center gap-2 flex-wrap w-full md:w-auto">
            {/* Status Filter */}
            <div className="flex items-center gap-1 bg-gray-50 p-1 rounded-xl border border-gray-200">
              {['Present', 'All', 'Mess-Off', 'Absent'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setStatusFilter(tab)}
                  className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
                    statusFilter === tab
                      ? 'bg-primary-800 text-white shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {tab === 'Present' ? `Eaten (${presentCount})` : tab}
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

      {/* Master Students Attendance Table */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
          <div>
            <h3 className="font-bold text-gray-900 text-sm">
              {statusFilter === 'Present' ? `Students Who Have Eaten (${filteredList.length})` : `Attendance Ledger (${filteredList.length})`}
            </h3>
            <p className="text-xs text-gray-500">Click on any row or 'View Bill' to inspect student's real-time consumption bill & deductions.</p>
          </div>
        </div>

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
                <th className="py-3 px-4">Scan Time & Plate Token</th>
                <th className="py-3 px-4 text-center">Action</th>
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
                    onClick={() => setSelectedStudentForBill(student)}
                    className={`cursor-pointer hover:bg-emerald-50/50 transition-colors ${
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
                          <span className="text-[10px] font-mono text-gray-500 font-semibold">{att.token}</span>
                        </div>
                      ) : isMessOff ? (
                        <span className="text-amber-800 text-xs font-semibold">Exempted (Rebate Credited)</span>
                      ) : (
                        <span className="text-gray-400 text-xs italic">Awaiting Student QR Camera Scan</span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedStudentForBill(student);
                        }}
                        className="bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 px-2.5 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1 mx-auto transition-colors"
                      >
                        <Receipt className="w-3.5 h-3.5" />
                        View Bill
                      </button>
                    </td>
                  </tr>
                );
              })}

              {filteredList.length === 0 && (
                <tr>
                  <td colSpan={9} className="text-center py-10 text-gray-500 text-sm font-medium">
                    No students found matching your filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* STUDENT MESS BILL & CONSUMPTION MODAL */}
      {selectedStudentForBill && selectedBillDetails && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            {/* Header */}
            <div className="p-5 border-b border-gray-100 flex items-center justify-between bg-primary-900 text-white">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-base">
                  {selectedStudentForBill.name[0]}
                </div>
                <div>
                  <h3 className="font-bold text-base">{selectedStudentForBill.name}</h3>
                  <p className="text-xs text-primary-200">
                    Roll: {selectedStudentForBill.rollNo} • Reg: {selectedStudentForBill.registrationNo} • Room {selectedStudentForBill.roomNo} ({selectedStudentForBill.branch})
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedStudentForBill(null)}
                className="text-white/80 hover:text-white p-1 rounded-lg hover:bg-white/10"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Scrollable Bill Content */}
            <div className="p-6 overflow-y-auto space-y-5 text-gray-800">
              {/* Main Total Amount Card */}
              <div className="bg-gradient-to-br from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-5 text-white shadow-md">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-primary-200 tracking-wider uppercase">Current Month Consumption Bill</span>
                  <span className="text-xs bg-white/20 px-2.5 py-0.5 rounded-full font-bold">
                    {selectedBillDetails.totalMealsEaten} Verified Meals
                  </span>
                </div>
                <div className="mt-2 flex items-baseline gap-2">
                  <span className="text-3xl font-black">₹{selectedBillDetails.totalMonthAmount}</span>
                  <span className="text-xs text-primary-200">total food eaten</span>
                </div>

                {/* 3 Metrics Strip */}
                <div className="grid grid-cols-3 gap-2 mt-4 pt-3 border-t border-white/20 text-xs">
                  <div>
                    <span className="text-primary-200 block text-[10px]">Advance Deposit</span>
                    <span className="font-bold text-sm">₹{selectedBillDetails.advanceDeposit}</span>
                  </div>
                  <div>
                    <span className="text-amber-300 block text-[10px]">Mess-Off Rebate</span>
                    <span className="font-bold text-sm text-amber-300">₹{selectedBillDetails.messOffRebate}</span>
                  </div>
                  <div>
                    <span className="text-primary-200 block text-[10px]">Remaining Balance</span>
                    <span className={`font-bold text-sm ${selectedBillDetails.netBalance >= 0 ? 'text-emerald-300' : 'text-red-300'}`}>
                      ₹{selectedBillDetails.netBalance}
                    </span>
                  </div>
                </div>
              </div>

              {/* Rate & Count Summary Chips */}
              <div>
                <h4 className="font-bold text-xs text-gray-700 uppercase tracking-wider mb-2">Meal Consumption Breakdown</h4>
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-amber-50 border border-amber-200 p-3 rounded-xl">
                    <span className="text-xs font-bold text-amber-900 block">Breakfast</span>
                    <span className="text-base font-black text-gray-900">{selectedBillDetails.breakfastCount}</span>
                    <span className="text-[10px] text-amber-800 font-semibold block">@ ₹25 / plate</span>
                  </div>

                  <div className="bg-blue-50 border border-blue-200 p-3 rounded-xl">
                    <span className="text-xs font-bold text-blue-900 block">Lunch</span>
                    <span className="text-base font-black text-gray-900">{selectedBillDetails.lunchCount}</span>
                    <span className="text-[10px] text-blue-800 font-semibold block">@ ₹50 / ₹100</span>
                  </div>

                  <div className="bg-purple-50 border border-purple-200 p-3 rounded-xl">
                    <span className="text-xs font-bold text-purple-900 block">Dinner</span>
                    <span className="text-base font-black text-gray-900">{selectedBillDetails.dinnerCount}</span>
                    <span className="text-[10px] text-purple-800 font-semibold block">@ ₹50 / ₹100</span>
                  </div>
                </div>
              </div>

              {/* Daily Consumption Log */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-bold text-xs text-gray-700 uppercase tracking-wider">
                    Daily Verified Attendance Log
                  </h4>
                  <span className="text-xs text-gray-500 font-medium">{selectedBillDetails.dailyItems.length} days recorded</span>
                </div>

                {selectedBillDetails.dailyItems.length === 0 ? (
                  <div className="bg-gray-50 p-6 rounded-xl text-center text-gray-500 text-xs border border-gray-200">
                    No verified attendance records found for this student this month.
                  </div>
                ) : (
                  <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                    {selectedBillDetails.dailyItems.map((item) => (
                      <div
                        key={item.date}
                        className="bg-gray-50 border border-gray-200 rounded-xl p-3 flex items-center justify-between text-xs"
                      >
                        <div>
                          <span className="font-bold text-gray-900 block">{item.dayName}</span>
                          <span className="text-[10px] text-gray-500">{item.dateFormatted}</span>
                        </div>

                        <div className="flex items-center gap-2">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            item.breakfast.eaten ? 'bg-amber-100 text-amber-900' : 'bg-gray-200 text-gray-500'
                          }`}>
                            B: {item.breakfast.eaten ? `₹${item.breakfast.price}` : '—'}
                          </span>

                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            item.lunch.eaten ? 'bg-blue-100 text-blue-900' : 'bg-gray-200 text-gray-500'
                          }`}>
                            L: {item.lunch.eaten ? `₹${item.lunch.price}` : '—'}
                          </span>

                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            item.dinner.eaten ? 'bg-purple-100 text-purple-900' : 'bg-gray-200 text-gray-500'
                          }`}>
                            D: {item.dinner.eaten ? `₹${item.dinner.price}` : '—'}
                          </span>

                          <span className="bg-emerald-100 text-emerald-900 font-bold px-2.5 py-0.5 rounded-lg ml-2">
                            ₹{item.dayTotal}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-gray-100 bg-gray-50 flex justify-end">
              <button
                onClick={() => setSelectedStudentForBill(null)}
                className="bg-gray-200 hover:bg-gray-300 text-gray-800 px-4 py-2 rounded-xl text-xs font-bold transition-colors"
              >
                Close Audit
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
