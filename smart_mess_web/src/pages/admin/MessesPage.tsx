import React, { useState, useEffect } from 'react';
import { Building2, Utensils, User, Phone, KeyRound, Lock, Plus, Edit, Trash2, Check, ShieldCheck, X } from 'lucide-react';
import toast from 'react-hot-toast';

export interface MessItem {
  id: string;
  name: string;
  hostelName: string;
  capacity: number;
  managerName: string;
  managerMobile: string;
  managerPassword: string;
  status: 'Active' | 'Under Maintenance';
  servingShifts: string[];
}

const DEFAULT_MESSES: MessItem[] = [
  {
    id: 'mess_h4',
    name: 'Hostel Number 4 Dining Hall',
    hostelName: 'Hostel Number 4',
    capacity: 112,
    managerName: 'Dhaneshwar Yadav',
    managerMobile: '6200432942',
    managerPassword: 'Pass@2942',
    status: 'Active',
    servingShifts: ['Breakfast', 'Lunch', 'Dinner']
  },
  {
    id: 'mess_h3',
    name: 'Hostel Number 3 Dining Hall',
    hostelName: 'Hostel Number 3',
    capacity: 140,
    managerName: 'Rameshwar Mahato',
    managerMobile: '9835012345',
    managerPassword: 'Pass@2345',
    status: 'Active',
    servingShifts: ['Breakfast', 'Lunch', 'Dinner']
  }
];

export const MessesPage: React.FC = () => {
  const [messes, setMesses] = useState<MessItem[]>(() => {
    const saved = localStorage.getItem('SMART_MESS_ALL_MESSES');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {}
    }
    return DEFAULT_MESSES;
  });

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingMess, setEditingMess] = useState<MessItem | null>(null);

  const [form, setForm] = useState({
    name: '',
    hostelName: 'Hostel Number 4',
    capacity: 112,
    managerName: '',
    managerMobile: '',
    managerPassword: '',
    status: 'Active' as 'Active' | 'Under Maintenance',
    servingShifts: ['Breakfast', 'Lunch', 'Dinner']
  });

  useEffect(() => {
    localStorage.setItem('SMART_MESS_ALL_MESSES', JSON.stringify(messes));
    const h4 = messes.find((m) => m.id === 'mess_h4');
    if (h4) {
      localStorage.setItem(
        'SMART_MESS_MANAGER_DATA',
        JSON.stringify({
          name: h4.managerName,
          mobile: h4.managerMobile,
          password: h4.managerPassword,
          role: 'Mess Manager',
          hostel: h4.hostelName
        })
      );
    }
  }, [messes]);

  const handleOpenAdd = () => {
    setForm({
      name: '',
      hostelName: 'Hostel Number 4',
      capacity: 112,
      managerName: '',
      managerMobile: '',
      managerPassword: '',
      status: 'Active',
      servingShifts: ['Breakfast', 'Lunch', 'Dinner']
    });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (mess: MessItem) => {
    setEditingMess(mess);
    setForm({
      name: mess.name,
      hostelName: mess.hostelName,
      capacity: mess.capacity,
      managerName: mess.managerName,
      managerMobile: mess.managerMobile,
      managerPassword: mess.managerPassword,
      status: mess.status,
      servingShifts: mess.servingShifts
    });
  };

  const handleSaveMess = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.managerName || !form.managerMobile) {
      toast.error('Mess Name, Manager Name, and Mobile are required');
      return;
    }

    const autoPass = form.managerPassword.trim() || `Pass@${form.managerMobile.slice(-4)}`;

    if (editingMess) {
      setMesses((prev) =>
        prev.map((m) =>
          m.id === editingMess.id
            ? {
                ...m,
                name: form.name,
                hostelName: form.hostelName,
                capacity: Number(form.capacity),
                managerName: form.managerName,
                managerMobile: form.managerMobile,
                managerPassword: autoPass,
                status: form.status
              }
            : m
        )
      );
      toast.success(`Updated mess & manager credentials for ${form.name}!`);
      setEditingMess(null);
    } else {
      const newMess: MessItem = {
        id: `mess_${Date.now()}`,
        name: form.name,
        hostelName: form.hostelName,
        capacity: Number(form.capacity),
        managerName: form.managerName,
        managerMobile: form.managerMobile,
        managerPassword: autoPass,
        status: form.status,
        servingShifts: form.servingShifts
      };
      setMesses((prev) => [...prev, newMess]);
      toast.success(`Added new mess "${newMess.name}" with manager ${newMess.managerName}!`);
      setIsAddModalOpen(false);
    }
  };

  const handleDeleteMess = (id: string, name: string) => {
    if (id === 'mess_h4') {
      toast.error('Hostel Number 4 is the primary default mess and cannot be deleted.');
      return;
    }
    setMesses((prev) => prev.filter((m) => m.id !== id));
    toast.success(`Removed mess ${name}`);
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
            Mess Units & Manager Assignment
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Create dining halls, manage mess names, and assign Mess Managers with unique login credentials
          </p>
        </div>
        <button
          onClick={handleOpenAdd}
          className="flex items-center gap-2 bg-amber-500 hover:bg-amber-600 text-slate-900 px-4 py-2.5 rounded-xl font-bold text-xs shadow transition-all shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>Add New Mess Unit</span>
        </button>
      </div>

      {/* Messes List */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {messes.map((mess) => (
          <div key={mess.id} className="bg-white rounded-2xl border border-gray-200 shadow-sm p-6 flex flex-col justify-between">
            <div>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl bg-emerald-100 text-[#1B5E20] flex items-center justify-center font-bold">
                    <Utensils className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg leading-tight">{mess.name}</h3>
                    <p className="text-xs text-gray-500 font-medium mt-0.5">{mess.hostelName} • Capacity: {mess.capacity} Residents</p>
                  </div>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-[#1B5E20] border border-emerald-200">
                  {mess.status}
                </span>
              </div>

              {/* Manager Assigned Card */}
              <div className="mt-5 p-4 rounded-xl bg-emerald-50/50 border border-emerald-200 space-y-2.5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 text-xs font-bold text-emerald-900">
                    <User className="w-4 h-4 text-[#1B5E20]" />
                    <span>Assigned Mess Manager</span>
                  </div>
                  <span className="text-[10px] font-bold px-2 py-0.5 bg-white text-emerald-800 rounded-md border border-emerald-200">
                    Authorized
                  </span>
                </div>

                <div className="text-sm font-bold text-gray-900">{mess.managerName}</div>

                <div className="grid grid-cols-2 gap-2 text-xs pt-1">
                  <div className="bg-white p-2 rounded-lg border border-gray-200">
                    <span className="text-[10px] text-gray-400 block font-semibold">LOGIN ID / MOBILE</span>
                    <span className="font-mono font-bold text-gray-800">{mess.managerMobile}</span>
                  </div>
                  <div className="bg-white p-2 rounded-lg border border-gray-200">
                    <span className="text-[10px] text-gray-400 block font-semibold">LOGIN PASSWORD</span>
                    <span className="font-mono font-bold text-[#1B5E20]">{mess.managerPassword}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="mt-5 pt-3 border-t border-gray-100 flex items-center justify-between">
              <span className="text-[11px] text-gray-400">Shifts: {mess.servingShifts.join(', ')}</span>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleOpenEdit(mess)}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] text-xs font-bold border border-emerald-200 transition-all"
                >
                  <Edit className="w-3.5 h-3.5" />
                  <span>Edit & Set Credentials</span>
                </button>
                {mess.id !== 'mess_h4' && (
                  <button
                    onClick={() => handleDeleteMess(mess.id, mess.name)}
                    className="p-1.5 rounded-lg text-red-500 hover:bg-red-50 transition-all"
                    title="Delete Mess"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ADD / EDIT MESS MODAL */}
      {(isAddModalOpen || editingMess) && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-emerald-50 text-[#1B5E20]">
                  <Utensils className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">{editingMess ? 'Edit Mess & Manager' : 'Add New Dining Mess'}</h3>
                  <p className="text-xs text-gray-500">Super Admin Configuration</p>
                </div>
              </div>
              <button
                onClick={() => {
                  setIsAddModalOpen(false);
                  setEditingMess(null);
                }}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveMess} className="space-y-3.5 py-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Mess Name</label>
                <input
                  type="text"
                  placeholder="e.g. Hostel Number 4 Dining Hall"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                  className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Associated Hostel</label>
                  <input
                    type="text"
                    placeholder="e.g. Hostel Number 4"
                    value={form.hostelName}
                    onChange={(e) => setForm({ ...form, hostelName: e.target.value })}
                    required
                    className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Resident Capacity</label>
                  <input
                    type="number"
                    value={form.capacity}
                    onChange={(e) => setForm({ ...form, capacity: Number(e.target.value) })}
                    required
                    className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </div>
              </div>

              <div className="p-3 bg-emerald-50/70 rounded-xl border border-emerald-200 space-y-3">
                <p className="text-xs font-extrabold text-[#1B5E20] uppercase tracking-wider">
                  Assign Mess Manager Credentials
                </p>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Manager Full Name</label>
                  <input
                    type="text"
                    placeholder="e.g. Dhaneshwar Yadav"
                    value={form.managerName}
                    onChange={(e) => setForm({ ...form, managerName: e.target.value })}
                    required
                    className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Manager Mobile No. (Login ID)</label>
                  <input
                    type="text"
                    placeholder="e.g. 6200432942"
                    value={form.managerMobile}
                    onChange={(e) => setForm({ ...form, managerMobile: e.target.value })}
                    required
                    className="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm font-mono outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Manager Password</label>
                  <input
                    type="text"
                    placeholder="e.g. Pass@2942"
                    value={form.managerPassword}
                    onChange={(e) => setForm({ ...form, managerPassword: e.target.value })}
                    className="w-full px-3 py-2 bg-white border border-emerald-300 rounded-lg text-sm font-mono font-bold text-[#1B5E20] outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => {
                    setIsAddModalOpen(false);
                    setEditingMess(null);
                  }}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-[#1B5E20] hover:bg-emerald-800 rounded-xl shadow transition-all"
                >
                  {editingMess ? 'Save Mess Configuration' : 'Create Mess Unit'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
