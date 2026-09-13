import React, { useState, useEffect } from "react";
import QRCode from "qrcode";
import { H4_STUDENTS_LIST } from "../../data/h4StudentsData";
import { Building2, Utensils, RefreshCw, Clock } from "lucide-react";

interface ScannedEntry {
  slNo: number;
  name: string;
  rollNo: string;
  registrationNo: string;
  branch: string;
  roomNo: string;
  scannedAt: string;
  token: string;
}

const FIRESTORE_KEY = "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E";
const FIRESTORE_BASE = "https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents";
const QR_ROTATE_SECONDS = 60;

function getActiveMeal(): "Breakfast" | "Lunch" | "Dinner" {
  const mins = new Date().getHours() * 60 + new Date().getMinutes();
  if (mins < 10 * 60 + 30) return "Breakfast"; // before 10:30 AM
  if (mins < 15 * 60 + 30) return "Lunch";      // 10:30 AM - 3:30 PM
  return "Dinner";                               // after 3:30 PM
}

function generateToken(): string {
  const ts = Date.now();
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `SMARTMESS_H4_${ts}_${rand}`;
}

async function pushTokenToFirestore(token: string): Promise<void> {
  const meal = getActiveMeal();
  try {
    const expiresAt = new Date(Date.now() + QR_ROTATE_SECONDS * 1000).toISOString();
    await fetch(`${FIRESTORE_BASE}/qrConfig/liveToken?key=${FIRESTORE_KEY}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fields: {
          token:     { stringValue: token },
          mealType:  { stringValue: meal },
          hostelId:  { stringValue: "Hostel Number 4" },
          issuedAt:  { stringValue: new Date().toISOString() },
          expiresAt: { stringValue: expiresAt },
          isValid:   { booleanValue: true },
        },
      }),
    });
  } catch (_) {}
}

export const QRAttendancePage: React.FC = () => {
  const [qrCodeUrl, setQrCodeUrl] = useState<string>("");
  const [currentToken, setCurrentToken] = useState<string>("");
  const [countdown, setCountdown] = useState<number>(QR_ROTATE_SECONDS);
  const [activeMeal, setActiveMeal] = useState<string>(getActiveMeal());
  const [selectedMeal, setSelectedMeal] = useState<"Breakfast" | "Lunch" | "Dinner">(getActiveMeal());
  const [scannedEntries, setScannedEntries] = useState<ScannedEntry[]>([]);
  const [isRotating, setIsRotating] = useState(false);

  const totalStudents = H4_STUDENTS_LIST.length;
  const scannedCount = scannedEntries.length;
  const pendingCount = Math.max(0, totalStudents - scannedCount);

  // ── Rotate QR (no meal param — meal auto-detected from time) ──────────
  const rotateQR = async () => {
    setIsRotating(true);
    const token = generateToken();
    const meal = getActiveMeal();
    setCurrentToken(token);
    setActiveMeal(meal);
    setCountdown(QR_ROTATE_SECONDS);
    await pushTokenToFirestore(token);
    try {
      const url = await QRCode.toDataURL(token, {
        width: 320,
        margin: 1,
        color: { dark: "#1B5E20", light: "#FFFFFF" },
      });
      setQrCodeUrl(url);
    } catch (_) {}
    setTimeout(() => setIsRotating(false), 400);
  };

  // ── Auto-rotate every 60 s ────────────────────────────────────────────
  useEffect(() => {
    rotateQR();
    const id = setInterval(() => rotateQR(), QR_ROTATE_SECONDS * 1000);
    return () => clearInterval(id);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Update active meal label every minute ─────────────────────────────
  useEffect(() => {
    const id = setInterval(() => setActiveMeal(getActiveMeal()), 60000);
    return () => clearInterval(id);
  }, []);

  // ── Countdown ticker ──────────────────────────────────────────────────
  useEffect(() => {
    const id = setInterval(() => {
      setCountdown((prev) => (prev <= 1 ? QR_ROTATE_SECONDS : prev - 1));
    }, 1000);
    return () => clearInterval(id);
  }, []);

  // ── Fetch live attendance (filtered by selected meal for table) ───────
  const fetchLiveScans = async () => {
    try {
      const res = await fetch(`${FIRESTORE_BASE}:runQuery?key=${FIRESTORE_KEY}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ structuredQuery: { from: [{ collectionId: "mealAttendance" }] } }),
      });
      if (!res.ok) return;
      const data = await res.json();
      if (!Array.isArray(data)) return;
      const today = new Date();
      const list: ScannedEntry[] = [];
      let idx = 1;
      for (const item of data) {
        if (!item.document?.fields) continue;
        const f = item.document.fields;
        const meal = f.mealType?.stringValue || "";
        const scanTimeStr: string = f.scannedAt?.stringValue || "";
        if (!scanTimeStr) continue;
        const scanDate = new Date(scanTimeStr);
        const isToday =
          scanDate.getFullYear() === today.getFullYear() &&
          scanDate.getMonth() === today.getMonth() &&
          scanDate.getDate() === today.getDate();
        if (isToday && meal.toLowerCase() === selectedMeal.toLowerCase()) {
          list.push({
            slNo: idx++,
            name: f.studentName?.stringValue || "Student",
            rollNo: f.rollNo?.stringValue || "",
            registrationNo: f.registrationNo?.stringValue || "",
            branch: f.branch?.stringValue || "CSE",
            roomNo: f.roomNo?.stringValue || "",
            scannedAt: scanDate.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
            token: f.id?.stringValue || "",
          });
        }
      }
      setScannedEntries(list);
    } catch (_) {}
  };

  useEffect(() => {
    fetchLiveScans();
    const id = setInterval(fetchLiveScans, 3000);
    return () => clearInterval(id);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedMeal]);

  // ── Countdown ring maths ──────────────────────────────────────────────
  const radius = 22;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference - (countdown / QR_ROTATE_SECONDS) * circumference;
  const ringColor = countdown <= 10 ? "#EF4444" : "#10B981";

  const mealEmoji: Record<string, string> = {
    Breakfast: "🌅",
    Lunch: "☀️",
    Dinner: "🌙",
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">

      {/* ── Top Banner ─────────────────────────────────────────────────── */}
      <div className="bg-gradient-to-r from-primary-900 via-primary-800 to-primary-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary-200 text-sm font-medium">
            <Building2 className="w-4 h-4 text-emerald-400" />
            <span>Hostel Number 4 &bull; Dynamic Mess Counter</span>
          </div>
          <h1 className="text-2xl md:text-3xl font-bold font-display tracking-tight text-white mt-1">
            Live Dynamic QR Code
          </h1>
          <p className="text-primary-200 text-sm mt-1">
            One universal QR &mdash; meal type is detected automatically from scan time. Rotates every {QR_ROTATE_SECONDS}s.
          </p>
        </div>
        {/* Active meal badge (auto, not selectable for QR) */}
        <div className="flex flex-col items-end gap-1">
          <div className="flex items-center gap-2 bg-emerald-500/20 border border-emerald-400/30 px-4 py-2 rounded-xl">
            <Clock className="w-4 h-4 text-emerald-300" />
            <span className="text-white font-bold text-sm">
              {mealEmoji[activeMeal]} Current Meal: {activeMeal}
            </span>
          </div>
          <p className="text-primary-300 text-xs">Auto-detected from current time</p>
        </div>
      </div>

      {/* ── Main Grid ──────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">

        {/* ── LEFT: Single Universal QR ────────────────────────────────── */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col items-center text-center space-y-4">

          {/* Header */}
          <div className="flex items-center justify-between w-full border-b border-gray-100 pb-3">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Universal QR &bull; All Meals
            </span>
            <div className="flex items-center gap-1.5 bg-emerald-50 text-emerald-800 text-xs font-bold px-2.5 py-1 rounded-full">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse inline-block"></span>
              Auto-Rotating
            </div>
          </div>

          {/* QR Code */}
          <div
            className="p-4 bg-white rounded-2xl border-2 border-primary-800/30 shadow-md"
            style={{
              opacity: isRotating ? 0 : 1,
              transform: isRotating ? "scale(0.95)" : "scale(1)",
              transition: "opacity 0.3s, transform 0.3s",
            }}
          >
            {qrCodeUrl ? (
              <img src={qrCodeUrl} alt="Universal QR Code" className="w-60 h-60 rounded-lg" />
            ) : (
              <div className="w-60 h-60 bg-gray-100 flex items-center justify-center rounded-lg text-gray-400 text-sm">
                Generating...
              </div>
            )}
          </div>

          {/* Countdown bar below QR — not overlapping */}
          <div className="flex items-center gap-3 bg-gray-50 rounded-xl px-4 py-3 border border-gray-100 w-full justify-center">
            <svg width="52" height="52" viewBox="0 0 56 56" className="flex-shrink-0">
              <circle cx="28" cy="28" r={radius} fill="none" stroke="#E5E7EB" strokeWidth="4" />
              <circle
                cx="28" cy="28" r={radius}
                fill="none"
                stroke={ringColor}
                strokeWidth="4"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={dashOffset}
                transform="rotate(-90 28 28)"
                style={{ transition: "stroke-dashoffset 0.9s linear, stroke 0.3s" }}
              />
              <text x="28" y="33" textAnchor="middle" fontSize="13" fontWeight="bold" fill={countdown <= 10 ? "#EF4444" : "#1B5E20"}>
                {countdown}
              </text>
            </svg>
            <div className="text-left">
              <p className={`text-sm font-bold ${countdown <= 10 ? "text-red-600" : "text-emerald-700"}`}>
                {countdown <= 10 ? "⚠ Expiring soon!" : "✓ QR is Valid"}
              </p>
              <p className="text-[11px] text-gray-500">Next rotation in {countdown}s</p>
            </div>
          </div>

          {/* Current token info */}
          <div className="w-full bg-gray-50 rounded-xl p-3 border border-gray-100 text-left space-y-1">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-gray-500 uppercase tracking-wider">Current Token</span>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${countdown <= 10 ? "bg-red-100 text-red-700" : "bg-emerald-100 text-emerald-700"}`}>
                {countdown <= 10 ? `Expires in ${countdown}s` : `Valid for ${countdown}s`}
              </span>
            </div>
            <p className="text-[10px] font-mono text-gray-600 break-all leading-relaxed">{currentToken || "—"}</p>
          </div>

          {/* Manual rotate */}
          <button
            onClick={() => rotateQR()}
            className="w-full py-2.5 px-3 bg-[#1B8E2D] hover:bg-[#157324] text-white text-xs font-bold rounded-xl shadow-sm hover:shadow transition-all flex items-center justify-center gap-1.5"
          >
            <RefreshCw className="w-4 h-4" />
            Rotate QR Now
          </button>

          <p className="text-[11px] text-gray-500 bg-amber-50 p-2.5 rounded-xl border border-amber-100 w-full text-left leading-relaxed">
            💡 <strong>How it works:</strong> Students scan this one QR. The app automatically records it as <strong>{activeMeal}</strong> based on the current time. No manual meal selection needed.
          </p>
        </div>

        {/* ── RIGHT: Live Attendance Feed ───────────────────────────────── */}
        <div className="lg:col-span-7 space-y-4">

          {/* Meal tabs — only for filtering the attendance TABLE */}
          <div className="bg-white rounded-2xl border border-gray-200 p-3 shadow-sm">
            <p className="text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-2 px-1">View attendance by meal</p>
            <div className="flex gap-2">
              {(["Breakfast", "Lunch", "Dinner"] as const).map((meal) => (
                <button
                  key={meal}
                  onClick={() => setSelectedMeal(meal)}
                  className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                    selectedMeal === meal
                      ? "bg-primary-800 text-white shadow-sm"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  <Utensils className="w-3.5 h-3.5" />
                  {mealEmoji[meal]} {meal}
                </button>
              ))}
            </div>
          </div>

          {/* Metrics */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Scanned &amp; Eaten</span>
              <span className="text-2xl font-bold text-emerald-700">{scannedCount}</span>
              <span className="text-[11px] text-emerald-600 font-bold block mt-0.5">{((scannedCount / totalStudents) * 100).toFixed(1)}% Turnout</span>
            </div>
            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Pending Boarders</span>
              <span className="text-2xl font-bold text-amber-700">{pendingCount}</span>
              <span className="text-[11px] text-gray-500 font-medium block mt-0.5">Remaining</span>
            </div>
            <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm text-center">
              <span className="text-xs font-semibold text-gray-500 block">Total Boarders</span>
              <span className="text-2xl font-bold text-gray-900">{totalStudents}</span>
              <span className="text-[11px] text-primary-700 font-bold block mt-0.5">H4 Roster</span>
            </div>
          </div>

          {/* Live attendance table */}
          <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse inline-block"></span>
                <h3 className="font-bold text-gray-900 text-sm">Live Feed &bull; {mealEmoji[selectedMeal]} {selectedMeal}</h3>
              </div>
              <span className="text-xs text-gray-500 font-medium">Auto-refreshing (3s)</span>
            </div>
            <div className="overflow-x-auto max-h-[380px] overflow-y-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50 text-gray-600 font-bold sticky top-0 border-b border-gray-100 z-10">
                  <tr>
                    <th className="py-2.5 px-3">#</th>
                    <th className="py-2.5 px-3">Student Name</th>
                    <th className="py-2.5 px-3">Roll No.</th>
                    <th className="py-2.5 px-3">Room</th>
                    <th className="py-2.5 px-3">Time</th>
                    <th className="py-2.5 px-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 text-gray-800">
                  {scannedEntries.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-10 text-gray-400">
                        No students scanned for {selectedMeal} yet today.
                      </td>
                    </tr>
                  ) : (
                    scannedEntries.map((entry) => (
                      <tr key={entry.slNo} className="hover:bg-emerald-50/40 transition-colors">
                        <td className="py-2.5 px-3 font-mono text-gray-400">{entry.slNo}</td>
                        <td className="py-2.5 px-3 font-semibold text-gray-900">{entry.name}</td>
                        <td className="py-2.5 px-3 font-mono text-emerald-800 font-bold">{entry.rollNo}</td>
                        <td className="py-2.5 px-3 font-medium text-gray-600">Room {entry.roomNo}</td>
                        <td className="py-2.5 px-3 text-gray-500 font-mono">{entry.scannedAt}</td>
                        <td className="py-2.5 px-3 text-right">
                          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">Verified</span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
