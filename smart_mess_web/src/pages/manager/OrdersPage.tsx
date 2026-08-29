import React, { useState, useEffect } from 'react';
import { ShoppingBag, Clock, CheckCircle2, Phone, User, Check, AlertCircle, RefreshCw, Edit3, Plus, Utensils, Trash2, MessageSquare } from 'lucide-react';
import toast from 'react-hot-toast';

interface FoodOrder {
  id: string;
  studentName: string;
  registrationNo: string;
  rollNo: string;
  roomNo: string;
  mobileNumber: string;
  specialNotes?: string;
  foodItemId: string;
  foodItemName: string;
  foodItemHindi: string;
  unitPrice: number;
  quantity: number;
  totalBill: number;
  isPaid: boolean;
  paymentMethod: string;
  status: 'Pending Approval' | 'Preparing' | 'Delivered' | 'Cancelled';
  cancellationReason?: string;
  estimatedDeliveryTime: string;
  orderedAt: string;
}

interface MenuItem {
  id: string;
  name: string;
  hindiName: string;
  price: number;
  description: string;
  isAvailable: boolean;
}

const DEFAULT_MENU_ITEMS: MenuItem[] = [
  {
    id: 'egg_roll',
    name: 'Special Double Egg Roll',
    hindiName: 'स्पेशल डबल एग रोल',
    price: 45,
    description: 'Crispy laccha paratha with 2 eggs, fresh onions, green chili & sauces',
    isAvailable: true,
  },
  {
    id: 'paneer_roll',
    name: 'Paneer Tikka Roll',
    hindiName: 'पनीर टिक्का रोल',
    price: 60,
    description: 'Fresh grilled paneer cubes wrapped in toasted flaky laccha paratha',
    isAvailable: true,
  },
];

export const OrdersPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'orders' | 'menu'>('orders');
  const [orders, setOrders] = useState<FoodOrder[]>([]);
  const [menuItems, setMenuItems] = useState<MenuItem[]>(DEFAULT_MENU_ITEMS);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<string>('All');
  const [selectedTimeModalOrder, setSelectedTimeModalOrder] = useState<FoodOrder | null>(null);
  const [selectedCancelModalOrder, setSelectedCancelModalOrder] = useState<FoodOrder | null>(null);
  const [cancelReason, setCancelReason] = useState<string>('Kitchen out of stock / High rush');
  const [deliveryTime, setDeliveryTime] = useState<string>('30 - 40 Mins');
  
  // Edit/Create Menu Item Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreatingNew, setIsCreatingNew] = useState(false);
  const [currentEditingId, setCurrentEditingId] = useState<string | null>(null);
  const [editPrice, setEditPrice] = useState<number>(45);
  const [editName, setEditName] = useState<string>('');
  const [editHindiName, setEditHindiName] = useState<string>('');
  const [editDescription, setEditDescription] = useState<string>('');
  const [editAvailable, setEditAvailable] = useState<boolean>(true);

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
                specialNotes: f.specialNotes?.stringValue || '',
                foodItemId: f.foodItemId?.stringValue || '',
                foodItemName: f.foodItemName?.stringValue || 'Special Item',
                foodItemHindi: f.foodItemHindi?.stringValue || '',
                unitPrice: parseInt(f.unitPrice?.integerValue || '0'),
                quantity: parseInt(f.quantity?.integerValue || '1'),
                totalBill: parseInt(f.totalBill?.integerValue || '0'),
                isPaid: f.isPaid?.booleanValue ?? false,
                paymentMethod: f.paymentMethod?.stringValue || 'Pay on Delivery',
                status: (f.status?.stringValue as any) || 'Pending Approval',
                cancellationReason: f.cancellationReason?.stringValue || '',
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

  const fetchMenuItems = async () => {
    try {
      const res = await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'specialFoodMenu' }]
            }
          })
        }
      );

      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          const list: MenuItem[] = [];
          for (const item of data) {
            if (item.document?.fields) {
              const f = item.document.fields;
              const id = f.id?.stringValue || item.document.name.split('/').pop() || '';
              list.push({
                id,
                name: f.name?.stringValue || 'Item',
                hindiName: f.hindiName?.stringValue || '',
                price: parseInt(f.price?.integerValue || '0'),
                description: f.description?.stringValue || '',
                isAvailable: f.isAvailable?.booleanValue ?? true,
              });
            }
          }
          if (list.length > 0) {
            setMenuItems(list);
          }
        }
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchOrders();
    fetchMenuItems();
    const interval = setInterval(() => {
      fetchOrders();
      fetchMenuItems();
    }, 3000);
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

      toast.success(`Order marked as "${newStatus}"!`);
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus as any, estimatedDeliveryTime: estTime || o.estimatedDeliveryTime } : o));
      setSelectedTimeModalOrder(null);
    } catch (_) {
      toast.error('Failed to update order status');
    }
  };

  const handleCancelOrder = async (orderId: string, reason: string) => {
    try {
      await fetch(
        `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/foodOrders/${orderId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E&updateMask.fieldPaths=status&updateMask.fieldPaths=cancellationReason&updateMask.fieldPaths=updatedAt`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              status: { stringValue: 'Cancelled' },
              cancellationReason: { stringValue: reason },
              updatedAt: { stringValue: new Date().toISOString() }
            }
          })
        }
      );

      toast.error(`Order cancelled and reason sent to student!`);
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: 'Cancelled' as any, cancellationReason: reason } : o));
      setSelectedCancelModalOrder(null);
    } catch (_) {
      toast.error('Failed to cancel order');
    }
  };

  const handleSaveMenuItem = async () => {
    if (!editName.trim()) {
      toast.error('Please enter an item name');
      return;
    }
    if (editPrice <= 0) {
      toast.error('Please enter a valid price');
      return;
    }

    try {
      const itemId = isCreatingNew
        ? `item_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`
        : (currentEditingId || `item_${Date.now()}`);

      const updatedItem: MenuItem = {
        id: itemId,
        name: editName.trim(),
        hindiName: editHindiName.trim(),
        price: editPrice,
        description: editDescription.trim(),
        isAvailable: editAvailable,
      };

      await fetch(
        `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/specialFoodMenu/${itemId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              id: { stringValue: updatedItem.id },
              name: { stringValue: updatedItem.name },
              hindiName: { stringValue: updatedItem.hindiName },
              price: { integerValue: updatedItem.price.toString() },
              description: { stringValue: updatedItem.description },
              isAvailable: { booleanValue: updatedItem.isAvailable },
            }
          })
        }
      );

      if (isCreatingNew) {
        toast.success(`New item "${updatedItem.name}" (₹${updatedItem.price}) created and synced to Student Dashboard!`);
        setMenuItems(prev => [updatedItem, ...prev]);
      } else {
        toast.success(`Updated "${updatedItem.name}" (₹${updatedItem.price})! Synced to Student Dashboard.`);
        setMenuItems(prev => prev.map(i => i.id === itemId ? updatedItem : i));
      }

      setIsModalOpen(false);
      setCurrentEditingId(null);
    } catch (_) {
      toast.error('Failed to save food item');
    }
  };

  const openCreateModal = () => {
    setIsCreatingNew(true);
    setCurrentEditingId(null);
    setEditName('');
    setEditHindiName('');
    setEditPrice(50);
    setEditDescription('');
    setEditAvailable(true);
    setIsModalOpen(true);
  };

  const openEditModal = (item: MenuItem) => {
    setIsCreatingNew(false);
    setCurrentEditingId(item.id);
    setEditName(item.name);
    setEditHindiName(item.hindiName);
    setEditPrice(item.price);
    setEditDescription(item.description);
    setEditAvailable(item.isAvailable);
    setIsModalOpen(true);
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
            Special Food Desk & Menu Manager
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            Manage live resident fast-food orders, create new food items, and edit rates in real time.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setActiveTab('orders')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition ${
              activeTab === 'orders' ? 'bg-white text-primary-900 shadow' : 'bg-primary-800 text-white hover:bg-primary-700'
            }`}
          >
            Live Orders ({orders.length})
          </button>
          <button
            onClick={() => setActiveTab('menu')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
              activeTab === 'menu' ? 'bg-white text-primary-900 shadow' : 'bg-primary-800 text-white hover:bg-primary-700'
            }`}
          >
            <Edit3 className="w-3.5 h-3.5" />
            Manage Items & Prices
          </button>
        </div>
      </div>

      {activeTab === 'orders' ? (
        <>
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
              <p className="text-xs text-gray-500 mt-1">Student orders for Egg Rolls, Chowmein, Burgers, or new custom food will appear here in real-time.</p>
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
                      <p className="text-gray-500">Room: <strong className="text-gray-900">{order.roomNo}</strong> • Roll: {order.rollNo}</p>
                    </div>
                    <div className="text-right">
                      <span className="text-gray-400 block font-medium">Total Bill</span>
                      <p className="text-base font-black text-primary-800 mt-0.5">₹{order.totalBill}</p>
                      <span className="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-900">
                        PAY ON DELIVERY
                      </span>
                    </div>
                  </div>

                  {order.specialNotes && (
                    <div className="p-2.5 bg-amber-50/70 rounded-xl border border-amber-200 text-xs flex items-start gap-2">
                      <MessageSquare className="w-3.5 h-3.5 text-amber-700 mt-0.5 shrink-0" />
                      <div>
                        <span className="font-bold text-amber-900 block text-[11px]">Special Instructions:</span>
                        <p className="text-gray-800 font-medium">{order.specialNotes}</p>
                      </div>
                    </div>
                  )}

                  {order.status === 'Cancelled' && order.cancellationReason && (
                    <div className="p-2.5 bg-red-50 rounded-xl border border-red-200 text-xs flex items-start gap-2">
                      <AlertCircle className="w-3.5 h-3.5 text-red-600 mt-0.5 shrink-0" />
                      <div>
                        <span className="font-bold text-red-900 block text-[11px]">Cancellation Reason:</span>
                        <p className="text-red-800 font-semibold">{order.cancellationReason}</p>
                      </div>
                    </div>
                  )}

                  <div className="flex items-center justify-between text-xs text-gray-600 pt-1">
                    <div className="flex items-center gap-1">
                      <Phone className="w-3.5 h-3.5 text-gray-400" />
                      <span>{order.mobileNumber}</span>
                    </div>
                    {order.status !== 'Cancelled' && (
                      <div className="flex items-center gap-1 font-semibold text-primary-800 bg-primary-50 px-2 py-1 rounded-lg">
                        <Clock className="w-3.5 h-3.5 text-primary-700" />
                        <span>Est. Time: {order.estimatedDeliveryTime}</span>
                      </div>
                    )}
                  </div>

                  {/* Action Buttons */}
                  <div className="pt-2 flex items-center justify-end gap-2 border-t border-gray-100">
                    {order.status !== 'Delivered' && order.status !== 'Cancelled' && (
                      <button
                        onClick={() => {
                          setSelectedCancelModalOrder(order);
                          setCancelReason('Kitchen out of stock / High rush');
                        }}
                        className="border border-red-200 hover:bg-red-50 text-red-700 text-xs font-bold px-3 py-2 rounded-xl transition flex items-center gap-1"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        Cancel Order
                      </button>
                    )}

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

                    {order.status === 'Cancelled' && (
                      <span className="text-xs text-red-700 font-bold flex items-center gap-1">
                        <AlertCircle className="w-4 h-4 text-red-600" />
                        Order Cancelled
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      ) : (
        /* TAB 2: Manage Special Food Items & Prices + CREATE NEW FOOD ITEM */
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 bg-emerald-50 p-4 rounded-2xl border border-emerald-200">
            <div className="text-xs text-emerald-900 font-medium">
              💡 <strong>Dynamic Menu & Pricing:</strong> Create new food items or edit existing rates. Everything updates in real-time in the Student Mobile App!
            </div>
            <button
              onClick={openCreateModal}
              className="bg-primary-800 hover:bg-primary-900 text-white text-xs font-bold px-4 py-2.5 rounded-xl transition flex items-center gap-1.5 shadow-sm whitespace-nowrap"
            >
              <Plus className="w-4 h-4" />
              + Add New Food Item
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {menuItems.map(item => (
              <div
                key={item.id}
                className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-3 relative"
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="p-2.5 bg-amber-50 rounded-xl text-orange-600 border border-amber-200">
                      <Utensils className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="font-extrabold text-gray-900 text-base">{item.name}</h3>
                      <p className="text-xs text-gray-500">{item.hindiName}</p>
                    </div>
                  </div>
                  <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${
                    item.isAvailable ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {item.isAvailable ? 'ACTIVE' : 'DISABLED'}
                  </span>
                </div>

                <p className="text-xs text-gray-600 line-clamp-2">{item.description || 'Special hostel fast food item prepared fresh by mess staff.'}</p>

                <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                  <div>
                    <span className="text-[10px] text-gray-400 block font-bold">CURRENT RATE</span>
                    <span className="text-xl font-black text-primary-800">₹{item.price}</span>
                  </div>
                  <button
                    onClick={() => openEditModal(item)}
                    className="bg-primary-800 hover:bg-primary-900 text-white text-xs font-bold px-3.5 py-2 rounded-xl transition flex items-center gap-1.5 shadow-sm"
                  >
                    <Edit3 className="w-3.5 h-3.5" />
                    Edit Price & Details
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Edit / Create Menu Item Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-gray-200 animate-in fade-in zoom-in-95">
            <h3 className="text-lg font-display font-bold text-gray-900 flex items-center gap-2">
              {isCreatingNew ? (
                <>
                  <Plus className="w-5 h-5 text-primary-700" />
                  Create New Special Food Item
                </>
              ) : (
                <>
                  <Edit3 className="w-5 h-5 text-primary-700" />
                  Edit Special Food Item & Price
                </>
              )}
            </h3>
            
            <div className="space-y-3 text-xs">
              <div>
                <label className="font-bold text-gray-700 block mb-1">Food Item Name (English) *</label>
                <input
                  type="text"
                  placeholder="e.g., Crispy Spring Roll / Chicken Biryani"
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                  className="w-full p-2.5 border rounded-xl font-semibold"
                />
              </div>

              <div>
                <label className="font-bold text-gray-700 block mb-1">Item Name (Hindi Optional)</label>
                <input
                  type="text"
                  placeholder="e.g., स्प्रिंग रोल"
                  value={editHindiName}
                  onChange={e => setEditHindiName(e.target.value)}
                  className="w-full p-2.5 border rounded-xl"
                />
              </div>

              <div>
                <label className="font-bold text-gray-700 block mb-1">Price Rate (₹) *</label>
                <div className="relative">
                  <span className="absolute left-3 top-2.5 font-bold text-gray-500">₹</span>
                  <input
                    type="number"
                    value={editPrice}
                    onChange={e => setEditPrice(parseInt(e.target.value) || 0)}
                    className="w-full p-2.5 pl-7 border rounded-xl font-bold text-sm"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-gray-700 block mb-1">Description / Ingredients</label>
                <textarea
                  placeholder="e.g., Freshly prepared with organic vegetables and special spices."
                  value={editDescription}
                  onChange={e => setEditDescription(e.target.value)}
                  rows={2}
                  className="w-full p-2.5 border rounded-xl"
                />
              </div>

              <div className="flex items-center gap-2 pt-1">
                <input
                  type="checkbox"
                  id="availCheck"
                  checked={editAvailable}
                  onChange={e => setEditAvailable(e.target.checked)}
                  className="w-4 h-4 text-primary-800 rounded"
                />
                <label htmlFor="availCheck" className="font-bold text-gray-800 cursor-pointer">
                  Available for Student Ordering
                </label>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-gray-100">
              <button
                onClick={() => {
                  setIsModalOpen(false);
                  setCurrentEditingId(null);
                }}
                className="px-4 py-2 text-xs font-bold text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveMenuItem}
                className="bg-primary-800 hover:bg-primary-900 text-white text-xs font-bold px-5 py-2.5 rounded-xl transition shadow-sm flex items-center gap-1.5"
              >
                <Check className="w-4 h-4" />
                {isCreatingNew ? 'Create & Sync to Students' : 'Save & Sync Changes'}
              </button>
            </div>
          </div>
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

      {/* Cancel Order with Reason Modal */}
      {selectedCancelModalOrder && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-gray-200 animate-in fade-in zoom-in-95">
            <h3 className="text-lg font-display font-bold text-red-900 flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-red-600" />
              Cancel Special Food Order
            </h3>
            <p className="text-xs text-gray-600">
              State the reason why order for <strong className="text-gray-900">{selectedCancelModalOrder.studentName}</strong> (Room {selectedCancelModalOrder.roomNo} • {selectedCancelModalOrder.foodItemName}) is being cancelled. This will notify the student instantly!
            </p>

            <div className="space-y-2">
              <label className="text-xs font-bold text-gray-700 block">Cancellation Reason *</label>
              <input
                type="text"
                value={cancelReason}
                onChange={e => setCancelReason(e.target.value)}
                placeholder="e.g. Out of eggs / paneer, Kitchen closed, High rush"
                className="w-full p-2.5 text-xs border rounded-xl font-medium focus:ring-2 focus:ring-red-300"
              />

              <div className="flex flex-wrap gap-1.5 pt-1">
                {[
                  'Kitchen out of stock',
                  'Heavy dinner rush',
                  'Special chef unavailable',
                  'Item temporarily sold out',
                ].map(r => (
                  <button
                    key={r}
                    type="button"
                    onClick={() => setCancelReason(r)}
                    className="text-[11px] bg-gray-100 hover:bg-gray-200 text-gray-700 px-2.5 py-1 rounded-lg font-semibold"
                  >
                    {r}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-gray-100">
              <button
                onClick={() => setSelectedCancelModalOrder(null)}
                className="px-4 py-2 text-xs font-bold text-gray-600 hover:text-gray-800"
              >
                Back
              </button>
              <button
                onClick={() => handleCancelOrder(selectedCancelModalOrder.id, cancelReason.trim() || 'Order cancelled by mess manager')}
                className="bg-red-700 hover:bg-red-800 text-white text-xs font-bold px-5 py-2.5 rounded-xl transition shadow-sm"
              >
                Confirm Cancellation
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
