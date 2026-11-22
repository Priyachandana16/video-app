'use client';

import React, { useState, useEffect, useRef } from 'react';
import { InvitationTemplate, MediaAsset, ImageElementConfig, TextElementConfig } from '../types/template';
import { X, Film, Check, Video, AlertCircle, UploadCloud, Loader2, Sparkles, Image as ImageIcon, FileText } from 'lucide-react';

interface CreateTemplateModalProps {
  isOpen: boolean;
  categories?: string[];
  onClose: () => void;
  onCreated: (newTemplate: InvitationTemplate) => void;
}

export default function CreateTemplateModal({ isOpen, categories, onClose, onCreated }: CreateTemplateModalProps) {
  const [title, setTitle] = useState('');
  const availableCategories = categories && categories.length > 0 ? categories : [
    'Wedding',
    'Half Saree',
    'Birthday',
    'Reception',
    'Engagement',
    'House Warming',
    'Dhoti Ceremony',
    'Annaprashana',
    'Festivals',
    'Anniversary',
  ];
  const [category, setCategory] = useState(availableCategories[0]);
  const [customCategoryInput, setCustomCategoryInput] = useState('');
  const [isCustomCategory, setIsCustomCategory] = useState(false);

  // Sub-categorization
  const [religion, setReligion] = useState('Hindu');
  const [orientation, setOrientation] = useState<'16:9' | '9:16'>('16:9');
  const [hasPhoto, setHasPhoto] = useState(true);
  const [photoSlotsCount, setPhotoSlotsCount] = useState(3);
  const [duration, setDuration] = useState(60);
  const [badgeText, setBadgeText] = useState('CUSTOM ROYAL');
  const [description, setDescription] = useState('');

  // Video Selection & Direct Upload
  const [selectedVideo, setSelectedVideo] = useState('');
  const [uploadedVideoName, setUploadedVideoName] = useState('');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!isOpen) return null;

  // Handle direct file upload to Supabase Storage
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('video/')) {
      setError('Please upload a valid MP4/MOV/WebM video file');
      return;
    }

    setIsUploading(true);
    setUploadProgress(20);
    setError('');

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('bucket', 'template-assets');

      setUploadProgress(50);
      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.error || 'Failed to upload video to Supabase Storage');
      }

      setUploadProgress(100);
      setSelectedVideo(data.publicUrl);
      setUploadedVideoName(file.name);
      // Auto-detect duration or set default
    } catch (err: any) {
      console.error('Upload error:', err);
      setError(err.message || 'Failed to upload video to Supabase Storage');
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Template title is required');
      return;
    }
    if (!selectedVideo) {
      setError('Please upload or select a master background video');
      return;
    }

    setIsSubmitting(true);
    setError('');

    const canvasWidth = orientation === '9:16' ? 1080 : 1920;
    const canvasHeight = orientation === '9:16' ? 1920 : 1080;
    const videoUrl = selectedVideo;

    // Generate Photo Slots dynamically based on admin photo choice
    const generatedImageElements: ImageElementConfig[] = [];
    if (hasPhoto && photoSlotsCount > 0) {
      const slotDuration = Math.max(6, Math.min(15, Math.floor(duration / Math.max(photoSlotsCount, 1))));
      for (let i = 1; i <= photoSlotsCount; i++) {
        const start = (i - 1) * (slotDuration + 1) + 2;
        const end = Math.min(duration, start + slotDuration);
        generatedImageElements.push({
          id: `img_${Date.now()}_${i}`,
          field: `photo_${i}`,
          label: i === 1 ? 'Bride / Main Portrait' : i === 2 ? 'Groom / Second Portrait' : `Photo Slot ${i}`,
          x: orientation === '9:16' ? 240 : 680,
          y: orientation === '9:16' ? 420 : 120,
          width: orientation === '9:16' ? 600 : 560,
          height: orientation === '9:16' ? 780 : 700,
          fit: 'cover',
          shape: 'rectangle',
          startTime: start,
          endTime: end,
          animationType: i % 2 === 1 ? 'ink_reveal' : 'brush_stroke',
          animationDuration: 1.2,
          placeholderUrl: '/assets/candidate_screenshot.jpg',
        });
      }
    }

    // Generate initial text elements tailored to category
    const initialTextElements: TextElementConfig[] = [
      {
        id: `txt_${Date.now()}_1`,
        field: 'ceremonyTitle',
        label: category.toLowerCase().includes('birthday') ? 'Birthday Celebration' : 'Ceremony Title',
        defaultText: category.toLowerCase().includes('birthday')
          ? 'Happy Birthday Celebration'
          : category.toLowerCase().includes('saree')
          ? 'హాఫ్ శారీ ఫంక్షన్ / Half Saree Ceremony'
          : 'శుభ వివాహం / Subha Vivaham',
        x: canvasWidth / 2,
        y: orientation === '9:16' ? 180 : 80,
        fontSize: 44,
        fontFamily: 'Ponnala',
        fontColor: '#FFD700',
        fontWeight: 'bold',
        strokeEnabled: false,
        strokeWidth: 2,
        strokeColor: '#000000',
        animationType: 'fade',
        textAlign: 'center',
        startTime: 2.0,
        endTime: Math.min(duration, 25.0),
        fadeIn: 0.8,
        fadeOut: 0.8,
      },
      {
        id: `txt_${Date.now()}_2`,
        field: 'groomName',
        label: category.toLowerCase().includes('birthday') ? 'Celebrant Name' : 'Groom Name',
        defaultText: category.toLowerCase().includes('birthday') ? 'Chi. Sai Krishna' : 'Sai Krishna',
        x: canvasWidth / 2,
        y: orientation === '9:16' ? 1380 : 820,
        fontSize: 50,
        fontFamily: 'NTR',
        fontColor: '#FFF8E7',
        fontWeight: 'bold',
        strokeEnabled: false,
        strokeWidth: 2,
        strokeColor: '#000000',
        animationType: 'slide',
        textAlign: 'center',
        startTime: 8.0,
        endTime: Math.min(duration, 38.0),
        fadeIn: 0.8,
        fadeOut: 0.8,
      },
      {
        id: `txt_${Date.now()}_3`,
        field: 'brideName',
        label: category.toLowerCase().includes('birthday') ? 'Parents Blessing' : 'Bride Name',
        defaultText: category.toLowerCase().includes('birthday') ? 'With love from Parents & Family' : 'Deepika',
        x: canvasWidth / 2,
        y: orientation === '9:16' ? 1480 : 890,
        fontSize: 48,
        fontFamily: 'Potti Sreeramulu',
        fontColor: '#FFE082',
        fontWeight: 'normal',
        strokeEnabled: false,
        strokeWidth: 2,
        strokeColor: '#000000',
        animationType: 'fade',
        textAlign: 'center',
        startTime: 12.0,
        endTime: Math.min(duration, 42.0),
        fadeIn: 0.8,
        fadeOut: 0.8,
      },
    ];

    const occasion_id = category.toLowerCase().includes('saree')
      ? 'half_saree'
      : category.toLowerCase().includes('birth')
      ? 'birthday'
      : category.toLowerCase().includes('house') || category.toLowerCase().includes('gruha')
      ? 'housewarming'
      : category.toLowerCase().includes('engage')
      ? 'engagement'
      : 'wedding';

    const newTemplatePayload: Partial<InvitationTemplate> & { occasion_id?: string } = {
      id: `tmpl_${(category || 'custom').toLowerCase().replace(/[^a-z0-9]/g, '_')}_${Date.now()}`,
      title,
      category,
      occasion_id,
      religion,
      orientation,
      canvasWidth,
      canvasHeight,
      hasPhoto,
      photoSlotsCount: hasPhoto ? photoSlotsCount : 0,
      durationSeconds: Number(duration) || 60,
      badgeText: badgeText || (hasPhoto ? `${photoSlotsCount}-PHOTO ROYAL` : 'TEXT ONLY ROYAL'),
      description: description || `Royal ${category} (${religion}) video template with ${hasPhoto ? `${photoSlotsCount} photo slots` : 'text-only layout'}.`,
      masterVideoPath: selectedVideo,
      videoUrl,
      thumbnailUrl: '/assets/templates/thumb_01_green.jpg',
      textElements: initialTextElements,
      imageElements: generatedImageElements,
      masterVideoChromaKey: false,
      masterVideoChromaKeyColor: '#00FF00',
      masterVideoChromaKeySimilarity: 0.25,
      masterVideoChromaKeyBlend: 0.05,
    };

    try {
      const res = await fetch('/api/templates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newTemplatePayload),
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
      <div className="relative w-full max-w-2xl bg-[#13131D] rounded-2xl border border-[#2B2B3E] shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-[#242436] flex items-center justify-between bg-[#161622]">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-amber-500/15 border border-amber-500/30">
              <Film className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <h2 className="font-playfair text-lg font-bold text-white">Create New Video Template</h2>
              <p className="text-xs text-slate-400">Configure category, religion, photos, and upload background video to Supabase</p>
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

          {/* Sub-categorization Row 1: Category & Orientation */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Category *</label>
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
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300 shadow-md shadow-amber-500/10'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400 hover:text-white'
                  }`}
                >
                  16:9 Horizontal
                </button>
                <button
                  type="button"
                  onClick={() => setOrientation('9:16')}
                  className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all ${
                    orientation === '9:16'
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300 shadow-md shadow-amber-500/10'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400 hover:text-white'
                  }`}
                >
                  9:16 Vertical
                </button>
              </div>
            </div>
          </div>

          {/* Sub-categorization Row 2: Religion & Photo Mode */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Religion / Theme Sub-Category</label>
              <select
                value={religion}
                onChange={(e) => setReligion(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-[#1A1A26] border border-[#2C2C40] focus:border-amber-500 text-white text-sm outline-none"
              >
                <option value="Hindu">Hindu (హైందవ సంప్రదాయం)</option>
                <option value="Muslim">Muslim (Nikah / నికాహ్)</option>
                <option value="Christian">Christian (Holy Matrimony)</option>
                <option value="Secular">Secular / Traditional (సర్వజన)</option>
                <option value="Modern">Modern Minimalist</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Photo Requirements</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setHasPhoto(true)}
                  className={`flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl text-xs font-semibold border transition-all ${
                    hasPhoto
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400'
                  }`}
                >
                  <ImageIcon className="w-3.5 h-3.5" />
                  With Photos
                </button>
                <button
                  type="button"
                  onClick={() => setHasPhoto(false)}
                  className={`flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl text-xs font-semibold border transition-all ${
                    !hasPhoto
                      ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                      : 'bg-[#1A1A26] border-[#2C2C40] text-slate-400'
                  }`}
                >
                  <FileText className="w-3.5 h-3.5" />
                  Without Photo (Text Only)
                </button>
              </div>
            </div>
          </div>

          {/* Photo Slots Counter if With Photos is selected */}
          {hasPhoto && (
            <div className="p-3.5 rounded-xl bg-[#181824] border border-[#2A2A3E]">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-slate-300">Number of Photo Slots</span>
                <span className="text-xs font-bold text-amber-400">{photoSlotsCount} Slots</span>
              </div>
              <div className="flex items-center gap-2">
                {[1, 2, 3, 4, 5, 6].map((num) => (
                  <button
                    key={num}
                    type="button"
                    onClick={() => setPhotoSlotsCount(num)}
                    className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-all border ${
                      photoSlotsCount === num
                        ? 'bg-amber-500 text-black border-amber-400 shadow-md shadow-amber-500/20'
                        : 'bg-[#1E1E2C] text-slate-400 border-[#2D2D40] hover:text-white'
                    }`}
                  >
                    {num}
                  </button>
                ))}
              </div>
              <p className="text-[11px] text-slate-500 mt-2">
                Auto-configures {photoSlotsCount} independent portrait layer{photoSlotsCount > 1 ? 's' : ''} on the timeline.
              </p>
            </div>
          )}

          {/* Master Video Source Selection & Upload to Supabase */}
          <div className="space-y-2 pt-1">
            <div className="flex items-center justify-between">
              <label className="text-xs font-semibold text-slate-300">
                Master Background Video * (Stored in Supabase)
              </label>
              <span className="text-[11px] font-medium text-amber-400">Direct Supabase Upload</span>
            </div>

            <div>
              <input
                ref={fileInputRef}
                type="file"
                accept="video/mp4,video/quicktime,video/webm"
                onChange={handleFileUpload}
                className="hidden"
              />
              <div
                onClick={() => !isUploading && fileInputRef.current?.click()}
                className={`flex flex-col items-center justify-center p-5 rounded-xl border-2 border-dashed cursor-pointer transition-all ${
                  selectedVideo && uploadedVideoName
                    ? 'border-amber-500/50 bg-amber-500/10'
                    : 'border-[#2D2D42] hover:border-amber-500/40 bg-[#171724]'
                }`}
              >
                {isUploading ? (
                  <div className="flex flex-col items-center gap-2 py-2">
                    <Loader2 className="w-6 h-6 text-amber-400 animate-spin" />
                    <p className="text-xs font-medium text-amber-300">Uploading to Supabase Storage... {uploadProgress}%</p>
                    <div className="w-48 h-1.5 bg-[#252538] rounded-full overflow-hidden mt-1">
                      <div
                        className="h-full bg-gradient-to-r from-amber-500 to-amber-300 transition-all duration-300"
                        style={{ width: `${uploadProgress}%` }}
                      />
                    </div>
                  </div>
                ) : selectedVideo && uploadedVideoName ? (
                  <div className="flex flex-col items-center gap-1.5 text-center">
                    <div className="p-2 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                      <Check className="w-5 h-5" />
                    </div>
                    <p className="text-xs font-bold text-white truncate max-w-sm">{uploadedVideoName}</p>
                    <p className="text-[11px] text-emerald-400 font-mono">Stored securely in Supabase Storage</p>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        fileInputRef.current?.click();
                      }}
                      className="mt-1 px-3 py-1 rounded bg-[#252538] text-[11px] text-slate-300 hover:text-white"
                    >
                      Change Video File
                    </button>
                  </div>
                ) : (
                  <div className="flex flex-col items-center gap-2 text-center py-2">
                    <div className="p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400">
                      <UploadCloud className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-slate-200">Click to upload Master Video</p>
                      <p className="text-[11px] text-slate-500 mt-0.5">MP4, MOV, or WebM (Stores directly in Supabase Storage)</p>
                    </div>
                  </div>
                )}
              </div>
            </div>
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
              disabled={isSubmitting || isUploading}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-black font-bold text-xs tracking-wide shadow-lg shadow-amber-500/20 active:scale-95 transition-all disabled:opacity-50"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  Creating...
                </>
              ) : (
                <>
                  <Sparkles className="w-3.5 h-3.5" />
                  Create & Open Editor
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
