import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { complaintsService } from '../../services/complaints.service';
import { useAuthStore } from '../../store/authStore';

export const ComplaintsPage: React.FC = () => {
  const { user } = useAuthStore();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<'Pending' | 'In Progress' | 'Resolved'>('Pending');

  const { data: complaints = [], isLoading } = useQuery({
    queryKey: ['complaints', user?.messId],
    queryFn: () => complaintsService.getComplaints(user?.messId || ''),
    enabled: !!user?.messId
  });

  const updateComplaint = useMutation({
    mutationFn: ({ id, status, response }: any) => complaintsService.updateComplaint(id, { status, response }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['complaints'] })
  });

  const filtered = complaints.filter(c => c.status === activeTab);

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-display font-bold">Complaints</h2>
      
      <div className="flex space-x-2 border-b">
        {['Pending', 'In Progress', 'Resolved'].map(tab => (
          <button
            key={tab}
            className={`py-2 px-4 border-b-2 font-medium ${activeTab === tab ? 'border-primary-600 text-primary-600' : 'border-transparent text-gray-500'}`}
            onClick={() => setActiveTab(tab as any)}
          >
            {tab}
          </button>
        ))}
      </div>

      <div className="grid gap-4">
        {isLoading ? <p>Loading...</p> : filtered.map(c => (
          <div key={c.id} className="bg-white p-4 rounded-xl border border-gray-200 flex flex-col space-y-3">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="font-bold text-lg">{c.title}</h3>
                <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">{c.category}</span>
              </div>
              <span className="text-sm text-gray-500">{new Date(c.createdAt).toLocaleDateString()}</span>
            </div>
            <p className="text-gray-700">{c.description}</p>
            {c.response && <div className="bg-primary-50 p-3 rounded border border-primary-100 text-sm"><strong>Response:</strong> {c.response}</div>}
            
            {activeTab !== 'Resolved' && (
              <div className="flex gap-2 items-center mt-2 pt-2 border-t">
                <input id={`resp-${c.id}`} type="text" placeholder="Add response..." className="flex-1 border rounded px-3 py-1 text-sm" />
                <button 
                  onClick={() => {
                    const el = document.getElementById(`resp-${c.id}`) as HTMLInputElement;
                    updateComplaint.mutate({ id: c.id, status: 'Resolved', response: el.value });
                  }}
                  className="bg-primary-600 text-white px-4 py-1 rounded text-sm hover:bg-primary-700"
                >
                  Resolve
                </button>
              </div>
            )}
          </div>
        ))}
        {filtered.length === 0 && <p className="text-gray-500 text-center py-8">No {activeTab.toLowerCase()} complaints.</p>}
      </div>
    </div>
  );
};
