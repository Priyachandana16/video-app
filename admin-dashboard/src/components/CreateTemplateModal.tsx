'use client';

import React, { useState, useEffect } from 'react';
import { InvitationTemplate, MediaAsset } from '../types/template';
import { X, Film, Check, Video, AlertCircle } from 'lucide-react';

interface CreateTemplateModalProps {
  isOpen: boolean;
  categories?: string[];
  onClose: () => void;
  onCreated: (newTemplate: InvitationTemplate) => void;
}

export default function CreateTemplateModal({ isOpen, categories, onClose, onCreated }: CreateTemplateModalProps) {
  const [title, setTitle] = useState('');
  const availableCategories = categories && categories.length > 0 ? categories : ['Wedding', 'Reception', 'Half Saree', 'Engagement', 'First Birthday', 'Birthday', 'Anniversary', 'Festivals', 'House Warming'];
  const [category, setCategory] = useState(availableCategories[0]);
  const [customCategoryInput, setCustomCategoryInput] = useState('');
  const [isCustomCategory, setIsCustomCategory] = useState(false);
  const [religion, setReligion] = useState('Hindu');
  const [orientation, setOrientation] = useState<'16:9' | '9:16'>('16:9');
  const [selectedVideo, setSelectedVideo] = useState('');
  const [duration, setDuration] = useState(60);
  const [description, setDescription] = useState('');
  const [badgeText, setBadgeText] = useState('CUSTOM ROYAL');
  const [mediaAssets, setMediaAssets] = useState<MediaAsset[]>([]);
  const [isLoadingAssets, setIsLoadingAssets] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
      setIsLoadingAssets(true);
      fetch('/api/admin/media-assets')
        .then((res) => res.json())
        .then((data) => {
          const videos = (data.assets || []).filter((a: MediaAsset) => a.type === 'video');
          setMediaAssets(videos);
          if (videos.length > 0 && !selectedVideo) {
            setSelectedVideo(videos[0].filePath);
          }
        })
        .catch((err) => {
          console.error('Failed to load media assets:', err);
        })
        .finally(() => {
          setIsLoadingAssets(false);
        });
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Template title is required');
      return;
    }
    if (!selectedVideo) {
      setError('Please select a master background video');
      return;
    }

    setIsSubmitting(true);
    setError('');

    const canvasWidth = orientation === '9:16' ? 1080 : 1920;
    const canvasHeight = orientation === '9:16' ? 1920 : 1080;
    const videoUrl = selectedVideo.startsWith('/') ? selectedVideo : `/${selectedVideo}`;

    const newTemplatePayload: Partial<InvitationTemplate> = {
      id: `tmpl_${Date.now()}`,
      title,
      category,
      religion,
      orientation,
      canvasWidth,
      canvasHeight,
      hasPhoto: true,
      photoSlotsCount: 3,
      durationSeconds: Number(duration) || 60,
      badgeText,
      description: description || `Royal ${category} video template with dynamic multi-photo overlays.`,
      masterVideoPath: selectedVideo,
      videoUrl,
      thumbnailUrl: '/assets/templates/thumb_01_green.jpg',
      textElements: [
        {
          id: `txt_${Date.now()}_1`,
          field: 'ceremonyTitle',
          label: 'Ceremony Title',
          defaultText: 'శుభ వివాహం / Subha Vivaham',
          x: canvasWidth / 2,
          y: orientation === '9:16' ? 180 : 80,
          fontSize: 44,
          fontFamily: 'Cinzel',
          fontColor: '#FFD700',
          textAlign: 'center',
          startTime: 2.0,
          endTime: Math.min(duration, 25.0),
          fadeIn: 0.8,
          fadeOut: 0.8
        },
        {
          id: `txt_${Date.now()}_2`,
          field: 'coupleNames',
          label: 'Couple Names',
          defaultText: 'Sai Krishna & Deepika',
          x: canvasWidth / 2,
          y: orientation === '9:16' ? 1400 : 840,
          fontSize: 52,
          fontFamily: 'Playfair Display',
          fontColor: '#FFF8E7',
          textAlign: 'center',
          startTime: 10.0,
          endTime: Math.min(duration, 40.0),
          fadeIn: 0.8,
          fadeOut: 0.8
        }
      ],
      imageElements: [
        {
          id: `img_${Date.now()}_1`,
          field: 'photo_1',
          label: 'Photo 1: Bride Portrait',
          x: orientation === '9:16' ? 240 : 680,
          y: orientation === '9:16' ? 420 : 100,
          width: orientation === '9:16' ? 600 : 560,
          height: orientation === '9:16' ? 780 : 700,
          fit: 'cover',
          startTime: 5.0,
          endTime: Math.min(duration, 15.0),
          animationType: 'ink_reveal',
          animationDuration: 1.2,
          placeholderUrl: '/assets/candidate_screenshot.jpg'
        },
        {
          id: `img_${Date.now()}_2`,
          field: 'photo_2',
          label: 'Photo 2: Groom Portrait',
          x: orientation === '9:16' ? 240 : 680,
          y: orientation === '9:16' ? 420 : 100,
          width: orientation === '9:16' ? 600 : 560,
          height: orientation === '9:16' ? 780 : 700,
          fit: 'cover',
          startTime: 16.0,
          endTime: Math.min(duration, 26.0),
          animationType: 'brush_stroke',
          animationDuration: 1.2,
          placeholderUrl: '/assets/candidate_logo1.png'
        }
      ]
    };

    try {
      const res = await fetch('/api/templates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newTemplatePayload)
      });
      const data = await res.json();
      if (res.ok && data.template) {
        onCreated(data.template);
        onClose();
      } else {
        setError(data.error || 'Failed to create template');
      }
    } catch (err: any) {
      setError(err.message || 'Network error');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn">
      <div className="relative w-full max-w-2xl bg-[#13131D] rounded-2xl border border-[#2B2B3E] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-[#242436] flex items-center justify-between bg-[#161622]">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-amber-500/15 border border-amber-500/30">
              <Film className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <h2 className="font-playfair text-lg font-bold text-white">Create New Video Template</h2>
              <p className="text-xs text-slate-400">Configure background video and initial timeline properties</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-6 overflow-y-auto space-y-4">
          {error && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Template Title *
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Royal Telugu Vivaham 5-Photo Edition"
              className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-sm outline-none transition-all placeholder:text-slate-600"
              required
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Category</label>
              {isCustomCategory ? (
                <div className="flex items-center gap-1.5">
                  <input
                    type="text"
                    value={customCategoryInput}
                    onChange={(e) => {
                      setCustomCategoryInput(e.target.value);
                      setCategory(e.target.value);
                    }}
                    placeholder="Enter custom category..."
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-amber-500/40 text-white text-sm outline-none"
                    autoFocus
                  />
                  <button
                    type="button"
                    onClick={() => {
                      setIsCustomCategory(false);
                      setCategory(availableCategories[0]);
                    }}
                    className="px-2.5 py-2.5 rounded-xl bg-[#222234] text-xs text-slate-400 hover:text-white"
                  >
                    List
                  </button>
                </div>
              ) : (
                <select
                  value={category}
                  onChange={(e) => {
                    if (e.target.value === '__NEW__') {
                      setIsCustomCategory(true);
                      setCustomCategoryInput('');
                    } else {
                      setCategory(e.target.value);
                    }
                  }}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-sm outline-none"
                >
                  {availableCategories.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                  <option value="__NEW__">+ Custom Category...</option>
                </select>
              )}
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Orientation / Aspect Ratio</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setOrientation('16:9')}
                  className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all ${
                    orientation === '16:9'
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400'
                  }`}
                >
                  16:9 Landscape
                </button>
                <button
                  type="button"
                  onClick={() => setOrientation('9:16')}
                  className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all ${
                    orientation === '9:16'
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400'
                  }`}
                >
                  9:16 Portrait
                </button>
              </div>
            </div>
          </div>

          {/* Master Video Asset Selection */}
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Select Master Background Video *
            </label>
            {isLoadingAssets ? (
              <div className="py-8 text-center text-xs text-slate-400">Loading available videos...</div>
            ) : mediaAssets.length === 0 ? (
              <div className="p-4 rounded-xl bg-[#1A1A26] border border-amber-500/20 text-xs text-amber-300">
                No videos found in storage. Default template video will be used.
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-48 overflow-y-auto pr-1">
                {mediaAssets.map((asset) => (
                  <div
                    key={asset.filePath}
                    onClick={() => setSelectedVideo(asset.filePath)}
                    className={`flex items-center gap-2.5 p-2.5 rounded-xl border cursor-pointer transition-all ${
                      selectedVideo === asset.filePath
                        ? 'bg-amber-500/15 border-amber-500 text-amber-200'
                        : 'bg-[#181824] border-[#28283C] hover:border-slate-500 text-slate-300'
                    }`}
                  >
                    <Video className="w-4 h-4 text-amber-400 shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium truncate">{asset.name}</p>
                      <p className="text-[10px] text-slate-500">{(asset.sizeBytes / (1024 * 1024)).toFixed(1)} MB</p>
                    </div>
                    {selectedVideo === asset.filePath && (
                      <Check className="w-4 h-4 text-amber-400 shrink-0" />
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Duration (Seconds)</label>
              <input
                type="number"
                value={duration}
                onChange={(e) => setDuration(Number(e.target.value))}
                min="5"
                max="300"
                className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-sm outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Badge Text</label>
              <input
                type="text"
                value={badgeText}
                onChange={(e) => setBadgeText(e.target.value)}
                placeholder="e.g. 5-PHOTO SPECIAL"
                className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-sm outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              placeholder="Brief description of this invitation style..."
              className="w-full px-3.5 py-2 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-xs outline-none resize-none placeholder:text-slate-600"
            />
          </div>

          {/* Footer actions */}
          <div className="pt-3 border-t border-[#242436] flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-black font-bold text-xs tracking-wide shadow-lg shadow-amber-500/20 active:scale-95 transition-all disabled:opacity-50"
            >
              {isSubmitting ? 'Creating...' : 'Create & Open Editor'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

