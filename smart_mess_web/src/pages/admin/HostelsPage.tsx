import React, { useState, useEffect } from 'react';
import { Building2, UserCheck, Phone, Mail, Plus, Edit, Trash2, Check, ShieldCheck, X, BedDouble } from 'lucide-react';
import toast from 'react-hot-toast';

export interface HostelItem {
  id: string;
  name: string;
  code: string;
  totalRooms: number;
  totalCapacity: number;
  activeResidents: number;
  wardenName: string;
  wardenMobile: string;
  wardenEmail: string;
  wardenOffice: string;
  status: 'Active' | 'Renovating';
}

const DEFAULT_HOSTELS: HostelItem[] = [
  {
    id: 'hostel_4',
    name: 'Hostel Number 4 (Senior Boys Hostel)',
    code: 'H-4',
    totalRooms: 60,
    totalCapacity: 120,
    activeResidents: 112,
    wardenName: 'Dr. S. K. Jha',
    wardenMobile: '9431201984',
    wardenEmail: 'warden.h4@bcebhagalpur.ac.in',
    wardenOffice: 'Ground Floor, Block-A Admin Room',
    status: 'Active'
  },
  {
    id: 'hostel_3',
    name: 'Hostel Number 3 (Junior Boys Hostel)',
    code: 'H-3',
    totalRooms: 70,
    totalCapacity: 140,
    activeResidents: 135,
    wardenName: 'Prof. R. K. Singh',
    wardenMobile: '9431405678',
    wardenEmail: 'warden.h3@bcebhagalpur.ac.in',
    wardenOffice: 'First Floor, Block-B Office',
    status: 'Active'
  }
];

export const HostelsPage: React.FC = () => {
  const [hostels, setHostels] = useState<HostelItem[]>(() => {
    const saved = localStorage.getItem('SMART_MESS_ALL_HOSTELS');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {}
    }
    return DEFAULT_HOSTELS;
  });

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingHostel, setEditingHostel] = useState<HostelItem | null>(null);

  const [form, setForm] = useState({
    name: '',
    code: 'H-4',
    totalRooms: 60,
    totalCapacity: 120,
    activeResidents: 112,
    wardenName: '',
    wardenMobile: '',
    wardenEmail: '',
    wardenOffice: '',
    status: 'Active' as 'Active' | 'Renovating'
  });

  useEffect(() => {
    localStorage.setItem('SMART_MESS_ALL_HOSTELS', JSON.stringify(hostels));
  }, [hostels]);

  const handleOpenAdd = () => {
    setForm({
      name: '',
      code: `H-${hostels.length + 1}`,
      totalRooms: 50,
      totalCapacity: 100,
      activeResidents: 0,
      wardenName: '',
      wardenMobile: '',
      wardenEmail: '',
      wardenOffice: '',
      status: 'Active'
    });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (hostel: HostelItem) => {
    setEditingHostel(hostel);
    setForm({
      name: hostel.name,
      code: hostel.code,
      totalRooms: hostel.totalRooms,
      totalCapacity: hostel.totalCapacity,
      activeResidents: hostel.activeResidents,
      wardenName: hostel.wardenName,
      wardenMobile: hostel.wardenMobile,
      wardenEmail: hostel.wardenEmail,
      wardenOffice: hostel.wardenOffice,
      status: hostel.status
    });
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.wardenName || !form.wardenMobile) {
      toast.error('Hostel Name, Warden Name, and Mobile are required');
      return;
    }

    if (editingHostel) {
      setHostels((prev) =>
        prev.map((h) =>
          h.id === editingHostel.id
            ? {
                ...h,
                name: form.name,
                code: form.code,
                totalRooms: Number(form.totalRooms),
                totalCapacity: Number(form.totalCapacity),
                activeResidents: Number(form.activeResidents),
                wardenName: form.wardenName,
                wardenMobile: form.wardenMobile,
                wardenEmail: form.wardenEmail || `${form.code.toLowerCase()}warden@bce.edu`,
                wardenOffice: form.wardenOffice || 'Hostel Admin Office',
                status: form.status
              }
            : h
        )
      );
      toast.success(`Updated hostel & assigned warden ${form.wardenName}!`);
      setEditingHostel(null);
    } else {
      const newHostel: HostelItem = {
        id: `hostel_${Date.now()}`,
        name: form.name,
        code: form.code,
        totalRooms: Number(form.totalRooms),
        totalCapacity: Number(form.totalCapacity),
        activeResidents: Number(form.activeResidents),
        wardenName: form.wardenName,
        wardenMobile: form.wardenMobile,
        wardenEmail: form.wardenEmail || `${form.code.toLowerCase()}warden@bce.edu`,
        wardenOffice: form.wardenOffice || 'Hostel Admin Office',
        status: form.status
      };
      setHostels((prev) => [...prev, newHostel]);
      toast.success(`Created hostel "${newHostel.name}" with warden ${newHostel.wardenName}!`);
      setIsAddModalOpen(false);
    }
  };

  const handleDelete = (id: string, name: string) => {
    if (id === 'hostel_4') {
      toast.error('Hostel Number 4 is the primary campus hostel and cannot be deleted.');
      return;
    }
    setHostels((prev) => prev.filter((h) => h.id !== id));
    toast.success(`Deleted ${name}`);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            Smart Mess Portal • Super Admin Console
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Campus Hostels & Warden Roster
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Manage residential buildings, room allocations, and assign official Hostel Wardens
          </p>
        </div>
        <button
          onClick={handleOpenAdd}
          className="flex items-center gap-2 bg-amber-500 hover:bg-amber-600 text-slate-900 px-4 py-2.5 rounded-xl font-bold text-xs shadow transition-all shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>Add New Hostel</span>
        </button>
      </div>

      {/* Hostels Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {hostels.map((h) => (
          <div key={h.id} className="bg-white rounded-2xl border border-gray-200 shadow-sm p-6 flex flex-col justify-between">
            <div>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl bg-blue-100 text-blue-800 flex items-center justify-center font-bold">
                    <Building2 className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg leading-tight">{h.name}</h3>
                    <p className="text-xs text-gray-500 font-medium mt-0.5">
                      Code: {h.code} • {h.activeResidents} Residents ({h.totalRooms} Rooms)
                    </p>
                  </div>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-blue-50 text-blue-800 border border-blue-200">
                  {h.status}
                </span>
              </div>

              {/* Warden Details Card */}
              <div className="mt-5 p-4 rounded-xl bg-blue-50/50 border border-blue-200 space-y-2.5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 text-xs font-bold text-blue-950">
                    <UserCheck className="w-4 h-4 text-blue-700" />
                    <span>Assigned Hostel Warden</span>
                  </div>
                  <span className="text-[10px] font-bold px-2 py-0.5 bg-white text-blue-800 rounded-md border border-blue-200">
                    Chief Warden
                  </span>
                </div>

                <div className="text-sm font-bold text-gray-900">{h.wardenName}</div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs pt-1">
                  <div className="bg-white p-2 rounded-lg border border-gray-200 flex items-center gap-2">
                    <Phone className="w-3.5 h-3.5 text-blue-700 shrink-0" />
                    <div>
                      <span className="text-[10px] text-gray-400 block font-semibold">CONTACT PHONE</span>
                      <span className="font-mono font-bold text-gray-800">{h.wardenMobile}</span>
                    </div>
                  </div>
                  <div className="bg-white p-2 rounded-lg border border-gray-200 flex items-center gap-2">
                    <Mail className="w-3.5 h-3.5 text-blue-700 shrink-0" />
                    <div>
                      <span className="text-[10px] text-gray-400 block font-semibold">OFFICIAL EMAIL</span>
                      <span className="font-mono text-[11px] font-bold text-gray-800 truncate block max-w-[150px]">{h.wardenEmail}</span>
                    </div>
                  </div>
                </div>

                <div className="text-[11px] text-gray-500 pt-1">
                  <strong>Office:</strong> {h.wardenOffice}
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="mt-5 pt-3 border-t border-gray-100 flex items-center justify-between">
              <span className="text-[11px] text-gray-400">Total Capacity: {h.totalCapacity} Students</span>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleOpenEdit(h)}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-900 text-xs font-bold border border-blue-200 transition-all"
                >
                  <Edit className="w-3.5 h-3.5" />
                  <span>Assign Warden</span>
                </button>
                {h.id !== 'hostel_4' && (
                  <button
                    onClick={() => handleDelete(h.id, h.name)}
                    className="p-1.5 rounded-lg text-red-500 hover:bg-red-50 transition-all"
                    title="Delete Hostel"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ADD / EDIT HOSTEL MODAL */}
      {(isAddModalOpen || editingHostel) && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-blue-50 text-blue-800">
                  <Building2 className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">{editingHostel ? 'Edit Hostel & Assign Warden' : 'Add New Hostel'}</h3>
                  <p className="text-xs text-gray-500">Super Admin Configuration</p>
                </div>
              </div>
              <button
                onClick={() => {
                  setIsAddModalOpen(false);
                  setEditingHostel(null);
                }}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="space-y-3.5 py-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Hostel Full Name</label>
                <input
                  type="text"
                  placeholder="e.g. Hostel Number 4 (Senior Boys Hostel)"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                  className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Hostel Code</label>
                  <input
                    type="text"
                    placeholder="e.g. H-4"
                    value={form.code}
                    onChange={(e) => setForm({ ...form, code: e.target.value })}
                    required
                    className="w-full px-3 py-2 border rounded-xl text-sm font-mono outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Total Rooms</label>
                  <input
                    type="number"
                    value={form.totalRooms}
                    onChange={(e) => setForm({ ...form, totalRooms: Number(e.target.value) })}
                    required
                    className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Capacity</label>
                  <input
                    type="number"
                    value={form.totalCapacity}
                    onChange={(e) => setForm({ ...form, totalCapacity: Number(e.target.value) })}
                    required
                    className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Warden Assignment Form */}
              <div className="p-3.5 bg-blue-50/70 rounded-xl border border-blue-200 space-y-3">
                <p className="text-xs font-extrabold text-blue-950 uppercase tracking-wider">
                  Assign Hostel Warden
                </p>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Warden Full Name & Title</label>
                  <input
                    type="text"
                    placeholder="e.g. Dr. S. K. Jha"
                    value={form.wardenName}
                    onChange={(e) => setForm({ ...form, wardenName: e.target.value })}
                    required
                    className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Warden Mobile</label>
                    <input
                      type="text"
                      placeholder="e.g. 9431201984"
                      value={form.wardenMobile}
                      onChange={(e) => setForm({ ...form, wardenMobile: e.target.value })}
                      required
                      className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm font-mono outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Warden Email</label>
                    <input
                      type="email"
                      placeholder="e.g. warden.h4@bce.ac.in"
                      value={form.wardenEmail}
                      onChange={(e) => setForm({ ...form, wardenEmail: e.target.value })}
                      className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Warden Office / Location</label>
                  <input
                    type="text"
                    placeholder="e.g. Ground Floor, Block-A Admin Room"
                    value={form.wardenOffice}
                    onChange={(e) => setForm({ ...form, wardenOffice: e.target.value })}
                    className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => {
                    setIsAddModalOpen(false);
                    setEditingHostel(null);
                  }}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-blue-700 hover:bg-blue-800 rounded-xl shadow transition-all"
                >
                  {editingHostel ? 'Save Hostel & Warden' : 'Create Hostel'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
