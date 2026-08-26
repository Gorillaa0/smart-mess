import React, { useState } from 'react';
import { 
  CalendarOff, Utensils, Users, DollarSign, Clock, AlertTriangle, 
  Download, Search, Filter, Building2, CheckCircle2, XCircle, Printer, ChefHat
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
  mealType: 'Breakfast' | 'Lunch' | 'Dinner' | 'Full Day';
  date: string;
  requestedAt: string;
  reason: string;
  status: 'Approved' | 'Overridden (Ate Meal)' | 'Cancelled';
  refundCredited: number;
}

const MOCK_MESS_OFFS: MessOffEntry[] = [
  {
    id: 'mo_01',
    studentName: 'Harshit Raj',
    rollNo: '23105108034',
    registrationNo: '23105108034',
    roomNo: '118',
    branch: 'CSE',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '09:42 AM (1h 18m before deadline)',
    reason: 'Department Project Field Visit in Town',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_02',
    studentName: 'Prince Kumar',
    rollNo: '23105108036',
    registrationNo: '23105108036',
    roomNo: '120',
    branch: 'CSE',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '08:15 AM (2h 45m before deadline)',
    reason: 'Visiting Home for Family Function',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_03',
    studentName: 'Ravi Kumar',
    rollNo: '23105108037',
    registrationNo: '23105108037',
    roomNo: '121',
    branch: 'CSE',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '10:12 AM (48m before deadline)',
    reason: 'Medical Appointment at Clinic',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_04',
    studentName: 'Vikas Kumar',
    rollNo: '23105108039',
    registrationNo: '23105108039',
    roomNo: '123',
    branch: 'CSE',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '07:30 AM',
    reason: 'Exam Preparation / Fasting',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_05',
    studentName: 'Abhishek Kumar',
    rollNo: '23105108040',
    registrationNo: '23105108040',
    roomNo: '124',
    branch: 'Civil',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '09:05 AM',
    reason: 'Visiting Local Relative',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_06',
    studentName: 'Shivam Kumar',
    rollNo: '23105108041',
    registrationNo: '23105108041',
    roomNo: '125',
    branch: 'Civil',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '10:50 AM (10m before deadline)',
    reason: 'Emergency Travel to Patna',
    status: 'Approved',
    refundCredited: 50
  },
  {
    id: 'mo_07',
    studentName: 'Sonu Kumar',
    rollNo: '23105108042',
    registrationNo: '23105108042',
    roomNo: '126',
    branch: 'Civil',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '08:40 AM',
    reason: 'Attending Seminar at City Campus',
    status: 'Overridden (Ate Meal)',
    refundCredited: 0
  },
  {
    id: 'mo_08',
    studentName: 'Rajesh Kumar',
    rollNo: '23105108043',
    registrationNo: '23105108043',
    roomNo: '127',
    branch: 'ECE',
    mealType: 'Lunch',
    date: '2026-08-26',
    requestedAt: '09:15 AM',
    reason: 'Cancelled before deadline',
    status: 'Cancelled',
    refundCredited: 0
  }
];

export const MessOffsPage: React.FC = () => {
  const [selectedMeal, setSelectedMeal] = useState<'Breakfast' | 'Lunch' | 'Dinner'>('Lunch');
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [messOffs, setMessOffs] = useState<MessOffEntry[]>(MOCK_MESS_OFFS);

  const totalCapacity = 112; // Hostel 4 Total Capacity
  const activeOptOuts = messOffs.filter((m) => m.status === 'Approved').length; // 6
  const overriddenCount = messOffs.filter((m) => m.status === 'Overridden (Ate Meal)').length; // 1
  const expectedDiners = totalCapacity - activeOptOuts; // 106
  const totalRebate = activeOptOuts * 50; // ₹300

  const handlePrintSlip = () => {
    window.print();
    toast.success('Kitchen Portion Slip sent to printer!');
  };

  const handleExportCSV = () => {
    const headers = 'Student Name,Roll No,Registration No,Branch,Room,Meal,Requested At,Reason,Status,Rebate\n';
    const rows = messOffs.map((m) =>
      `"${m.studentName}","${m.rollNo}","${m.registrationNo}","${m.branch}","Room ${m.roomNo}","${m.mealType}","${m.requestedAt}","${m.reason}","${m.status}","₹${m.refundCredited}"`
    ).join('\n');

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `Hostel4_Mess_Offs_${selectedMeal}_2026-08-26.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success(`Exported ${selectedMeal} Mess-Off Roster!`);
  };

  const filtered = messOffs.filter((m) => {
    const matchesStatus = statusFilter === 'All' || m.status.startsWith(statusFilter);
    const cleanQ = searchQuery.toLowerCase().trim();
    const matchesSearch =
      cleanQ === '' ||
      m.studentName.toLowerCase().includes(cleanQ) ||
      m.rollNo.includes(cleanQ) ||
      m.roomNo.includes(cleanQ) ||
      m.reason.toLowerCase().includes(cleanQ);

    return matchesStatus && matchesSearch;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            Hostel Number 4 • Mess Manager Portal
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Student Mess-Off & Leave Ledger
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Review resident opt-out requests, adjust kitchen preparation quantities, and track fee rebates
          </p>
        </div>

        {/* Meal Selector & Print Action */}
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
            onClick={handlePrintSlip}
            className="flex items-center gap-1.5 bg-amber-500 hover:bg-amber-600 text-slate-900 px-3.5 py-2 rounded-xl font-bold text-xs shadow transition-all"
          >
            <Printer className="w-4 h-4" />
            <span>Kitchen Slip</span>
          </button>

          <button
            onClick={handleExportCSV}
            className="flex items-center gap-1.5 bg-white text-primary-900 px-3.5 py-2 rounded-xl font-bold text-xs shadow hover:bg-primary-50 transition-all"
          >
            <Download className="w-4 h-4 text-primary-800" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* 4 Key Operational Metrics */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div className="flex items-center justify-between text-gray-500 text-xs font-semibold">
            <span>Total Hostel Capacity</span>
            <Users className="w-4 h-4 text-gray-400" />
          </div>
          <p className="text-2xl font-display font-bold text-gray-900 mt-1">{totalCapacity} Residents</p>
          <p className="text-xs text-gray-400 mt-0.5">Hostel Number 4</p>
        </div>

        <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 shadow-sm">
          <div className="flex items-center justify-between text-amber-800 text-xs font-bold">
            <span>🟡 Approved Mess-Offs</span>
            <CalendarOff className="w-4 h-4 text-amber-600" />
          </div>
          <p className="text-2xl font-display font-bold text-amber-900 mt-1">{activeOptOuts} Students</p>
          <p className="text-xs text-amber-700 mt-0.5">Will NOT eat {selectedMeal}</p>
        </div>

        <div className="bg-emerald-50 p-4 rounded-xl border border-emerald-200 shadow-sm">
          <div className="flex items-center justify-between text-emerald-800 text-xs font-bold">
            <span>👨‍🍳 Cook Preparation Target</span>
            <ChefHat className="w-4 h-4 text-emerald-600" />
          </div>
          <p className="text-2xl font-display font-bold text-[#1B5E20] mt-1">{expectedDiners} Portions</p>
          <p className="text-xs text-emerald-700 mt-0.5">Reduced from {totalCapacity} (Saves food)</p>
        </div>

        <div className="bg-blue-50 p-4 rounded-xl border border-blue-200 shadow-sm">
          <div className="flex items-center justify-between text-blue-800 text-xs font-bold">
            <span>💰 Meal Fee Rebates</span>
            <DollarSign className="w-4 h-4 text-blue-600" />
          </div>
          <p className="text-2xl font-display font-bold text-blue-900 mt-1">₹{totalRebate}</p>
          <p className="text-xs text-blue-700 mt-0.5">Credited to student ledgers</p>
        </div>
      </div>

      {/* Kitchen Advisory Notice */}
      <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-start gap-3">
        <ChefHat className="w-5 h-5 text-emerald-700 shrink-0 mt-0.5" />
        <div>
          <h4 className="text-xs font-bold text-emerald-950 uppercase tracking-wider">
            Kitchen Preparation Directive for Head Chef
          </h4>
          <p className="text-xs text-emerald-900 mt-0.5 leading-relaxed">
            Due to <strong>{activeOptOuts} approved resident mess-offs</strong>, kitchen staff should cook for exactly <strong>{expectedDiners} residents (+4 safety buffer = {expectedDiners + 4} plates)</strong> for today's {selectedMeal}. This prevents surplus cooking and avoids grain wastage.
          </p>
        </div>
      </div>

      {/* Filter & Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Search */}
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search student, room, reason..."
            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:bg-white"
          />
        </div>

        {/* Status Filter Tabs */}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="text-xs font-bold text-gray-500 mr-1">Status:</span>
          {['All', 'Approved', 'Overridden', 'Cancelled'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                statusFilter === st
                  ? st === 'Approved'
                    ? 'bg-amber-600 text-white'
                    : st === 'Overridden'
                    ? 'bg-red-600 text-white'
                    : st === 'Cancelled'
                    ? 'bg-gray-700 text-white'
                    : 'bg-[#1B5E20] text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Mess-Offs Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-left">
            <thead className="bg-gray-50/80 text-gray-600 text-xs font-bold uppercase tracking-wider">
              <tr>
                <th className="px-6 py-3.5">Student Details</th>
                <th className="px-4 py-3.5">Room & Branch</th>
                <th className="px-4 py-3.5">Meal Session</th>
                <th className="px-6 py-3.5">Reason & Category</th>
                <th className="px-6 py-3.5">Requested Timing</th>
                <th className="px-4 py-3.5">Status</th>
                <th className="px-4 py-3.5 text-right">Fee Rebate</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-gray-400">
                    No mess-off requests found matching current filters.
                  </td>
                </tr>
              ) : (
                filtered.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/70 transition-colors">
                    <td className="px-6 py-3.5">
                      <div className="font-bold text-gray-900">{item.studentName}</div>
                      <div className="text-xs text-gray-500 font-mono">Reg: {item.registrationNo}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-xs font-bold text-gray-800">Room {item.roomNo}</div>
                      <span className="inline-block px-1.5 py-0.5 rounded text-[10px] font-extrabold bg-gray-100 text-gray-700 mt-0.5">
                        {item.branch}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-900 border border-amber-200">
                        <Utensils className="w-3 h-3 text-amber-700" />
                        <span>{item.mealType}</span>
                      </span>
                    </td>
                    <td className="px-6 py-3.5">
                      <div className="text-xs text-gray-800 font-medium">{item.reason}</div>
                    </td>
                    <td className="px-6 py-3.5 text-xs text-gray-500">
                      <div className="flex items-center gap-1">
                        <Clock className="w-3 h-3 text-gray-400" />
                        <span>{item.requestedAt}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      {item.status === 'Approved' && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold border border-emerald-200">
                          <CheckCircle2 className="w-3 h-3 text-emerald-700" />
                          <span>Approved</span>
                        </span>
                      )}
                      {item.status === 'Overridden (Ate Meal)' && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-red-100 text-red-800 text-xs font-bold border border-red-200" title="Student scanned QR counter anyway. Waiver revoked.">
                          <AlertTriangle className="w-3 h-3 text-red-700" />
                          <span>Ate Anyway</span>
                        </span>
                      )}
                      {item.status === 'Cancelled' && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-gray-100 text-gray-700 text-xs font-bold">
                          <XCircle className="w-3 h-3 text-gray-500" />
                          <span>Cancelled</span>
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3.5 text-right font-mono font-bold text-xs">
                      {item.refundCredited > 0 ? (
                        <span className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200">
                          +₹{item.refundCredited}
                        </span>
                      ) : (
                        <span className="text-gray-400">₹0</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
