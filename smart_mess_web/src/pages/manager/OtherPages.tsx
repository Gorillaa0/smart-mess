import React from 'react';

export const WastagePage: React.FC = () => (
  <div className="p-6 bg-white rounded-xl shadow-sm border border-gray-100">
    <h2 className="text-2xl font-display font-bold mb-4">Record Wastage</h2>
    <form className="max-w-md space-y-4">
      <div><label className="block mb-1">Prepared Quantity (kg)</label><input type="number" className="w-full border p-2 rounded" /></div>
      <div><label className="block mb-1">Leftover Quantity (kg)</label><input type="number" className="w-full border p-2 rounded" /></div>
      <button className="bg-primary-600 text-white px-4 py-2 rounded">Submit Record</button>
    </form>
  </div>
);

export const NotificationsPage: React.FC = () => (
  <div className="p-6 bg-white rounded-xl shadow-sm border border-gray-100">
    <h2 className="text-2xl font-display font-bold mb-4">Send Notification</h2>
    <form className="max-w-md space-y-4">
      <div><label className="block mb-1">Title</label><input type="text" className="w-full border p-2 rounded" /></div>
      <div><label className="block mb-1">Message</label><textarea className="w-full border p-2 rounded h-24" /></div>
      <button className="bg-primary-600 text-white px-4 py-2 rounded">Broadcast</button>
    </form>
  </div>
);

export const FoodPrepPage: React.FC = () => {
  const [selectedMeal, setSelectedMeal] = React.useState<'Breakfast' | 'Lunch' | 'Dinner'>('Lunch');
  const [managerPortions, setManagerPortions] = React.useState<Record<string, number>>({});
  const [approvedMap, setApprovedMap] = React.useState<Record<string, boolean>>({
    Breakfast: false,
    Lunch: false,
    Dinner: false
  });

  const mealsData = {
    Breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      predicted: 73,
      recommended: 75,
      menu: 'Aloo Paratha / Idli Sambhar, Curd & Hot Chai',
      range: '69 - 77',
      rate: '₹25 / student'
    },
    Lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      predicted: 106,
      recommended: 109,
      menu: 'Rice, Arhar Dal, Seasonal Mixed Veg, Papad & Fresh Salad',
      range: '101 - 111',
      rate: '₹50 (Standard) / ₹100 (Special)'
    },
    Dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      predicted: 95,
      recommended: 98,
      menu: 'Hot Phulka Roti, Dal Tadka, Paneer Butter Masala / Chicken Curry',
      range: '91 - 99',
      rate: '₹50 (Standard) / ₹100 (Special)'
    }
  };

  const current = mealsData[selectedMeal];
  const decidedQty = managerPortions[selectedMeal] ?? current.recommended;
  const isApproved = approvedMap[selectedMeal] || false;

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md">
        <h1 className="text-2xl font-bold font-display">Kitchen Food Preparation & Cooking Planner</h1>
        <p className="text-primary-200 text-sm mt-1">
          Separate AI attendance predictions and cooking portion recommendations for Breakfast, Lunch, and Dinner with Manager Decided Quantity Control.
        </p>
      </div>

      {/* 3-Meal Cards Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {(['Breakfast', 'Lunch', 'Dinner'] as const).map((m) => {
          const d = mealsData[m];
          const isSelected = selectedMeal === m;
          const isApp = approvedMap[m];

          return (
            <div
              key={m}
              onClick={() => setSelectedMeal(m)}
              className={`p-5 rounded-2xl border transition-all cursor-pointer ${
                isSelected
                  ? 'bg-primary-50/40 border-primary-600 shadow-md ring-2 ring-primary-500/20'
                  : 'bg-white border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="font-bold text-gray-900 text-base">
                  {m === 'Breakfast' ? '🍳 Breakfast' : m === 'Lunch' ? '🍛 Lunch' : '🍲 Dinner'}
                </span>
                {isApp ? (
                  <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    ✓ Approved
                  </span>
                ) : (
                  <span className="bg-amber-100 text-amber-800 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    Pending
                  </span>
                )}
              </div>

              <div className="space-y-1.5 text-xs text-gray-600">
                <p><span className="font-semibold text-gray-800">Timing:</span> {d.time}</p>
                <p><span className="font-semibold text-gray-800">Cutoff:</span> {d.cutoff}</p>
                <div className="mt-3 pt-3 border-t border-gray-100 flex items-center justify-between">
                  <span className="text-gray-500 font-medium">Rec. Cook:</span>
                  <span className="text-lg font-black text-primary-900">{d.recommended} Portions</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Selected Meal Detailed Approval Panel */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-sm space-y-5">
        <div className="flex items-center justify-between border-b border-gray-100 pb-4">
          <div>
            <h3 className="font-bold text-gray-900 text-lg">
              {selectedMeal === 'Breakfast' ? '🍳 Breakfast' : selectedMeal === 'Lunch' ? '🍛 Lunch' : '🍲 Dinner'} Preparation Sheet
            </h3>
            <p className="text-xs text-gray-500">Menu: {current.menu}</p>
          </div>
          <span className="text-xs font-bold text-primary-800 bg-primary-50 px-3 py-1.5 rounded-xl border border-primary-200">
            Cutoff Deadline: {current.cutoff}
          </span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-gray-50 p-4 rounded-xl border border-gray-100 text-center">
            <span className="text-xs text-gray-500 font-medium block">Total Roster</span>
            <span className="text-2xl font-bold text-gray-900 mt-1 block">112</span>
            <span className="text-[10px] text-gray-400">Hostel 4 Boarders</span>
          </div>

          <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 text-center">
            <span className="text-xs text-blue-700 font-medium block">Predicted Crowd</span>
            <span className="text-2xl font-bold text-blue-900 mt-1 block">{current.predicted}</span>
            <span className="text-[10px] text-blue-600">Expected scans</span>
          </div>

          <div className="bg-purple-50 p-4 rounded-xl border border-purple-100 text-center">
            <span className="text-xs text-purple-700 font-medium block">Expected Range</span>
            <span className="text-xl font-bold text-purple-900 mt-1 block">{current.range}</span>
            <span className="text-[10px] text-purple-600">±4% confidence band</span>
          </div>

          <div className="bg-emerald-50 p-4 rounded-xl border border-emerald-200 text-center">
            <span className="text-xs text-emerald-800 font-bold block">Recommended Cook</span>
            <span className="text-2xl font-black text-emerald-900 mt-1 block">{current.recommended}</span>
            <span className="text-[10px] text-emerald-700 font-medium">+3% safety buffer</span>
          </div>
        </div>

        <div className="bg-gray-50 p-4 rounded-xl border border-gray-200 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="text-xs text-gray-700">
            <span className="font-bold">Meal Rate:</span> {current.rate} • <span className="font-bold">Total Estimated Serving Cost:</span> ₹{decidedQty * (selectedMeal === 'Breakfast' ? 25 : 50)}
          </div>

          <div className="flex items-center gap-3 w-full md:w-auto">
            {!isApproved ? (
              <div className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-xl border border-gray-300 shadow-inner">
                <span className="text-xs font-bold text-gray-600">Decision Qty:</span>
                <input
                  type="number"
                  value={decidedQty}
                  onChange={(e) => {
                    const val = parseInt(e.target.value) || 0;
                    setManagerPortions(prev => ({ ...prev, [selectedMeal]: val }));
                  }}
                  className="w-20 text-center font-black text-gray-900 border-b-2 border-emerald-600 focus:outline-none text-base"
                />
                <span className="text-xs text-gray-400">portions</span>
              </div>
            ) : (
              <span className="text-xs font-bold text-emerald-800 bg-emerald-100 px-3 py-2 rounded-xl">
                ✓ {decidedQty} Portions Finalized
              </span>
            )}

            <button
              onClick={() => setApprovedMap(prev => ({ ...prev, [selectedMeal]: true }))}
              disabled={isApproved}
              className={`px-6 py-2.5 rounded-xl text-xs font-bold text-white transition shadow-sm ${
                isApproved
                  ? 'bg-emerald-800 cursor-default'
                  : 'bg-primary-800 hover:bg-primary-900'
              }`}
            >
              {isApproved ? `✓ ${selectedMeal} Approved (${decidedQty} Portions)` : `Approve ${selectedMeal} Kitchen Batch`}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export const HostelsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Hostels</h1><p>Manage hostels and rooms here.</p></div>;
export const EventsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Events</h1><p>Manage calendar events affecting attendance.</p></div>;
export const MessesPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Messes</h1><p>Configure mess locations and capacities.</p></div>;
export const SystemAnalyticsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">System Analytics</h1><p>Aggregate insights across all messes.</p></div>;
