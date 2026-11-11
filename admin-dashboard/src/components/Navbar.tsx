'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { Film, Plus, Server, Layers, Video } from 'lucide-react';

interface NavbarProps {
  onNewTemplateClick?: () => void;
  activeTab?: string;
  onTabChange?: (tab: string) => void;
}

export default function Navbar({ onNewTemplateClick, activeTab = 'templates', onTabChange }: NavbarProps) {
  const [serverOnline, setServerOnline] = useState<boolean | null>(null);

  useEffect(() => {
    fetch('/api/health')
      .then((res) => {
        setServerOnline(res.ok);
      })
      .catch(() => {
        setServerOnline(false);
      });
  }, []);

  return (
    <header className="sticky top-0 z-50 bg-[#101018]/90 backdrop-blur-md border-b border-[#232334] px-6 py-3.5 flex items-center justify-between shadow-xl">
      <div className="flex items-center gap-6">
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#FFD700] via-[#D4AF37] to-[#800020] p-0.5 shadow-lg shadow-amber-500/10 group-hover:shadow-amber-500/25 transition-all flex items-center justify-center">
            <div className="w-full h-full bg-[#14141E] rounded-[10px] flex items-center justify-center p-1">
              <img src="/logo.png" alt="My Invitation Logo" className="w-7 h-7 object-contain drop-shadow" />
            </div>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-playfair text-xl font-bold tracking-wide bg-gradient-to-r from-white via-amber-100 to-amber-300 bg-clip-text text-transparent">
                My Invitation
              </span>
              <span className="text-[10px] font-semibold tracking-wider uppercase px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-400 border border-amber-500/30">
                Admin Studio
              </span>
            </div>
            <p className="text-[11px] text-slate-400 font-medium">
              Dynamic Video Template & Timeline Editor
            </p>
          </div>
        </Link>

        {onTabChange && (
          <nav className="hidden md:flex items-center gap-1 bg-[#161622] p-1 rounded-xl border border-[#262638]">
            <button
              onClick={() => onTabChange('templates')}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'templates'
                  ? 'bg-gradient-to-r from-amber-500/20 to-amber-600/20 text-[#FFE082] border border-amber-500/40 shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              Templates Catalog
            </button>
            <button
              onClick={() => onTabChange('assets')}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'assets'
                  ? 'bg-gradient-to-r from-amber-500/20 to-amber-600/20 text-[#FFE082] border border-amber-500/40 shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
            >
              <Video className="w-3.5 h-3.5" />
              Media Storage Assets
            </button>
          </nav>
        )}
      </div>

      <div className="flex items-center gap-4">
        {/* Backend status indicator */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#14141E] border border-[#232332] text-xs">
          <Server className="w-3.5 h-3.5 text-slate-400" />
          <span className="text-slate-400">Rendering Engine:</span>
          {serverOnline === null ? (
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
          ) : serverOnline ? (
            <span className="flex items-center gap-1.5 text-emerald-400 font-medium">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              Online (5000)
            </span>
          ) : (
            <span className="flex items-center gap-1.5 text-rose-400 font-medium">
              <span className="w-2 h-2 rounded-full bg-rose-500" />
              Offline
            </span>
          )}
        </div>

        {onNewTemplateClick && (
          <button
            onClick={onNewTemplateClick}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#B38F22] hover:from-[#E5C158] hover:to-[#C69E2B] text-black font-semibold text-xs tracking-wide shadow-lg shadow-amber-500/20 active:scale-95 transition-all"
          >
            <Plus className="w-4 h-4" />
            Create Template
          </button>
        )}
      </div>
    </header>
  );
}

