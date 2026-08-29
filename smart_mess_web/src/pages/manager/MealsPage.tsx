import React, { useState } from 'react';
import { useAuthStore } from '../../store/authStore';
import { Calendar, Clock, Edit2, Plus, Info, ShieldCheck, Sparkles, Utensils } from 'lucide-react';
import toast from 'react-hot-toast';

interface WeeklyMenuItem {
  id: string;
  dayHindi: string;
  dayEnglish: string;
  breakfast: {
    time: string;
    cutoff: string;
    itemsHindi: string;
    itemsEnglish: string;
    price: number;
    isAvailable?: boolean;
  };
  lunch: {
    time: string;
    cutoff: string;
    itemsHindi: string;
    itemsEnglish: string;
    price: number;
  };
  dinner: {
    time: string;
    cutoff: string;
    itemsHindi: string;
    itemsEnglish: string;
    price: number;
  };
}

const DEFAULT_WEEKLY_MENU: WeeklyMenuItem[] = [
  {
    id: 'mon',
    dayHindi: 'सोमवार',
    dayEnglish: 'Monday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'मुगलाई पराठा-1 / सूजी पराठा-3, सब्जी, हलवा',
      itemsEnglish: 'Mughlai Paratha / Sooji Paratha, Sabji, Halwa',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'रोटी, चावल, दाल, सब्जी, भुजिया, सलाद',
      itemsEnglish: 'Roti, Rice, Dal, Sabji, Bhujia, Salad',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'रोटी, मटरपनीर',
      itemsEnglish: 'Roti, Matar Paneer',
      price: 50,
    },
  },
  {
    id: 'tue',
    dayHindi: 'मंगलवार',
    dayEnglish: 'Tuesday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'आलू पराठा-3, सब्जी',
      itemsEnglish: 'Aloo Paratha (3 pcs), Sabji',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'रोटी, चावल, दाल, सब्जी, चोखा, पापड़',
      itemsEnglish: 'Roti, Rice, Dal, Sabji, Chokha, Papad',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'रोटी, जीरा राईस, दाल तड़का, भुजिया',
      itemsEnglish: 'Roti, Jeera Rice, Dal Tadka, Bhujia',
      price: 50,
    },
  },
  {
    id: 'wed',
    dayHindi: 'बुधवार',
    dayEnglish: 'Wednesday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'पूरी-6, सब्जी, जलेबी-2',
      itemsEnglish: 'Poori (6 pcs), Sabji, Jalebi (2 pcs)',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'रोटी, चावल, दाल, मौसमी सब्जी, पकोड़ा, सलाद',
      itemsEnglish: 'Roti, Rice, Dal, Seasonal Sabji, Pakoda, Salad',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'रोटी, चावल, दाल तड़का, पनीर-4 / चिकन-2 पीस, सलाद',
      itemsEnglish: 'Roti, Rice, Dal Tadka, Paneer (4 pcs) / Chicken (2 pcs), Salad',
      price: 100,
    },
  },
  {
    id: 'thu',
    dayHindi: 'गुरुवार',
    dayEnglish: 'Thursday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'इटली-4 सांभर / पूरी-6, सब्जी',
      itemsEnglish: 'Idli (4 pcs) Sambar / Poori (6 pcs), Sabji',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'रोटी, चावल, दाल, सब्जी, चोखा, सलाद, पापड़',
      itemsEnglish: 'Roti, Rice, Dal, Sabji, Chokha, Salad, Papad',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'पूरी, सब्जी, सेवई',
      itemsEnglish: 'Poori, Sabji, Sewai',
      price: 50,
    },
  },
  {
    id: 'fri',
    dayHindi: 'शुक्रवार',
    dayEnglish: 'Friday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'पराठा-3, भुजिया',
      itemsEnglish: 'Plain Paratha (3 pcs), Bhujia',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'रोटी, चावल, दाल, मौसमी सब्जी, भुजिया',
      itemsEnglish: 'Roti, Rice, Dal, Seasonal Sabji, Bhujia',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'अंडा करी-2 पीस / पनीर-4 पीस, मिठाई, रोटी, दाल, चावल',
      itemsEnglish: 'Egg Curry (2 pcs) / Paneer (4 pcs), Sweet, Roti, Dal, Rice',
      price: 50,
    },
  },
  {
    id: 'sat',
    dayHindi: 'शनिवार',
    dayEnglish: 'Saturday',
    breakfast: {
      time: '08:00 AM - 09:30 AM',
      cutoff: '07:00 AM',
      itemsHindi: 'छोला भटूरा-2, अचार',
      itemsEnglish: 'Chole Bhature (2 pcs), Pickle',
      price: 25,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'राजमा, चावल, भुजिया, पापड़, सलाद',
      itemsEnglish: 'Rajma, Rice, Bhujia, Papad, Salad',
      price: 50,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'सत्तू पराठा, सब्जी, सलाद, लाल चटनी',
      itemsEnglish: 'Sattu Paratha, Sabji, Salad, Red Chutney',
      price: 50,
    },
  },
  {
    id: 'sun',
    dayHindi: 'रविवार',
    dayEnglish: 'Sunday',
    breakfast: {
      time: 'Closed',
      cutoff: 'N/A',
      itemsHindi: 'रविवार को नाश्ता बंद रहता है',
      itemsEnglish: 'No Breakfast served on Sundays',
      price: 0,
      isAvailable: false,
    },
    lunch: {
      time: '01:00 PM - 02:30 PM',
      cutoff: '11:00 AM',
      itemsHindi: 'पुलाव, चिकन - 2 पीस / मशरूम 4- पीस, मिठाई, सलाद',
      itemsEnglish: 'Pulao, Chicken (2 pcs) / Mushroom (4 pcs), Sweet, Salad',
      price: 100,
    },
    dinner: {
      time: '08:00 PM - 09:30 PM',
      cutoff: '06:00 PM',
      itemsHindi: 'रोटी, चना सब्जी, खीर',
      itemsEnglish: 'Roti, Chana Sabji, Kheer',
      price: 50,
    },
  },
];

export const MealsPage: React.FC = () => {
  const { user } = useAuthStore();
  const [weeklyMenu, setWeeklyMenu] = useState<WeeklyMenuItem[]>(DEFAULT_WEEKLY_MENU);
  const [editingDay, setEditingDay] = useState<WeeklyMenuItem | null>(null);
  const [activeTab, setActiveTab] = useState<'weekly' | 'rules'>('weekly');

  React.useEffect(() => {
    const fetchCloudMenu = async () => {
      try {
        const res = await fetch(
          'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/settings/weekly_menu?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E'
        );
        if (res.ok) {
          const doc = await res.json();
          if (doc.fields && doc.fields.daysJson?.stringValue) {
            const parsed = JSON.parse(doc.fields.daysJson.stringValue);
            if (Array.isArray(parsed) && parsed.length > 0) {
              setWeeklyMenu(parsed);
            }
          }
        }
      } catch (_) {}
    };
    fetchCloudMenu();
  }, []);

  const handleSaveEdit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!editingDay) return;
    const formData = new FormData(e.currentTarget);
    
    const updatedMenu = weeklyMenu.map(day => {
      if (day.id === editingDay.id) {
        return {
          ...day,
          breakfast: {
            ...day.breakfast,
            itemsHindi: formData.get('bHindi') as string,
            itemsEnglish: formData.get('bEnglish') as string,
            time: formData.get('bTime') as string,
            cutoff: formData.get('bCutoff') as string,
          },
          lunch: {
            ...day.lunch,
            itemsHindi: formData.get('lHindi') as string,
            itemsEnglish: formData.get('lEnglish') as string,
            time: formData.get('lTime') as string,
            cutoff: formData.get('lCutoff') as string,
          },
          dinner: {
            ...day.dinner,
            itemsHindi: formData.get('dHindi') as string,
            itemsEnglish: formData.get('dEnglish') as string,
            time: formData.get('dTime') as string,
            cutoff: formData.get('dCutoff') as string,
          },
        };
      }
      return day;
    });

    setWeeklyMenu(updatedMenu);
    toast.success(`Updated menu schedule for ${editingDay.dayEnglish}!`);
    setEditingDay(null);

    // Persist to Cloud Firestore for Flutter app sync
    try {
      await fetch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/settings/weekly_menu?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              daysJson: { stringValue: JSON.stringify(updatedMenu) },
              updatedAt: { stringValue: new Date().toISOString() }
            }
          })
        }
      );
    } catch (_) {}
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Institution & Hostel Header */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
              <Utensils className="w-4 h-4 text-emerald-400" />
              Smart Mess Dining System • Central Dining Facility
            </div>
            <h1 className="text-2xl md:text-3xl font-display font-bold mt-1">
              Hostel Dining & Weekly Meal Menu
            </h1>
            <p className="text-primary-200 text-sm mt-1">
              Official Weekly Schedule & Strict Mess-Off Cutoff Enforcements
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab('weekly')}
              className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
                activeTab === 'weekly' ? 'bg-white text-primary-900 shadow' : 'bg-primary-800 text-primary-200 hover:bg-primary-700'
              }`}
            >
              Weekly Timetable
            </button>
            <button
              onClick={() => setActiveTab('rules')}
              className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
                activeTab === 'rules' ? 'bg-white text-primary-900 shadow' : 'bg-primary-800 text-primary-200 hover:bg-primary-700'
              }`}
            >
              Mess Rules & Cutoffs
            </button>
          </div>
        </div>
      </div>

      {/* Strict Cutoff Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-xl border border-amber-200 shadow-sm flex items-start gap-3">
          <div className="p-2.5 bg-amber-50 text-amber-700 rounded-lg shrink-0">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-amber-800 uppercase">नाश्ता (Breakfast)</span>
              <span className="text-xs bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded">Cutoff: 07:00 AM</span>
            </div>
            <p className="text-sm font-bold text-gray-900 mt-1">08:00 AM – 09:30 AM</p>
            <p className="text-xs text-gray-500 mt-0.5">Mess-Off must be applied before 7:00 AM</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-blue-200 shadow-sm flex items-start gap-3">
          <div className="p-2.5 bg-blue-50 text-blue-700 rounded-lg shrink-0">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-blue-800 uppercase">मध्याह्न भोजन (Lunch)</span>
              <span className="text-xs bg-blue-100 text-blue-900 font-bold px-2 py-0.5 rounded">Cutoff: 11:00 AM</span>
            </div>
            <p className="text-sm font-bold text-gray-900 mt-1">01:00 PM – 02:30 PM</p>
            <p className="text-xs text-gray-500 mt-0.5">Mess-Off must be applied before 11:00 AM</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-purple-200 shadow-sm flex items-start gap-3">
          <div className="p-2.5 bg-purple-50 text-purple-700 rounded-lg shrink-0">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-purple-800 uppercase">रात्रि भोजन (Dinner)</span>
              <span className="text-xs bg-purple-100 text-purple-900 font-bold px-2 py-0.5 rounded">Cutoff: 06:00 PM</span>
            </div>
            <p className="text-sm font-bold text-gray-900 mt-1">08:00 PM – 09:30 PM</p>
            <p className="text-xs text-gray-500 mt-0.5">Mess-Off must be applied before 6:00 PM</p>
          </div>
        </div>
      </div>

      {activeTab === 'weekly' ? (
        /* Full Weekly Timetable Table */
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <div>
              <h3 className="font-display font-bold text-gray-900 text-base">Weekly Menu Timetable</h3>
              <p className="text-xs text-gray-500">Admin & Manager can customize menu items and special preparations</p>
            </div>
            <span className="text-xs text-primary-700 bg-primary-50 border border-primary-200 font-medium px-3 py-1 rounded-full">
              7 Days Configured
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 text-left text-sm">
              <thead className="bg-gray-50 text-xs font-bold text-gray-600 uppercase tracking-wider">
                <tr>
                  <th className="px-5 py-4 w-32">दिन (Day)</th>
                  <th className="px-5 py-4">नाश्ता (Breakfast)<br/><span className="text-[10px] font-normal text-amber-700 font-mono">Cutoff: 07:00 AM</span></th>
                  <th className="px-5 py-4">मध्याह्न भोजन (Lunch)<br/><span className="text-[10px] font-normal text-blue-700 font-mono">Cutoff: 11:00 AM</span></th>
                  <th className="px-5 py-4">रात्रि भोजन (Dinner)<br/><span className="text-[10px] font-normal text-purple-700 font-mono">Cutoff: 06:00 PM</span></th>
                  <th className="px-4 py-4 text-center w-24">Action</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-100">
                {weeklyMenu.map((day) => (
                  <tr key={day.id} className="hover:bg-gray-50/80 transition-colors">
                    <td className="px-5 py-4 align-top font-semibold text-gray-900 bg-gray-50/30">
                      <div className="font-display font-bold text-base text-primary-900">{day.dayHindi}</div>
                      <div className="text-xs text-gray-500 font-normal">{day.dayEnglish}</div>
                    </td>
                    <td className="px-5 py-4 align-top">
                      <div className="flex items-center gap-2">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                          day.breakfast.isAvailable === false ? 'bg-gray-100 text-gray-600' : 'bg-amber-100 text-amber-900'
                        }`}>
                          {day.breakfast.isAvailable === false ? 'NO BREAKFAST' : `₹${day.breakfast.price}`}
                        </span>
                      </div>
                      <div className="font-medium text-gray-900 text-sm mt-1">{day.breakfast.itemsHindi}</div>
                      <div className="text-xs text-gray-500 mt-0.5">{day.breakfast.itemsEnglish}</div>
                    </td>
                    <td className="px-5 py-4 align-top">
                      <div className="flex items-center gap-2">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                          day.lunch.price === 100 ? 'bg-orange-100 text-orange-900 border border-orange-200' : 'bg-blue-100 text-blue-900'
                        }`}>
                          {day.lunch.price === 100 ? 'SPECIAL FEAST • ₹100' : `₹${day.lunch.price}`}
                        </span>
                      </div>
                      <div className="font-medium text-gray-900 text-sm mt-1">{day.lunch.itemsHindi}</div>
                      <div className="text-xs text-gray-500 mt-0.5">{day.lunch.itemsEnglish}</div>
                    </td>
                    <td className="px-5 py-4 align-top">
                      <div className="flex items-center gap-2">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                          day.dinner.price === 100 ? 'bg-orange-100 text-orange-900 border border-orange-200' : 'bg-purple-100 text-purple-900'
                        }`}>
                          {day.dinner.price === 100 ? 'NON-VEG FEAST • ₹100' : `₹${day.dinner.price}`}
                        </span>
                      </div>
                      <div className="font-medium text-gray-900 text-sm mt-1">{day.dinner.itemsHindi}</div>
                      <div className="text-xs text-gray-500 mt-0.5">{day.dinner.itemsEnglish}</div>
                    </td>
                    <td className="px-4 py-4 align-top text-center">
                      <button
                        onClick={() => setEditingDay(day)}
                        className="inline-flex items-center gap-1 text-primary-700 hover:text-primary-900 bg-primary-50 hover:bg-primary-100 px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors"
                      >
                        <Edit2 className="w-3.5 h-3.5" /> Edit
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Official Mess Rules Box */
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-6">
          <div className="flex items-center gap-2 border-b border-gray-100 pb-4">
            <ShieldCheck className="w-6 h-6 text-primary-700" />
            <h3 className="text-lg font-display font-bold text-gray-900">Official Hostel Mess Regulations & Billing Tariffs</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-gray-50 border border-gray-100 space-y-2">
              <span className="text-xs font-bold text-primary-800 uppercase tracking-wide">1. Official Meal Tariff Rates</span>
              <p className="text-sm text-gray-800 font-medium">
                • <strong>Breakfast</strong>: ₹25 / morning (Mon–Sat; Closed on Sunday)<br/>
                • <strong>Regular Lunch</strong>: ₹50 / meal (Mon–Sat)<br/>
                • <strong>Sunday Special Feast Lunch</strong>: ₹100 / person (Pulao, Chicken/Mushroom & Sweet)<br/>
                • <strong>Regular Dinner</strong>: ₹50 / meal<br/>
                • <strong>Wednesday Special Dinner</strong>: ₹100 / person (Non-Veg Chicken / Paneer)
              </p>
            </div>

            <div className="p-4 rounded-xl bg-gray-50 border border-gray-100 space-y-2">
              <span className="text-xs font-bold text-primary-800 uppercase tracking-wide">2. Mess Off Quota</span>
              <p className="text-sm text-gray-800 font-medium">
                Maximum <strong>40 days mess off</strong> allowed per semester for a student. Prior notice must be submitted before strict cutoffs.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-gray-50 border border-gray-100 space-y-2">
              <span className="text-xs font-bold text-primary-800 uppercase tracking-wide">3. Strict Cutoff Enforcements</span>
              <p className="text-sm text-gray-800 font-medium">
                • Breakfast: Before <strong>07:00 AM</strong><br/>
                • Lunch: Before <strong>11:00 AM</strong><br/>
                • Dinner: Before <strong>06:00 PM</strong>
              </p>
            </div>

            <div className="p-4 rounded-xl bg-gray-50 border border-gray-100 space-y-2">
              <span className="text-xs font-bold text-primary-800 uppercase tracking-wide">4. Dining Hall Discipline & Zero Waste</span>
              <p className="text-sm text-gray-800 font-medium">
                Maintain discipline in dining hall. <strong>Don't waste food.</strong> QR scanning is strictly mandatory for meal issuance.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Edit Day Menu Modal */}
      {editingDay && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3 mb-4">
              <div>
                <h3 className="text-lg font-bold text-gray-900">
                  Edit Menu Schedule — {editingDay.dayHindi} ({editingDay.dayEnglish})
                </h3>
                <p className="text-xs text-gray-500">Update dishes and timing for this day</p>
              </div>
              <button onClick={() => setEditingDay(null)} className="text-gray-400 hover:text-gray-600 font-bold text-xl">✕</button>
            </div>

            <form onSubmit={handleSaveEdit} className="space-y-4">
              {/* Breakfast Edit */}
              <div className="p-3.5 bg-amber-50/50 rounded-xl border border-amber-200/80 space-y-2">
                <span className="text-xs font-bold text-amber-900 uppercase">नाश्ता (Breakfast)</span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (Hindi)</label>
                    <input name="bHindi" defaultValue={editingDay.breakfast.itemsHindi} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (English)</label>
                    <input name="bEnglish" defaultValue={editingDay.breakfast.itemsEnglish} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <label className="text-gray-600 block">Serving Time</label>
                    <input name="bTime" defaultValue={editingDay.breakfast.time} className="w-full border rounded-lg p-1.5 bg-white" />
                  </div>
                  <div>
                    <label className="text-gray-600 block">Cutoff Deadline</label>
                    <input name="bCutoff" defaultValue={editingDay.breakfast.cutoff} className="w-full border rounded-lg p-1.5 bg-white font-bold text-amber-800" />
                  </div>
                </div>
              </div>

              {/* Lunch Edit */}
              <div className="p-3.5 bg-blue-50/50 rounded-xl border border-blue-200/80 space-y-2">
                <span className="text-xs font-bold text-blue-900 uppercase">मध्याह्न भोजन (Lunch)</span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (Hindi)</label>
                    <input name="lHindi" defaultValue={editingDay.lunch.itemsHindi} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (English)</label>
                    <input name="lEnglish" defaultValue={editingDay.lunch.itemsEnglish} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <label className="text-gray-600 block">Serving Time</label>
                    <input name="lTime" defaultValue={editingDay.lunch.time} className="w-full border rounded-lg p-1.5 bg-white" />
                  </div>
                  <div>
                    <label className="text-gray-600 block">Cutoff Deadline</label>
                    <input name="lCutoff" defaultValue={editingDay.lunch.cutoff} className="w-full border rounded-lg p-1.5 bg-white font-bold text-blue-800" />
                  </div>
                </div>
              </div>

              {/* Dinner Edit */}
              <div className="p-3.5 bg-purple-50/50 rounded-xl border border-purple-200/80 space-y-2">
                <span className="text-xs font-bold text-purple-900 uppercase">रात्रि भोजन (Dinner)</span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (Hindi)</label>
                    <input name="dHindi" defaultValue={editingDay.dinner.itemsHindi} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                  <div>
                    <label className="text-xs text-gray-600 block mb-0.5">Dishes (English)</label>
                    <input name="dEnglish" defaultValue={editingDay.dinner.itemsEnglish} required className="w-full text-sm border rounded-lg p-2 bg-white" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <label className="text-gray-600 block">Serving Time</label>
                    <input name="dTime" defaultValue={editingDay.dinner.time} className="w-full border rounded-lg p-1.5 bg-white" />
                  </div>
                  <div>
                    <label className="text-gray-600 block">Cutoff Deadline</label>
                    <input name="dCutoff" defaultValue={editingDay.dinner.cutoff} className="w-full border rounded-lg p-1.5 bg-white font-bold text-purple-800" />
                  </div>
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-3 border-t border-gray-100">
                <button type="button" onClick={() => setEditingDay(null)} className="px-5 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
                <button type="submit" className="bg-primary-700 hover:bg-primary-800 text-white px-6 py-2 rounded-lg text-sm font-semibold shadow">Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
