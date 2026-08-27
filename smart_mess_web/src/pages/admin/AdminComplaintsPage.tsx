import React, { useState, useEffect } from 'react';
import { ShieldCheck, MessageSquare, CheckCircle2, Clock, User, Home, AlertCircle, Search, Filter, Sparkles, ChefHat } from 'lucide-react';
import toast from 'react-hot-toast';

interface ComplaintItem {
  id: string;
  title: string;
  studentId: string;
  studentName: string;
  hostelId: string;
  roomNumber: string;
  category: string;
  description: string;
  status: 'Pending' | 'In Progress' | 'Resolved';
  createdAt: string;
  response?: string;
  resolvedAt?: string;
}

export const AdminComplaintsPage: React.FC = () => {
  const [complaints, setComplaints] = useState<ComplaintItem[]>([
    {
      id: 'cmp_sample_1',
      title: 'Undercooked Rice during Lunch',
      studentId: '21BCSE042',
      studentName: 'Priyanshu Sharma',
      hostelId: 'Hostel H4',
      roomNumber: '204',
      category: 'Food Quality / Taste',
      description: 'The plain rice served in today\'s lunch was hard and undercooked.',
      status: 'In Progress',
      createdAt: new Date(Date.now() - 3 * 3600 * 1000).toISOString(),
      response: 'Inspected kitchen. Cook instructed to recalibrate rice steamer timing.'
    }
  ]);
  const [activeTab, setActiveTab] = useState<'All' | 'Pending' | 'In Progress' | 'Resolved' | 'Action Taken'>('All');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchLiveComplaints = async () => {
    try {
      const res = await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'complaints' }]
            }
          })
        }
      );
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          const list: ComplaintItem[] = [];
          for (const item of data) {
            if (item.document && item.document.fields) {
              const f = item.document.fields;
              const id = f.id?.stringValue || item.document.name.split('/').pop() || 'cmp';
              list.push({
                id,
                title: f.title?.stringValue || f.category?.stringValue || 'Complaint',
                studentId: f.studentId?.stringValue || '21BCSE042',
                studentName: f.studentName?.stringValue || 'Student',
                hostelId: f.hostelId?.stringValue || 'Hostel H4',
                roomNumber: f.roomNumber?.stringValue || '204',
                category: f.category?.stringValue || 'Food Quality',
                description: f.description?.stringValue || '',
                status: (f.status?.stringValue as any) || 'Pending',
                createdAt: f.createdAt?.stringValue || new Date().toISOString(),
                response: f.response?.stringValue || f.managerResponse?.stringValue,
                resolvedAt: f.resolvedAt?.stringValue
              });
            }
          }
          if (list.length > 0) {
            list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
            setComplaints(list);
          }
        }
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchLiveComplaints();
    const interval = setInterval(fetchLiveComplaints, 3000);
    return () => clearInterval(interval);
  }, []);

  const pendingCount = complaints.filter((c) => c.status === 'Pending').length;
  const inProgressCount = complaints.filter((c) => c.status === 'In Progress').length;
  const resolvedCount = complaints.filter((c) => c.status === 'Resolved').length;
  const respondedCount = complaints.filter((c) => c.response && c.response.trim().length > 0).length;

  const filtered = complaints.filter((c) => {
    // Tab filter
    if (activeTab === 'Pending' && c.status !== 'Pending') return false;
    if (activeTab === 'In Progress' && c.status !== 'In Progress') return false;
    if (activeTab === 'Resolved' && c.status !== 'Resolved') return false;
    if (activeTab === 'Action Taken' && (!c.response || c.response.trim().length === 0)) return false;

    // Search filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        c.studentName.toLowerCase().includes(q) ||
        c.studentId.toLowerCase().includes(q) ||
        c.roomNumber.toLowerCase().includes(q) ||
        c.title.toLowerCase().includes(q) ||
        c.category.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-primary-950 to-slate-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4 border border-primary-900/40">
        <div>
          <div className="flex items-center gap-2 text-emerald-400 text-sm font-medium">
            <ShieldCheck className="w-4 h-4" />
            <span>Institute Administrative Oversight</span>
          </div>
          <h1 className="text-2xl font-bold font-display tracking-tight text-white mt-1">
            Hostel H4 Complaints & Mess Manager Accountability
          </h1>
          <p className="text-slate-300 text-sm mt-1">
            Track student grievances from Hostel H4 and review the corrective actions taken by the Mess Manager in real-time.
          </p>
        </div>

        {/* Oversight Metrics */}
        <div className="flex gap-2.5 flex-wrap">
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[85px]">
            <span className="text-lg font-bold text-white">{complaints.length}</span>
            <span className="block text-[10.5px] text-slate-300">Total</span>
          </div>
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[85px]">
            <span className="text-lg font-bold text-amber-300">{pendingCount}</span>
            <span className="block text-[10.5px] text-slate-300">Pending</span>
          </div>
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[85px]">
            <span className="text-lg font-bold text-blue-300">{inProgressCount}</span>
            <span className="block text-[10.5px] text-slate-300">In Progress</span>
          </div>
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[85px]">
            <span className="text-lg font-bold text-emerald-300">{resolvedCount}</span>
            <span className="block text-[10.5px] text-slate-300">Resolved</span>
          </div>
          <div className="bg-emerald-500/20 backdrop-blur-md rounded-xl p-3 text-center border border-emerald-400/30 min-w-[100px]">
            <span className="text-lg font-bold text-emerald-300">{respondedCount}/{complaints.length}</span>
            <span className="block text-[10.5px] text-emerald-200">Manager Acted</span>
          </div>
        </div>
      </div>

      {/* Search and Tabs Row */}
      <div className="flex flex-col md:flex-row gap-3 items-center justify-between">
        {/* Tabs */}
        <div className="flex bg-white p-1 rounded-xl border border-gray-200 shadow-sm gap-1 w-full md:w-auto">
          {(['All', 'Pending', 'In Progress', 'Resolved', 'Action Taken'] as const).map((tab) => {
            const count = tab === 'All' ? complaints.length : tab === 'Pending' ? pendingCount : tab === 'In Progress' ? inProgressCount : tab === 'Resolved' ? resolvedCount : respondedCount;
            return (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`py-2 px-3.5 text-xs font-semibold rounded-lg transition-all flex items-center gap-1.5 ${
                  activeTab === tab
                    ? 'bg-primary-900 text-white shadow-sm'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <span>{tab}</span>
                <span className={`text-[10px] px-1.5 py-0.2 rounded-full ${activeTab === tab ? 'bg-primary-950 text-emerald-300' : 'bg-gray-200 text-gray-700'}`}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Search bar */}
        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Search by student, room, issue..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full text-xs pl-9 pr-3 py-2 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-600 focus:outline-none shadow-sm"
          />
        </div>
      </div>

      {/* Complaints Oversight Cards */}
      <div className="grid gap-4">
        {filtered.map((c) => (
          <div
            key={c.id}
            className="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm space-y-4 hover:border-gray-300 transition-all"
          >
            {/* Top row */}
            <div className="flex flex-wrap items-center justify-between gap-2 border-b border-gray-100 pb-3">
              <div className="flex items-center gap-2">
                <span className="bg-slate-900 text-white font-bold text-xs px-2.5 py-1 rounded-md">
                  Hostel H4
                </span>
                <span className="bg-primary-50 text-primary-800 text-xs font-semibold px-2.5 py-1 rounded-md border border-primary-200">
                  {c.category}
                </span>
                <span
                  className={`text-xs font-bold px-2.5 py-1 rounded-md flex items-center gap-1 ${
                    c.status === 'Resolved'
                      ? 'bg-emerald-100 text-emerald-800'
                      : c.status === 'In Progress'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-amber-100 text-amber-800'
                  }`}
                >
                  <span className={`w-2 h-2 rounded-full ${c.status === 'Resolved' ? 'bg-emerald-600' : c.status === 'In Progress' ? 'bg-blue-600' : 'bg-amber-600'}`} />
                  {c.status}
                </span>
              </div>

              <div className="text-xs text-gray-500 flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                {new Date(c.createdAt).toLocaleString()}
              </div>
            </div>

            {/* Student & Issue Details */}
            <div className="grid md:grid-cols-3 gap-4">
              <div className="md:col-span-2 space-y-2">
                <div>
                  <h3 className="text-base font-bold text-gray-900">{c.title}</h3>
                  <p className="text-xs text-gray-700 mt-1 leading-relaxed bg-gray-50 p-3 rounded-xl border border-gray-100">
                    "{c.description}"
                  </p>
                </div>
                <div className="flex items-center gap-4 text-xs text-gray-600">
                  <span className="flex items-center gap-1 font-semibold text-gray-900">
                    <User className="w-3.5 h-3.5 text-primary-700" />
                    {c.studentName} (Roll: {c.studentId})
                  </span>
                  <span className="flex items-center gap-1">
                    <Home className="w-3.5 h-3.5 text-gray-500" />
                    Room {c.roomNumber}
                  </span>
                </div>
              </div>

              {/* Mess Manager Reaction / Response Box */}
              <div className="md:col-span-1">
                {c.response ? (
                  <div className="bg-emerald-50/90 border border-emerald-300 rounded-xl p-3.5 h-full flex flex-col justify-between space-y-2 shadow-sm">
                    <div>
                      <div className="flex items-center gap-1.5 text-emerald-900 font-bold text-xs">
                        <ChefHat className="w-4 h-4 text-emerald-700" />
                        <span>Mess Manager Action Taken:</span>
                      </div>
                      <p className="text-emerald-950 text-xs italic mt-1.5 leading-relaxed">
                        "{c.response}"
                      </p>
                    </div>
                    <div className="flex items-center justify-between text-[10.5px] text-emerald-800 pt-2 border-t border-emerald-200">
                      <span className="flex items-center gap-1 font-semibold text-emerald-900">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                        Manager Responded
                      </span>
                      <span>{c.resolvedAt ? new Date(c.resolvedAt).toLocaleTimeString() : 'Verified'}</span>
                    </div>
                  </div>
                ) : (
                  <div className="bg-amber-50/80 border border-amber-200 rounded-xl p-3.5 h-full flex flex-col justify-center items-center text-center space-y-1 text-xs">
                    <AlertCircle className="w-5 h-5 text-amber-600 mb-1" />
                    <span className="font-bold text-amber-900">Awaiting Manager Action</span>
                    <span className="text-amber-700 text-[11px]">Mess Manager has not yet recorded action.</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="bg-white rounded-2xl p-12 text-center border border-gray-200">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-60" />
            <p className="font-bold text-gray-800">No complaints found</p>
            <p className="text-xs text-gray-500 mt-1">Hostel H4 student complaints will update here in real-time.</p>
          </div>
        )}
      </div>
    </div>
  );
};
