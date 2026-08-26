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

export const FoodPrepPage: React.FC = () => (
  <div className="p-6 bg-white rounded-xl shadow-sm border border-gray-100">
    <h2 className="text-2xl font-display font-bold mb-4">Food Preparation</h2>
    <div className="bg-green-50 p-6 rounded-lg mb-6 text-center border border-green-200">
      <h3 className="text-lg font-bold text-green-800">Predicted Attendance for Next Meal</h3>
      <p className="text-5xl font-bold text-green-600 my-4">425</p>
      <p className="text-sm text-green-700">Confidence: 94%</p>
    </div>
    <form className="max-w-md mx-auto space-y-4">
      <div><label className="block mb-1 font-bold">Approve Preparation Quantity</label><input type="number" defaultValue={425} className="w-full border p-2 rounded text-lg text-center" /></div>
      <button className="w-full bg-primary-600 text-white px-4 py-3 font-bold rounded-lg hover:bg-primary-700">Approve & Notify Cooks</button>
    </form>
  </div>
);

export const HostelsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Hostels</h1><p>Manage hostels and rooms here.</p></div>;
export const EventsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Events</h1><p>Manage calendar events affecting attendance.</p></div>;
export const MessesPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">Messes</h1><p>Configure mess locations and capacities.</p></div>;
export const SystemAnalyticsPage: React.FC = () => <div className="p-4"><h1 className="text-2xl font-bold">System Analytics</h1><p>Aggregate insights across all messes.</p></div>;
