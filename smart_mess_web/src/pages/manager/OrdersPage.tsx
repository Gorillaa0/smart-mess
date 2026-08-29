import React, { useState, useEffect } from 'react';
import { ShoppingBag, Clock, CheckCircle2, Phone, User, Check, AlertCircle, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

interface FoodOrder {
  id: string;
  studentName: string;
  registrationNo: string;
  rollNo: string;
  roomNo: string;
  mobileNumber: string;
  foodItemId: string;
  foodItemName: string;
  foodItemHindi: string;
  unitPrice: number;
  quantity: number;
  totalBill: number;
  isPaid: boolean;
  paymentMethod: string;
  status: 'Pending Approval' | 'Preparing' | 'Delivered';
  estimatedDeliveryTime: string;
  orderedAt: string;
}

export const OrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<FoodOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<string>('All');
  const [selectedTimeModalOrder, setSelectedTimeModalOrder] = useState<FoodOrder | null>(null);
  const [deliveryTime, setDeliveryTime] = useState<string>('30 - 40 Mins');

  const fetchOrders = async () => {
    try {
      const res = await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'foodOrders' }]
            }
          })
        }
      );

      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          const list: FoodOrder[] = [];
          for (const item of data) {
            if (item.document?.fields) {
              const f = item.document.fields;
              const id = f.id?.stringValue || item.document.name.split('/').pop() || '';
              list.push({
                id,
                studentName: f.studentName?.stringValue || 'Student',
                registrationNo: f.registrationNo?.stringValue || '',
                rollNo: f.rollNo?.stringValue || '',
                roomNo: f.roomNo?.stringValue || '',
                mobileNumber: f.mobileNumber?.stringValue || '',
                foodItemId: f.foodItemId?.stringValue || '',
                foodItemName: f.foodItemName?.stringValue || 'Special Item',
                foodItemHindi: f.foodItemHindi?.stringValue || '',
                unitPrice: parseInt(f.unitPrice?.integerValue || '0'),
                quantity: parseInt(f.quantity?.integerValue || '1'),
                totalBill: parseInt(f.totalBill?.integerValue || '0'),
                isPaid: f.isPaid?.booleanValue ?? true,
                paymentMethod: f.paymentMethod?.stringValue || 'UPI / Online',
                status: (f.status?.stringValue as any) || 'Pending Approval',
                estimatedDeliveryTime: f.estimatedDeliveryTime?.stringValue || '30 - 40 Mins',
                orderedAt: f.orderedAt?.stringValue || new Date().toISOString()
              });
            }
          }
          list.sort((a, b) => new Date(b.orderedAt).getTime() - new Date(a.orderedAt).getTime());
          setOrders(list);
        }
      }
    } catch (_) {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
    const interval = setInterval(fetchOrders, 3000);
    return () => clearInterval(interval);
  }, []);

  const handleUpdateStatus = async (orderId: string, newStatus: string, estTime?: string) => {
    try {
      await fetch(
        `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/foodOrders/${orderId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E&updateMask.fieldPaths=status&updateMask.fieldPaths=estimatedDeliveryTime&updateMask.fieldPaths=updatedAt`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              status: { stringValue: newStatus },
              estimatedDeliveryTime: { stringValue: estTime || '30 - 40 Mins' },
              updatedAt: { stringValue: new Date().toISOString() }
            }
          })
        }
      );

      toast.success(`Order updated to "${newStatus}"!`);
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus as any, estimatedDeliveryTime: estTime || o.estimatedDeliveryTime } : o));
      setSelectedTimeModalOrder(null);
    } catch (_) {
      toast.error('Failed to update order status');
    }
  };

  const filteredOrders = orders.filter(o => {
    if (selectedStatus === 'All') return true;
    return o.status.toLowerCase() === selectedStatus.toLowerCase();
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <ShoppingBag className="w-4 h-4 text-emerald-400" />
            Central Mess Fast Food & Kitchen Orders
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
            Special Food Orders Ledger
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Real-time orders placed by Hostel 4 residents with payment & delivery confirmation
          </p>
        </div>
        <div className="flex items-center gap-2 bg-primary-800/80 px-4 py-2 rounded-xl border border-primary-700">
          <span className="text-xs text-primary-200 font-semibold">Total Orders:</span>
          <span className="text-lg font-bold text-white">{orders.length}</span>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 border-b border-gray-200 pb-3">
        {['All', 'Pending Approval', 'Preparing', 'Delivered'].map(st => (
          <button
            key={st}
            onClick={() => setSelectedStatus(st)}
            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all ${
              selectedStatus === st ? 'bg-primary-800 text-white shadow-sm' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {st} ({st === 'All' ? orders.length : orders.filter(o => o.status.toLowerCase() === st.toLowerCase()).length})
          </button>
        ))}
      </div>

      {/* Orders List Table / Cards */}
      {filteredOrders.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-gray-200">
          <ShoppingBag className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <h3 className="text-base font-bold text-gray-700">No Orders Found</h3>
          <p className="text-xs text-gray-500 mt-1">Student orders for Egg Rolls, Chowmein & Burgers will appear here in real-time.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredOrders.map(order => (
            <div
              key={order.id}
              className={`bg-white rounded-2xl p-5 border shadow-sm transition space-y-3 ${
                order.status === 'Pending Approval' ? 'border-amber-300 ring-1 ring-amber-200' :
                order.status === 'Preparing' ? 'border-blue-300' : 'border-gray-200'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-base font-extrabold text-gray-900">{order.foodItemName}</span>
                  <span className="text-xs bg-gray-100 text-gray-700 px-2 py-0.5 rounded-full font-bold">
                    x{order.quantity}
                  </span>
                </div>
                <span className={`text-xs font-bold px-3 py-1 rounded-full ${
                  order.status === 'Pending Approval' ? 'bg-amber-100 text-amber-800' :
                  order.status === 'Preparing' ? 'bg-blue-100 text-blue-800' : 'bg-emerald-100 text-emerald-800'
                }`}>
                  {order.status}
                </span>
              </div>

              <div className="text-xs text-gray-500">{order.foodItemHindi}</div>

              <div className="grid grid-cols-2 gap-2 bg-gray-50 p-3 rounded-xl border border-gray-100 text-xs">
                <div>
                  <span className="text-gray-400 block font-medium">Resident Details</span>
                  <p className="font-bold text-gray-800 mt-0.5">{order.studentName}</p>
                  <p className="text-gray-500">Room {order.roomNo} • Roll: {order.rollNo}</p>
                </div>
                <div className="text-right">
                  <span className="text-gray-400 block font-medium">Total Bill</span>
                  <p className="text-base font-black text-primary-800 mt-0.5">₹{order.totalBill}</p>
                  <span className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold ${
                    order.isPaid ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {order.isPaid ? '✓ PAID ONLINE' : 'PAY ON DELIVERY'}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between text-xs text-gray-600 pt-1">
                <div className="flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-gray-400" />
                  <span>{order.mobileNumber}</span>
                </div>
                <div className="flex items-center gap-1 font-semibold text-primary-800 bg-primary-50 px-2 py-1 rounded-lg">
                  <Clock className="w-3.5 h-3.5 text-primary-700" />
                  <span>Est. Time: {order.estimatedDeliveryTime}</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="pt-2 flex items-center justify-end gap-2 border-t border-gray-100">
                {order.status === 'Pending Approval' && (
                  <button
                    onClick={() => setSelectedTimeModalOrder(order)}
                    className="bg-primary-800 hover:bg-primary-900 text-white text-xs font-bold px-4 py-2 rounded-xl transition flex items-center gap-1.5"
                  >
                    <Check className="w-4 h-4" />
                    Accept & Prepare
                  </button>
                )}

                {order.status === 'Preparing' && (
                  <button
                    onClick={() => handleUpdateStatus(order.id, 'Delivered')}
                    className="bg-blue-700 hover:bg-blue-800 text-white text-xs font-bold px-4 py-2 rounded-xl transition flex items-center gap-1.5"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    Mark as Delivered
                  </button>
                )}

                {order.status === 'Delivered' && (
                  <span className="text-xs text-emerald-700 font-bold flex items-center gap-1">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    Delivered to Room {order.roomNo}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Confirm & Set Time Modal */}
      {selectedTimeModalOrder && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-gray-200 animate-in fade-in zoom-in-95">
            <h3 className="text-lg font-display font-bold text-gray-900">
              Confirm & Prepare Order
            </h3>
            <p className="text-xs text-gray-600">
              Select estimated preparation & delivery duration for <strong className="text-gray-900">{selectedTimeModalOrder.studentName}</strong> (Room {selectedTimeModalOrder.roomNo}).
            </p>

            <div className="space-y-2">
              <label className="text-xs font-bold text-gray-700 block">Preparation & Delivery Time</label>
              <div className="grid grid-cols-3 gap-2">
                {['20 - 30 Mins', '30 - 40 Mins', '45 - 60 Mins'].map(t => (
                  <button
                    key={t}
                    type="button"
                    onClick={() => setDeliveryTime(t)}
                    className={`py-2 px-1 text-xs font-bold rounded-xl border text-center transition ${
                      deliveryTime === t ? 'bg-primary-800 text-white border-primary-900 shadow-sm' : 'bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100'
                    }`}
                  >
                    {t}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-gray-100">
              <button
                onClick={() => setSelectedTimeModalOrder(null)}
                className="px-4 py-2 text-xs font-bold text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={() => handleUpdateStatus(selectedTimeModalOrder.id, 'Preparing', deliveryTime)}
                className="bg-primary-800 hover:bg-primary-900 text-white text-xs font-bold px-5 py-2.5 rounded-xl transition shadow-sm"
              >
                Confirm & Notify Student
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
