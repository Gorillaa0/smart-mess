import React from 'react';
import { Outlet } from 'react-router-dom';
import { Target, QrCode, ShoppingBag, Building2, ShieldCheck } from 'lucide-react';

export const AuthLayout: React.FC = () => {
  return (
    <div className="min-h-screen w-full relative flex items-center justify-center p-4 sm:p-6 lg:p-12 overflow-hidden bg-slate-900">
      
      {/* 1. Full Screen Cafeteria Dining Atmosphere Background */}
      <div 
        className="absolute inset-0 bg-cover bg-center bg-no-repeat"
        style={{
          backgroundImage: `url('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1920&q=80')`,
          filter: 'brightness(0.55) contrast(1.1) saturate(1.35)',
        }}
      />

      {/* Subtle Green & Dark Vignette Gradient Over Cafeteria Photo */}
      <div className="absolute inset-0 bg-gradient-to-r from-emerald-950/85 via-emerald-950/60 to-emerald-950/40 pointer-events-none" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/30 pointer-events-none" />

      {/* 2. Main Content Container (Split Grid) */}
      <div className="w-full max-w-6xl z-10 grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center">
        
        {/* Left Hero Section: Headline, Branding & 3 Glass Cards (7 Cols) */}
        <div className="lg:col-span-7 text-white space-y-6 flex flex-col justify-between">
          
          {/* Top Pill Badge */}
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-2xl bg-emerald-950/70 border border-emerald-400/40 text-emerald-200 text-xs font-semibold backdrop-blur-md shadow-lg">
              <Building2 className="w-4 h-4 text-emerald-400" />
              <span>Smart Mess System</span>
              <span className="text-emerald-500">•</span>
              <span className="text-emerald-300">Institutional Dining Platform</span>
            </div>

            {/* Main Bold Headline */}
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-display font-extrabold text-white tracking-tight leading-[1.15] mt-4 drop-shadow-md">
              Smart Mess & AI <br />
              Food Demand <br />
              Optimization
            </h1>

            <p className="text-emerald-100/90 text-sm sm:text-base mt-3 font-medium max-w-lg drop-shadow">
              Automated Dining Operations, <br className="hidden sm:inline" />
              Meal Analytics & Waste Reduction Console
            </p>
          </div>

          {/* 3 Horizontal Glassmorphism Feature Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3.5 pt-4">
            
            {/* Card 1: AI Prediction */}
            <div className="p-4 rounded-2xl bg-emerald-950/60 border border-emerald-500/30 backdrop-blur-xl hover:bg-emerald-950/80 transition-all shadow-xl group">
              <div className="w-10 h-10 rounded-full bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center text-emerald-300 mb-3 group-hover:scale-105 transition-transform">
                <Target className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-white">AI Prediction</h4>
              <p className="text-xs text-emerald-300/90 font-semibold mt-0.5">97.4% Accuracy</p>
            </div>

            {/* Card 2: QR Verification */}
            <div className="p-4 rounded-2xl bg-emerald-950/60 border border-emerald-500/30 backdrop-blur-xl hover:bg-emerald-950/80 transition-all shadow-xl group">
              <div className="w-10 h-10 rounded-full bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center text-emerald-300 mb-3 group-hover:scale-105 transition-transform">
                <QrCode className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-white">QR Verification</h4>
              <p className="text-xs text-emerald-300/90 font-semibold mt-0.5">Live Counter</p>
            </div>

            {/* Card 3: Zero Waste */}
            <div className="p-4 rounded-2xl bg-emerald-950/60 border border-emerald-500/30 backdrop-blur-xl hover:bg-emerald-950/80 transition-all shadow-xl group">
              <div className="w-10 h-10 rounded-full bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center text-emerald-300 mb-3 group-hover:scale-105 transition-transform">
                <ShoppingBag className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-white">Zero Waste</h4>
              <p className="text-xs text-emerald-300/90 font-semibold mt-0.5">1,200+ kg Saved (YoY)</p>
            </div>

          </div>
        </div>

        {/* Right Floating White Login Card (5 Cols) */}
        <div className="lg:col-span-5 bg-white/95 backdrop-blur-2xl rounded-3xl p-7 sm:p-9 shadow-2xl border border-white/50 flex flex-col justify-between">
          <div>
            {/* Header & Logo */}
            <div className="text-center mb-6">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-[#1B8E2D] text-white mb-3 shadow-lg shadow-emerald-900/20">
                <svg className="w-7 h-7" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 2v6a3 3 0 0 1-3 3 3 3 0 0 1-3-3V2" />
                  <path d="M15 11v11" />
                  <path d="M5 2v10a2 2 0 0 0 2 2h0a2 2 0 0 0 2-2V2" />
                  <path d="M7 14v8" />
                </svg>
              </div>
              <h2 className="text-2xl font-display font-extrabold text-gray-900">Sign In to Console</h2>
            </div>

            {/* Login Form */}
            <Outlet />
          </div>

          {/* Footer */}
          <div className="mt-6 pt-4 border-t border-gray-100 flex items-center justify-center gap-1.5 text-xs text-emerald-800 font-semibold">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>Enterprise Secure</span>
          </div>
        </div>

      </div>
    </div>
  );
};
