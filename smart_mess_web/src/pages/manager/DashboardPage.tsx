import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import { CheckCircle2, TrendingUp, Users, CalendarOff, AlertCircle, ChefHat, Sparkles } from 'lucide-react';
import toast from 'react-hot-toast';

export const DashboardPage: React.FC = () => {
  const { user } = useAuthStore();
  const [approvedQty, setApprovedQty] = useState(168);
  const [isApproved, setIsApproved] = useState(false);

  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const isBreakfast = currentMinutes < 9 * 60 + 30; // before 09:30 AM
  const isLunch = !isBreakfast && currentMinutes < 14 * 60 + 30; // before 02:30 PM
  const isDinner = !isBreakfast && !isLunch && currentMinutes < 21 * 60 + 30; // before 09:30 PM
  const isClosedForDay = !isBreakfast && !isLunch && !isDinner; // after 09:30 PM

  const currentMealName = isBreakfast ? 'Breakfast' : isLunch ? 'Lunch' : isDinner ? 'Dinner' : 'Closed for Today';
  const currentMealHours = isBreakfast ? '08:00 AM - 09:30 AM' : isLunch ? '01:00 PM - 02:30 PM' : isDinner ? '08:00 PM - 09:30 PM' : 'Service Closed';
  const currentCutoff = isBreakfast ? '07:00 AM' : isLunch ? '11:00 AM' : isDinner ? '06:00 PM' : 'Tomorrow 07:00 AM';

  const handleApprove = () => {
    setIsApproved(true);
    toast.success(`Preparation quantity approved for ${approvedQty} portions!`);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <span className="inline-block w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Smart Mess Operational Dashboard • Central Dining Facility
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Hello, {user?.name || 'Mess Manager'}
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Active / Upcoming: <strong className="text-white font-semibold">{currentMealName} ({currentMealHours})</strong>
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="bg-primary-800/80 border border-primary-700 text-primary-100 px-4 py-2 rounded-xl text-sm font-medium">
            Cutoff Deadline: <strong>{currentCutoff} {isClosedForDay ? '(All Meals Ended)' : '(Strict)'}</strong>
          </span>
        </div>
      </div>

      {/* SECTION 1: HERO DEMAND PREDICTION CARD */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 space-y-6">
        <div className="flex items-center justify-between border-b border-gray-100 pb-4">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-emerald-50 rounded-lg text-emerald-700">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <h2 className="font-display font-bold text-gray-900 text-lg">AI Food Demand Prediction</h2>
              <p className="text-xs text-gray-500">Real-time Random Forest ML Model Recommendation</p>
            </div>
          </div>
          <span className="bg-emerald-100 text-emerald-800 text-xs font-semibold px-3 py-1 rounded-full">
            High Confidence (97.4%)
          </span>
        </div>

        {/* 5 Operational Key Metrics */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
          <div className="bg-gray-50/70 p-4 rounded-xl border border-gray-100">
            <span className="text-xs font-medium text-gray-500 uppercase tracking-wider">Active Students</span>
            <p className="text-2xl font-bold text-gray-900 mt-1">187</p>
            <span className="text-xs text-gray-500 mt-1 block">Hostel Occupancy 94%</span>
          </div>

          <div className="bg-amber-50/60 p-4 rounded-xl border border-amber-100">
            <span className="text-xs font-medium text-amber-700 uppercase tracking-wider">Mess-Off Count</span>
            <p className="text-2xl font-bold text-amber-900 mt-1">23</p>
            <span className="text-xs text-amber-700 mt-1 block">12.3% opt-out rate</span>
          </div>

          <div className="bg-blue-50/60 p-4 rounded-xl border border-blue-100">
            <span className="text-xs font-medium text-blue-700 uppercase tracking-wider">Predicted Demand</span>
            <p className="text-2xl font-bold text-blue-900 mt-1">163</p>
            <span className="text-xs text-blue-600 mt-1 block">Historical Avg: 165</span>
          </div>

          <div className="bg-purple-50/60 p-4 rounded-xl border border-purple-100">
            <span className="text-xs font-medium text-purple-700 uppercase tracking-wider">Expected Range</span>
            <p className="text-2xl font-bold text-purple-900 mt-1">158 – 169</p>
            <span className="text-xs text-purple-600 mt-1 block">±5% confidence interval</span>
          </div>

          <div className="bg-emerald-50 p-4 rounded-xl border border-emerald-200">
            <span className="text-xs font-bold text-emerald-800 uppercase tracking-wider">Recommended Cooking</span>
            <p className="text-2xl font-extrabold text-emerald-900 mt-1">{approvedQty}</p>
            <span className="text-xs text-emerald-700 font-medium mt-1 block">+3% safety buffer</span>
          </div>
        </div>

        {/* Approval Action Bar */}
        <div className="bg-emerald-50/50 border border-emerald-200 rounded-xl p-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <ChefHat className="w-6 h-6 text-emerald-700 shrink-0" />
            <div>
              <p className="text-sm font-semibold text-gray-900">
                Operational Decision: {isApproved ? `Approved ${approvedQty} Portions for Lunch` : 'Review & Approve Kitchen Batch'}
              </p>
              <p className="text-xs text-gray-500">
                ML recommendation is advisory. Manager holds final decision before kitchen preparation.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3 w-full sm:w-auto">
            {!isApproved && (
              <input
                type="number"
                value={approvedQty}
                onChange={(e) => setApprovedQty(parseInt(e.target.value) || 0)}
                className="w-24 px-3 py-2 border border-gray-300 rounded-lg text-center font-bold text-gray-900 focus:ring-2 focus:ring-emerald-500"
              />
            )}
            <button
              onClick={handleApprove}
              disabled={isApproved}
              className={`flex-1 sm:flex-none flex items-center justify-center gap-2 px-6 py-2.5 rounded-lg font-semibold text-sm transition-all shadow-sm ${
                isApproved
                  ? 'bg-emerald-600 text-white cursor-default'
                  : 'bg-emerald-700 hover:bg-emerald-800 text-white'
              }`}
            >
              <CheckCircle2 className="w-4 h-4" />
              {isApproved ? 'Approved & Sent to Kitchen' : `APPROVE ${approvedQty} PORTIONS`}
            </button>
          </div>
        </div>
      </div>

      {/* SECTION 2 & 3: LIVE ATTENDANCE + RECENT PERFORMANCE */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Live Attendance Counter */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-display font-bold text-gray-900 text-base">Live Meal Attendance</h3>
                <p className="text-xs text-gray-500">Real-time Dynamic QR verification feed</p>
              </div>
              <span className="flex items-center gap-1.5 bg-emerald-50 text-emerald-700 text-xs font-semibold px-2.5 py-1 rounded-full">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span> Live
              </span>
            </div>

            <div className="my-6 text-center">
              <div className="inline-flex items-baseline gap-2">
                <span className="text-5xl font-extrabold font-display text-gray-900">138</span>
                <span className="text-2xl font-bold text-gray-400">/ 168</span>
              </div>
              <p className="text-xs text-gray-500 mt-1">Students Checked-in via Dynamic QR</p>
            </div>

            {/* Progress Bar */}
            <div className="space-y-2">
              <div className="flex justify-between text-xs font-medium text-gray-600">
                <span>Progress</span>
                <span>82.1%</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-primary-600 h-3 rounded-full transition-all duration-500" style={{ width: '82.1%' }}></div>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-500">
            <span>Remaining to eat: <strong>18 students</strong></span>
            <button
              onClick={() => navigate('/attendance-ledger')}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-[#1B5E20] font-bold text-xs border border-emerald-200 transition-all shadow-sm"
            >
              <Users className="w-3.5 h-3.5" />
              <span>View 112 Student Attendance Ledger ➔</span>
            </button>
          </div>
        </div>

        {/* Recent Performance Table */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-display font-bold text-gray-900 text-base">Recent Prediction Accuracy</h3>
              <p className="text-xs text-gray-500">Predicted vs Actual Attendance & Wastage</p>
            </div>
            <TrendingUp className="w-5 h-5 text-gray-400" />
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-gray-100 text-xs font-semibold text-gray-500 uppercase">
                  <th className="pb-3">Meal</th>
                  <th className="pb-3 text-center">Predicted</th>
                  <th className="pb-3 text-center">Actual</th>
                  <th className="pb-3 text-center">Error</th>
                  <th className="pb-3 text-center">Wasted</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                <tr>
                  <td className="py-2.5 font-medium text-gray-900">Breakfast (Today)</td>
                  <td className="py-2.5 text-center text-gray-600">125</td>
                  <td className="py-2.5 text-center font-semibold text-gray-900">122</td>
                  <td className="py-2.5 text-center text-emerald-600 font-medium">3 (2.4%)</td>
                  <td className="py-2.5 text-center text-gray-500">4 kg</td>
                </tr>
                <tr>
                  <td className="py-2.5 font-medium text-gray-900">Dinner (Yesterday)</td>
                  <td className="py-2.5 text-center text-gray-600">170</td>
                  <td className="py-2.5 text-center font-semibold text-gray-900">168</td>
                  <td className="py-2.5 text-center text-emerald-600 font-medium">2 (1.2%)</td>
                  <td className="py-2.5 text-center text-gray-500">5 kg</td>
                </tr>
                <tr>
                  <td className="py-2.5 font-medium text-gray-900">Lunch (Yesterday)</td>
                  <td className="py-2.5 text-center text-gray-600">165</td>
                  <td className="py-2.5 text-center font-semibold text-gray-900">161</td>
                  <td className="py-2.5 text-center text-emerald-600 font-medium">4 (2.4%)</td>
                  <td className="py-2.5 text-center text-gray-500">7 kg</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
