import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, BarChart, Bar } from 'recharts';

const dummyAttendanceData = [
  { name: 'Mon', predicted: 400, actual: 380 },
  { name: 'Tue', predicted: 420, actual: 410 },
  { name: 'Wed', predicted: 410, actual: 415 },
  { name: 'Thu', predicted: 430, actual: 400 },
  { name: 'Fri', predicted: 390, actual: 360 },
  { name: 'Sat', predicted: 300, actual: 290 },
  { name: 'Sun', predicted: 320, actual: 310 },
];

export const AnalyticsPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-display font-bold">Analytics & Insights</h2>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold mb-4">Attendance: Predicted vs Actual</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={dummyAttendanceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="predicted" stroke="#9ca3af" />
                <Line type="monotone" dataKey="actual" stroke="#16a34a" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold mb-4">Wastage Trends (kg)</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dummyAttendanceData.map(d => ({ ...d, wastage: Math.abs(d.predicted - d.actual) * 0.2 }))}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="wastage" fill="#ef4444" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};
