'use client';

import React from 'react';
import { InvitationTemplate } from '../types/template';
import { Play, Sliders, Image as ImageIcon, Type, Clock, Trash2, Sparkles } from 'lucide-react';

interface TemplateCardProps {
  template: InvitationTemplate;
  onSelect: (template: InvitationTemplate) => void;
  onDelete?: (id: string) => void;
}

export default function TemplateCard({ template, onSelect, onDelete }: TemplateCardProps) {
  const photoCount = template.imageElements ? template.imageElements.length : (template.photoSlotsCount || 0);
  const textCount = template.textElements ? template.textElements.length : 0;

  const formatDuration = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
  };

  return (
    <div className="group relative bg-[#13131C] rounded-2xl border border-[#232332] hover:border-amber-500/40 transition-all duration-300 overflow-hidden shadow-lg hover:shadow-2xl hover:shadow-amber-500/10 flex flex-col">
      {/* Thumbnail / Video header */}
      <div className="relative aspect-video w-full bg-[#0E0E14] overflow-hidden">
        <img
          src={template.thumbnailUrl || '/assets/templates/thumb_01_green.jpg'}
          alt={template.title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
          onError={(e) => {
            (e.target as HTMLImageElement).src = '/assets/candidate_screenshot.jpg';
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#13131C] via-black/20 to-transparent" />

        {/* Badge & Orientation */}
        <div className="absolute top-3 left-3 flex items-center gap-2">
          {template.badgeText && (
            <span className="px-2.5 py-1 rounded-md text-[10px] font-bold tracking-wider uppercase bg-amber-500/90 text-black shadow-md">
              {template.badgeText}
            </span>
          )}
          <span className="px-2 py-0.5 rounded-md text-[10px] font-semibold tracking-wider bg-black/60 backdrop-blur-md text-amber-200 border border-white/10">
            {template.orientation}
          </span>
        </div>

        {/* Duration badge */}
        <div className="absolute bottom-3 right-3 flex items-center gap-1.5 px-2 py-1 rounded-md bg-black/70 backdrop-blur-md text-slate-200 text-[11px] font-mono border border-white/10">
          <Clock className="w-3 h-3 text-amber-400" />
          <span>{formatDuration(template.durationSeconds)}</span>
        </div>

        {/* Hover overlay play button */}
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/40 backdrop-blur-xs">
          <button
            onClick={() => onSelect(template)}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-500 text-black font-semibold text-xs tracking-wide shadow-xl shadow-amber-500/30 transform scale-95 group-hover:scale-100 transition-transform"
          >
            <Sliders className="w-4 h-4" />
            Open Timeline Editor
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 flex-1 flex flex-col justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[11px] font-medium text-amber-400">
              {template.category} • {template.religion || 'Universal'}
            </span>
          </div>

          <h3 className="font-playfair text-base font-bold text-white group-hover:text-amber-300 transition-colors line-clamp-1">
            {template.title}
          </h3>

          <p className="text-xs text-slate-400 mt-1 line-clamp-2 leading-relaxed">
            {template.description}
          </p>
        </div>

        {/* Elements summary badges */}
        <div className="mt-4 pt-3 border-t border-[#20202E] flex items-center justify-between text-xs">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 text-slate-300" title="Configured Photo Placeholders">
              <ImageIcon className="w-3.5 h-3.5 text-purple-400" />
              <span className="font-semibold text-purple-200">{photoCount}</span>
              <span className="text-[11px] text-slate-400">Photos</span>
            </div>

            <div className="flex items-center gap-1.5 text-slate-300" title="Configured Dynamic Text Fields">
              <Type className="w-3.5 h-3.5 text-amber-400" />
              <span className="font-semibold text-amber-200">{textCount}</span>
              <span className="text-[11px] text-slate-400">Texts</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {onDelete && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  if (confirm(`Are you sure you want to delete template "${template.title}"?`)) {
                    onDelete(template.id);
                  }
                }}
                className="p-1.5 rounded-lg text-slate-500 hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                title="Delete Template"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            )}

            <button
              onClick={() => onSelect(template)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1B1B26] hover:bg-amber-500 hover:text-black text-amber-300 font-semibold text-xs border border-amber-500/30 hover:border-transparent transition-all"
            >
              <Sliders className="w-3 h-3" />
              Edit
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

