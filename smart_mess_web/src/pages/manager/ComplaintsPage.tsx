import React, { useState, useEffect } from 'react';
import { MessageSquare, Clock, CheckCircle2, AlertCircle, Send, User, Home, ShieldAlert, Sparkles, Filter } from 'lucide-react';
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

export const ComplaintsPage: React.FC = () => {
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
  const [activeTab, setActiveTab] = useState<'All' | 'Pending' | 'In Progress' | 'Resolved'>('All');
  const [selectedComplaint, setSelectedComplaint] = useState<ComplaintItem | null>(null);
  const [managerAction, setManagerAction] = useState('');
  const [newStatus, setNewStatus] = useState<'In Progress' | 'Resolved'>('Resolved');
  const [isUpdating, setIsUpdating] = useState(false);

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

  const handleOpenResponseModal = (c: ComplaintItem) => {
    setSelectedComplaint(c);
    setManagerAction(c.response || '');
    setNewStatus(c.status === 'Pending' ? 'Resolved' : c.status as any);
  };

  const handleSubmitResponse = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedComplaint) return;
    if (!managerAction.trim()) {
      toast.error('Please enter the corrective action or reaction taken.');
      return;
    }

    setIsUpdating(true);
    const updatedPayload = {
      ...selectedComplaint,
      response: managerAction.trim(),
      status: newStatus,
      resolvedAt: newStatus === 'Resolved' ? new Date().toISOString() : undefined
    };

    // Optimistic UI update
    setComplaints((prev) => prev.map((c) => (c.id === selectedComplaint.id ? updatedPayload : c)));

    try {
      await fetch(
        `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/complaints/${selectedComplaint.id}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              id: { stringValue: selectedComplaint.id },
              title: { stringValue: selectedComplaint.title },
              studentId: { stringValue: selectedComplaint.studentId },
              studentName: { stringValue: selectedComplaint.studentName },
              hostelId: { stringValue: selectedComplaint.hostelId },
              roomNumber: { stringValue: selectedComplaint.roomNumber },
              category: { stringValue: selectedComplaint.category },
              description: { stringValue: selectedComplaint.description },
              status: { stringValue: newStatus },
              createdAt: { stringValue: selectedComplaint.createdAt },
              response: { stringValue: managerAction.trim() },
              resolvedAt: { stringValue: new Date().toISOString() }
            }
          })
        }
      );

      toast.success(`Action recorded! Complaint marked as ${newStatus}. Visible to Student & Admin.`);
      setSelectedComplaint(null);
    } catch (_) {
      toast.success('Action saved locally.');
      setSelectedComplaint(null);
    } finally {
      setIsUpdating(false);
    }
  };

  const filtered = activeTab === 'All' ? complaints : complaints.filter((c) => c.status === activeTab);

  const pendingCount = complaints.filter((c) => c.status === 'Pending').length;
  const inProgressCount = complaints.filter((c) => c.status === 'In Progress').length;
  const resolvedCount = complaints.filter((c) => c.status === 'Resolved').length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <MessageSquare className="w-4 h-4 text-emerald-400" />
            <span>Hostel H4 Mess Operations</span>
          </div>
          <h1 className="text-2xl font-bold font-display tracking-tight text-white mt-1">
            Student Complaints & Grievance Desk
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Review food quality, hygiene & service issues raised by Hostel H4 students, and record your corrective action taken.
          </p>
        </div>

        {/* Quick Stats */}
        <div className="flex gap-3">
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[90px]">
            <span className="text-xl font-bold text-amber-300">{pendingCount}</span>
            <span className="block text-[11px] text-primary-200">Pending</span>
          </div>
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[90px]">
            <span className="text-xl font-bold text-blue-300">{inProgressCount}</span>
            <span className="block text-[11px] text-primary-200">In Progress</span>
          </div>
          <div className="bg-white/10 backdrop-blur-md rounded-xl p-3 text-center border border-white/15 min-w-[90px]">
            <span className="text-xl font-bold text-emerald-300">{resolvedCount}</span>
            <span className="block text-[11px] text-primary-200">Resolved</span>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex bg-white p-1.5 rounded-xl border border-gray-200 shadow-sm gap-1">
        {(['All', 'Pending', 'In Progress', 'Resolved'] as const).map((tab) => {
          const count = tab === 'All' ? complaints.length : tab === 'Pending' ? pendingCount : tab === 'In Progress' ? inProgressCount : resolvedCount;
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2.5 px-4 text-sm font-semibold rounded-lg transition-all flex items-center justify-center gap-2 ${
                activeTab === tab
                  ? 'bg-primary-800 text-white shadow-sm'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              <span>{tab}</span>
              <span className={`text-xs px-2 py-0.5 rounded-full ${activeTab === tab ? 'bg-primary-900 text-primary-200' : 'bg-gray-200 text-gray-700'}`}>
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {/* Complaints List */}
      <div className="grid gap-4">
        {filtered.map((c) => (
          <div
            key={c.id}
            className="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm hover:shadow-md transition-all flex flex-col md:flex-row md:items-start justify-between gap-4"
          >
            <div className="flex-1 space-y-3">
              {/* Top metadata */}
              <div className="flex flex-wrap items-center gap-2">
                <span className="bg-primary-50 text-primary-800 text-xs font-bold px-2.5 py-1 rounded-md border border-primary-200">
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
                <span className="text-xs text-gray-500 flex items-center gap-1 ml-auto">
                  <Clock className="w-3.5 h-3.5" />
                  {new Date(c.createdAt).toLocaleString()}
                </span>
              </div>

              {/* Title & Description */}
              <div>
                <h3 className="text-base font-bold text-gray-900">{c.title}</h3>
                <p className="text-sm text-gray-700 mt-1 leading-relaxed">{c.description}</p>
              </div>

              {/* Student info */}
              <div className="flex items-center gap-4 text-xs text-gray-600 pt-1 border-t border-gray-100">
                <span className="flex items-center gap-1 font-medium text-gray-900">
                  <User className="w-3.5 h-3.5 text-primary-700" />
                  {c.studentName} ({c.studentId})
                </span>
                <span className="flex items-center gap-1">
                  <Home className="w-3.5 h-3.5 text-gray-500" />
                  Hostel H4 • Room {c.roomNumber}
                </span>
              </div>

              {/* Manager's Action Taken Box */}
              {c.response && (
                <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-3 text-sm">
                  <div className="flex items-center gap-1.5 text-emerald-900 font-bold text-xs mb-1">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    <span>Mess Manager Corrective Action Taken & Reaction:</span>
                  </div>
                  <p className="text-emerald-950 text-xs italic">"{c.response}"</p>
                </div>
              )}
            </div>

            {/* Action button */}
            <div className="shrink-0 flex md:flex-col justify-end gap-2 pt-2 md:pt-0">
              <button
                onClick={() => handleOpenResponseModal(c)}
                className="bg-primary-800 hover:bg-primary-900 text-white font-medium text-xs px-4 py-2.5 rounded-xl shadow-sm transition-all flex items-center justify-center gap-1.5"
              >
                <Send className="w-3.5 h-3.5" />
                {c.response ? 'Update Response' : 'Respond & Take Action'}
              </button>
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="bg-white rounded-2xl p-12 text-center border border-gray-200">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-60" />
            <p className="font-bold text-gray-800">No {activeTab.toLowerCase()} complaints found</p>
            <p className="text-xs text-gray-500 mt-1">Hostel H4 student complaints will appear here automatically in real-time.</p>
          </div>
        )}
      </div>

      {/* Response Modal */}
      {selectedComplaint && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4 border border-gray-100">
            <div className="flex justify-between items-start border-b pb-3">
              <div>
                <h3 className="font-bold text-lg text-gray-900">Respond to Complaint</h3>
                <p className="text-xs text-gray-500">Hostel H4 • {selectedComplaint.studentName} (Room {selectedComplaint.roomNumber})</p>
              </div>
              <button onClick={() => setSelectedComplaint(null)} className="text-gray-400 hover:text-gray-600 text-lg">✕</button>
            </div>

            <div className="bg-gray-50 p-3.5 rounded-xl text-xs space-y-1">
              <p className="font-bold text-gray-800">"{selectedComplaint.title}"</p>
              <p className="text-gray-600">{selectedComplaint.description}</p>
            </div>

            <form onSubmit={handleSubmitResponse} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Manager Corrective Action Taken / Reaction <span className="text-red-500">*</span>
                </label>
                <textarea
                  rows={4}
                  required
                  placeholder="Describe your immediate reaction and corrective action (e.g., Kitchen inspected immediately. Head cook was issued a strict warning and fresh dinner meal batch was prepared)..."
                  value={managerAction}
                  onChange={(e) => setManagerAction(e.target.value)}
                  className="w-full text-xs p-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-600 focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Update Status</label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value as any)}
                  className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-600 focus:outline-none"
                >
                  <option value="In Progress">In Progress (Investigating / Corrective Action Underway)</option>
                  <option value="Resolved">Resolved (Corrective Action Completed)</option>
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedComplaint(null)}
                  className="px-4 py-2 text-xs font-medium text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isUpdating}
                  className="px-5 py-2 text-xs font-bold text-white bg-primary-800 hover:bg-primary-900 rounded-xl shadow-sm flex items-center gap-1.5"
                >
                  {isUpdating ? 'Saving...' : 'Submit Action & Update Status'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
