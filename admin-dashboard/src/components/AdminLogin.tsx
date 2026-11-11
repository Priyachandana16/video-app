'use client';

import React, { useState } from 'react';
import { Lock, User, ArrowRight, ShieldCheck, AlertCircle } from 'lucide-react';

interface AdminLoginProps {
  onLoginSuccess: (username: string) => void;
}

export default function AdminLogin({ onLoginSuccess }: AdminLoginProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    const cleanUser = username.trim().toLowerCase();
    const cleanPass = password.trim();

    // Hardcoded Admin Credentials
    const isValid =
      (cleanUser === 'admin' || cleanUser === 'yash') &&
      (cleanPass === 'admin123' || cleanPass === 'admin' || cleanPass === 'Password123!');

    setTimeout(() => {
      setIsLoading(false);
      if (isValid) {
        const session = {
          user: cleanUser,
          role: 'super_admin',
          loggedInAt: new Date().toISOString(),
        };
        localStorage.setItem('my_invitation_admin_session', JSON.stringify(session));
        onLoginSuccess(cleanUser);
      } else {
        setError('Invalid Admin credentials. Use admin / admin123');
      }
    }, 300);
  };

  return (
    <div className="min-h-screen bg-[#0A0A10] flex items-center justify-center p-4 relative overflow-hidden select-none">
      {/* Background ambient lighting */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-amber-500/10 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute bottom-1/4 left-1/3 w-80 h-80 bg-rose-500/5 rounded-full blur-[120px] pointer-events-none" />

      <div className="w-full max-w-md bg-[#12121C]/90 backdrop-blur-xl border border-[#2A2A3E] rounded-2xl p-8 shadow-2xl relative z-10">
        {/* Header with Logo */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#FFD700] via-[#D4AF37] to-[#800020] p-0.5 shadow-xl shadow-amber-500/20 mb-4">
            <div className="w-full h-full bg-[#14141E] rounded-[14px] flex items-center justify-center p-2">
              <img src="/logo.png" alt="My Invitation Logo" className="w-11 h-11 object-contain drop-shadow" />
            </div>
          </div>
          <h1 className="font-playfair text-2xl font-bold bg-gradient-to-r from-white via-amber-100 to-amber-300 bg-clip-text text-transparent">
            My Invitation Admin
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Studio Sign In • Manage Templates, Timelines & Renders
          </p>
        </div>

        {error && (
          <div className="mb-6 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-center gap-2.5 text-xs text-rose-300">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Admin ID / Username
            </label>
            <div className="relative">
              <User className="w-4 h-4 text-amber-400/80 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter admin ID (e.g. admin)"
                className="w-full pl-10 pr-4 py-2.5 bg-[#181826] border border-[#2D2D42] focus:border-amber-500/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-amber-500/50 transition-all"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-amber-400/80 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter password"
                className="w-full pl-10 pr-4 py-2.5 bg-[#181826] border border-[#2D2D42] focus:border-amber-500/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-amber-500/50 transition-all"
              />
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#B38F22] hover:from-[#E5C158] hover:to-[#C69E2B] text-black font-semibold text-sm shadow-lg shadow-amber-500/20 active:scale-[0.99] transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isLoading ? (
                <div className="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>Sign In to Studio</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </div>
        </form>

        <div className="mt-6 pt-5 border-t border-[#232334] flex items-center justify-between text-[11px] text-slate-400">
          <span className="flex items-center gap-1.5 text-amber-400/90 font-medium">
            <ShieldCheck className="w-3.5 h-3.5 text-amber-400" />
            Default: admin / admin123
          </span>
          <span>v1.0.0</span>
        </div>
      </div>
    </div>
  );
}

