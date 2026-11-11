'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  InvitationTemplate,
  TextElementConfig,
  ImageElementConfig,
  TextAlign,
  ImageFit,
} from '../types/template';
import {
  Play,
  Pause,
  RotateCcw,
  SkipBack,
  SkipForward,
  Plus,
  Trash2,
  Save,
  Film,
  Type,
  Image as ImageIcon,
  Sparkles,
  ArrowLeft,
  Eye,
  Sliders,
  AlignLeft,
  AlignCenter,
  AlignRight,
  Maximize2,
  CheckCircle2,
  Clock,
  Layers,
  Volume2,
  VolumeX,
  FileVideo,
  Crosshair,
  Move,
  ChevronRight,
  Filter,
} from 'lucide-react';

interface VisualTimelineEditorProps {
  template: InvitationTemplate;
  onBack: () => void;
  onSave: (updatedTemplate: InvitationTemplate) => void;
}

export default function VisualTimelineEditor({
  template: initialTemplate,
  onBack,
  onSave,
}: VisualTimelineEditorProps) {
  const [template, setTemplate] = useState<InvitationTemplate>(() => ({
    ...initialTemplate,
    textElements: initialTemplate?.textElements || [],
    imageElements: initialTemplate?.imageElements || [],
  }));
  const [currentTime, setCurrentTime] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isMuted, setIsMuted] = useState(true);
  const [selectedElementId, setSelectedElementId] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<'text' | 'image' | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveToast, setSaveToast] = useState<string | null>(null);

  // Inactive Elements toggle (defaults to false so only elements active at current second are shown)
  const [showInactiveElements, setShowInactiveElements] = useState(false);

  // Inspector tab: 'inspector' or 'layers'
  const [inspectorTab, setInspectorTab] = useState<'inspector' | 'layers'>('inspector');

  // Timeline track filter: 'all' | 'text' | 'image'
  const [trackFilter, setTrackFilter] = useState<'all' | 'text' | 'image'>('all');

  // Fetch full template configuration if missing elements
  useEffect(() => {
    let isMounted = true;
    if (initialTemplate?.id) {
      fetch(`/api/templates/${initialTemplate.id}`)
        .then((res) => (res.ok ? res.json() : null))
        .then((fullData) => {
          if (isMounted && fullData && fullData.id) {
            setTemplate((prev) => ({
              ...prev,
              ...fullData,
              textElements: (fullData.textElements && fullData.textElements.length > 0) ? fullData.textElements : (prev.textElements || []),
              imageElements: (fullData.imageElements && fullData.imageElements.length > 0) ? fullData.imageElements : (prev.imageElements || []),
            }));
          }
        })
        .catch((err) => console.warn('Could not fetch full template details in editor:', err));
    }
    return () => {
      isMounted = false;
    };
  }, [initialTemplate.id]);

  // Timeline Track Dragging & Trimming State (mode: 'start' trims startTime, 'end' trims endTime, 'move' shifts block)
  const [timelineDrag, setTimelineDrag] = useState<{
    id: string;
    type: 'text' | 'image';
    mode: 'start' | 'end' | 'move';
    startX: number;
    initialStart: number;
    initialEnd: number;
  } | null>(null);

  // Test data injection for live preview
  const [previewUserData, setPreviewUserData] = useState({
    groomName: 'Sai Krishna',
    brideName: 'Deepika',
    ceremonyTitle: 'శుభ వివాహం / Subha Vivaham',
    eventDate: 'Sunday, 15 December 2026',
    muhurthamTime: 'Sumuhurtham: 10:24 AM',
    venue: 'Sri Venkateswara Kalyana Mandapam, Hyderabad',
    rsvp: 'With Best Compliments from Family & Friends',
    parentsNames: 'Smt. Sarojini & Sri. Rama Rao',
  });
  const [showTestDataPanel, setShowTestDataPanel] = useState(false);

  // Full Video Render Preview Modal State
  const [isRenderingPreview, setIsRenderingPreview] = useState(false);
  const [renderProgress, setRenderProgress] = useState(0);
  const [renderStep, setRenderStep] = useState('');
  const [renderedVideoUrl, setRenderedVideoUrl] = useState<string | null>(null);
  const [showRenderModal, setShowRenderModal] = useState(false);

  // Video and Canvas Refs
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const timelineRef = useRef<HTMLDivElement | null>(null);

  // Dragging and resizing state
  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState(false);
  const [resizeHandle, setResizeHandle] = useState<string | null>(null);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [elementStartPos, setElementStartPos] = useState({ x: 0, y: 0, width: 0, height: 0 });

  const canvasWidth = template.canvasWidth || 1920;
  const canvasHeight = template.canvasHeight || 1080;
  const duration = template.durationSeconds || 60;

  // Selected element lookup
  const selectedTextElement = (template.textElements || []).find((t) => t.id === selectedElementId);
  const selectedImageElement = (template.imageElements || []).find((i) => i.id === selectedElementId);

  // Video playback sync with high-precision 60 FPS requestAnimationFrame loop
  const togglePlay = () => {
    if (!videoRef.current) return;
    if (isPlaying) {
      videoRef.current.pause();
      setIsPlaying(false);
    } else {
      videoRef.current.play();
      setIsPlaying(true);
    }
  };

  useEffect(() => {
    let animId: number;
    const syncFrame = () => {
      if (videoRef.current && !videoRef.current.paused) {
        setCurrentTime(videoRef.current.currentTime);
        animId = requestAnimationFrame(syncFrame);
      }
    };
    if (isPlaying) {
      animId = requestAnimationFrame(syncFrame);
    }
    return () => {
      if (animId) cancelAnimationFrame(animId);
    };
  }, [isPlaying]);

  const handleTimeUpdate = () => {
    if (videoRef.current && !isPlaying) {
      setCurrentTime(videoRef.current.currentTime);
    }
  };

  const seekTo = (timeInSec: number) => {
    const clamped = Math.max(0, Math.min(timeInSec, duration));
    setCurrentTime(clamped);
    if (videoRef.current) {
      videoRef.current.currentTime = clamped;
    }
  };

  const stepFrame = (forward: boolean) => {
    const step = 1 / 30; // 30 fps
    seekTo(currentTime + (forward ? step : -step));
  };

  // Timeline track dragging & handle trimming start
  const handleTimelineDragStart = (
    e: React.MouseEvent,
    id: string,
    type: 'text' | 'image',
    mode: 'start' | 'end' | 'move',
    startTime: number,
    endTime: number
  ) => {
    e.stopPropagation();
    e.preventDefault();
    setSelectedElementId(id);
    setSelectedType(type);
    setInspectorTab('inspector');
    // Automatically seek playhead to element start time if outside its active window
    if (currentTime < startTime || currentTime > endTime) {
      seekTo(startTime);
    }
    setTimelineDrag({
      id,
      type,
      mode,
      startX: e.clientX,
      initialStart: startTime,
      initialEnd: endTime,
    });
  };

  // Convert canvas coordinates to preview overlay scale
  const getScale = useCallback(() => {
    if (!containerRef.current) return 1;
    const rect = containerRef.current.getBoundingClientRect();
    return rect.width / canvasWidth;
  }, [canvasWidth]);

  // Add new elements
  const addTextElement = () => {
    const currentTexts = template.textElements || [];
    const newId = `txt_${Date.now()}`;
    const newEl: TextElementConfig = {
      id: newId,
      field: 'coupleNames',
      label: `Text ${currentTexts.length + 1}`,
      defaultText: 'Sai Krishna & Deepika',
      x: Math.round(canvasWidth / 2),
      y: Math.round(canvasHeight / 2),
      fontSize: 48,
      fontFamily: 'Playfair Display',
      fontColor: '#FFE082',
      textAlign: 'center',
      startTime: Math.floor(currentTime),
      endTime: Math.min(duration, Math.floor(currentTime) + 10),
      fadeIn: 0.6,
      fadeOut: 0.6,
    };
    setTemplate((prev) => ({
      ...prev,
      textElements: [...(prev.textElements || []), newEl],
    }));
    setSelectedElementId(newId);
    setSelectedType('text');
    setInspectorTab('inspector');
  };

  const addImageElement = () => {
    const currentImages = template.imageElements || [];
    const nextSlotNum = currentImages.length + 1;
    const newId = `img_${Date.now()}`;
    const newEl: ImageElementConfig = {
      id: newId,
      field: `photo_${nextSlotNum}`,
      label: `Photo ${nextSlotNum}: Portrait ${nextSlotNum}`,
      x: template.orientation === '9:16' ? 240 : 680,
      y: template.orientation === '9:16' ? 420 : 120,
      width: template.orientation === '9:16' ? 600 : 560,
      height: template.orientation === '9:16' ? 780 : 700,
      fit: 'cover',
      startTime: Math.floor(currentTime),
      endTime: Math.min(duration, Math.floor(currentTime) + 8),
      animationType: nextSlotNum % 2 === 1 ? 'ink_reveal' : 'brush_stroke',
      animationDuration: 1.2,
      placeholderUrl: `/assets/candidate_logo${(nextSlotNum % 4) + 1}.png`,
    };
    setTemplate((prev) => {
      const updatedImages = [...(prev.imageElements || []), newEl];
      return {
        ...prev,
        imageElements: updatedImages,
        photoSlotsCount: updatedImages.length,
        hasPhoto: true,
      };
    });
    setSelectedElementId(newId);
    setSelectedType('image');
    setInspectorTab('inspector');
  };

  const deleteElement = (id: string, type: 'text' | 'image') => {
    if (type === 'text') {
      setTemplate((prev) => ({
        ...prev,
        textElements: (prev.textElements || []).filter((t) => t.id !== id),
      }));
    } else {
      setTemplate((prev) => {
        const remainingImages = (prev.imageElements || []).filter((i) => i.id !== id);
        return {
          ...prev,
          imageElements: remainingImages,
          photoSlotsCount: remainingImages.length,
          hasPhoto: remainingImages.length > 0,
        };
      });
    }
    if (selectedElementId === id) {
      setSelectedElementId(null);
      setSelectedType(null);
    }
  };

  const updateTextElement = (id: string, updates: Partial<TextElementConfig>) => {
    setTemplate((prev) => ({
      ...prev,
      textElements: (prev.textElements || []).map((t) => (t.id === id ? { ...t, ...updates } : t)),
    }));
  };

  const updateImageElement = (id: string, updates: Partial<ImageElementConfig>) => {
    setTemplate((prev) => ({
      ...prev,
      imageElements: (prev.imageElements || []).map((i) => (i.id === id ? { ...i, ...updates } : i)),
    }));
  };

  // Dragging and canvas interaction
  const handleMouseDown = (
    e: React.MouseEvent,
    id: string,
    type: 'text' | 'image',
    handle: string | null = null
  ) => {
    e.stopPropagation();
    e.preventDefault(); // Prevents native text selection when dragging
    setSelectedElementId(id);
    setSelectedType(type);
    setInspectorTab('inspector');

    const el =
      type === 'text'
        ? (template.textElements || []).find((t) => t.id === id)
        : (template.imageElements || []).find((i) => i.id === id);

    if (!el) return;

    if (handle) {
      setIsResizing(true);
      setResizeHandle(handle);
    } else {
      setIsDragging(true);
    }

    setDragStart({ x: e.clientX, y: e.clientY });
    setElementStartPos({
      x: el.x,
      y: el.y,
      width: 'width' in el ? el.width : 300,
      height: 'height' in el ? el.height : 100,
    });
  };

  const handleMouseMove = useCallback(
    (e: MouseEvent) => {
      // Timeline dragging and trimming
      if (timelineDrag && timelineRef.current) {
        const rect = timelineRef.current.getBoundingClientRect();
        const deltaPx = e.clientX - timelineDrag.startX;
        const deltaSec = (deltaPx / rect.width) * duration;

        if (timelineDrag.mode === 'start') {
          const rawNewStart = timelineDrag.initialStart + deltaSec;
          const clampedStart = Math.max(0, Math.min(timelineDrag.initialEnd - 0.5, rawNewStart));
          const finalStart = Math.round(clampedStart * 10) / 10;
          if (timelineDrag.type === 'text') {
            updateTextElement(timelineDrag.id, { startTime: finalStart });
          } else {
            updateImageElement(timelineDrag.id, { startTime: finalStart });
          }
          seekTo(finalStart);
        } else if (timelineDrag.mode === 'end') {
          const rawNewEnd = timelineDrag.initialEnd + deltaSec;
          const clampedEnd = Math.max(timelineDrag.initialStart + 0.5, Math.min(duration, rawNewEnd));
          const finalEnd = Math.round(clampedEnd * 10) / 10;
          if (timelineDrag.type === 'text') {
            updateTextElement(timelineDrag.id, { endTime: finalEnd });
          } else {
            updateImageElement(timelineDrag.id, { endTime: finalEnd });
          }
          seekTo(finalEnd);
        } else if (timelineDrag.mode === 'move') {
          const blockDuration = timelineDrag.initialEnd - timelineDrag.initialStart;
          const rawNewStart = timelineDrag.initialStart + deltaSec;
          const clampedStart = Math.max(0, Math.min(duration - blockDuration, rawNewStart));
          const finalStart = Math.round(clampedStart * 10) / 10;
          const finalEnd = Math.round((finalStart + blockDuration) * 10) / 10;
          if (timelineDrag.type === 'text') {
            updateTextElement(timelineDrag.id, { startTime: finalStart, endTime: finalEnd });
          } else {
            updateImageElement(timelineDrag.id, { startTime: finalStart, endTime: finalEnd });
          }
          seekTo(finalStart);
        }
        return;
      }

      if (!isDragging && !isResizing) return;
      const scale = getScale();
      const deltaX = (e.clientX - dragStart.x) / scale;
      const deltaY = (e.clientY - dragStart.y) / scale;

      if (isDragging && selectedElementId && selectedType) {
        const rawX = Math.round(elementStartPos.x + deltaX);
        const rawY = Math.round(elementStartPos.y + deltaY);

        if (selectedType === 'text') {
          // Clamp inside canvas bounds
          const clampedX = Math.max(30, Math.min(canvasWidth - 30, rawX));
          const clampedY = Math.max(30, Math.min(canvasHeight - 30, rawY));
          updateTextElement(selectedElementId, { x: clampedX, y: clampedY });
        } else {
          const clampedX = Math.max(0, Math.min(canvasWidth - 50, rawX));
          const clampedY = Math.max(0, Math.min(canvasHeight - 50, rawY));
          updateImageElement(selectedElementId, { x: clampedX, y: clampedY });
        }
      } else if (isResizing && selectedElementId && selectedType === 'image') {
        let newW = elementStartPos.width;
        let newH = elementStartPos.height;
        let newX = elementStartPos.x;
        let newY = elementStartPos.y;

        if (resizeHandle?.includes('e')) newW = Math.max(100, elementStartPos.width + deltaX);
        if (resizeHandle?.includes('s')) newH = Math.max(100, elementStartPos.height + deltaY);
        if (resizeHandle?.includes('w')) {
          const possibleW = elementStartPos.width - deltaX;
          if (possibleW > 100) {
            newW = possibleW;
            newX = elementStartPos.x + deltaX;
          }
        }
        if (resizeHandle?.includes('n')) {
          const possibleH = elementStartPos.height - deltaY;
          if (possibleH > 100) {
            newH = possibleH;
            newY = elementStartPos.y + deltaY;
          }
        }

        updateImageElement(selectedElementId, {
          x: Math.round(newX),
          y: Math.round(newY),
          width: Math.round(newW),
          height: Math.round(newH),
        });
      }
    },
    [isDragging, isResizing, selectedElementId, selectedType, dragStart, elementStartPos, resizeHandle, getScale, canvasWidth, canvasHeight, timelineDrag, duration]
  );

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
    setIsResizing(false);
    setResizeHandle(null);
    setTimelineDrag(null);
  }, []);

  useEffect(() => {
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [handleMouseMove, handleMouseUp]);

  // Timeline scrubbing click/drag
  const handleTimelineClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!timelineRef.current) return;
    const rect = timelineRef.current.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const ratio = Math.max(0, Math.min(1, clickX / rect.width));
    seekTo(ratio * duration);
  };

  // Save / Publish Template
  const handleSaveTemplate = async () => {
    setIsSaving(true);
    try {
      const payload: InvitationTemplate = {
        ...template,
        isPublished: true,
        textElements: template.textElements || [],
        imageElements: template.imageElements || [],
        photoSlotsCount: (template.imageElements || []).length,
        hasPhoto: (template.imageElements || []).length > 0,
      };
      const res = await fetch(`/api/templates/${template.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (res.ok) {
        setSaveToast('Template configuration published successfully!');
        onSave(payload);
        setTimeout(() => setSaveToast(null), 3500);
      } else {
        alert(`Error saving template: ${data.error || 'Unknown error'}`);
      }
    } catch (err: any) {
      alert(`Save error: ${err.message}`);
    } finally {
      setIsSaving(false);
    }
  };

  // Full Video Render Preview
  const handleTriggerRenderPreview = async () => {
    setIsRenderingPreview(true);
    setShowRenderModal(true);
    setRenderProgress(0.05);
    setRenderStep('Initializing rendering engine...');
    setRenderedVideoUrl(null);

    try {
      const formData = new FormData();
      formData.append('templateId', template.id);
      formData.append('previewMode', 'true');
      formData.append('templateConfig', JSON.stringify(template));
      Object.entries(previewUserData).forEach(([k, v]) => formData.append(k, v));

      const res = await fetch('/api/render?async=true', {
        method: 'POST',
        headers: { 'x-async-render': 'true' },
        body: formData,
      });

      const data = await res.json();
      if (res.ok && data.jobId) {
        const jobId = data.jobId;
        const interval = setInterval(async () => {
          try {
            const statusRes = await fetch(`/api/render/status/${jobId}`);
            if (statusRes.ok) {
              const statusData = await statusRes.json();
              setRenderProgress(statusData.progress || 0.1);
              setRenderStep(statusData.step || 'Processing...');

              if (statusData.status === 'completed') {
                clearInterval(interval);
                setIsRenderingPreview(false);
                setRenderedVideoUrl(statusData.videoUrl);
              } else if (statusData.status === 'failed') {
                clearInterval(interval);
                setIsRenderingPreview(false);
                alert(`Render failed: ${statusData.error}`);
              }
            }
          } catch (_) {}
        }, 1200);
      } else {
        setIsRenderingPreview(false);
        alert(data.error || 'Failed to start render');
      }
    } catch (err: any) {
      setIsRenderingPreview(false);
      alert(`Render preview error: ${err.message}`);
    }
  };

  // Resolve dynamic display text
  const resolveDisplayText = (txtEl: TextElementConfig) => {
    // When editing in studio, defaultText takes precedence so admins can customize text and see results immediately
    if (txtEl.defaultText && txtEl.defaultText.trim() !== '') {
      return txtEl.defaultText;
    }
    const key = txtEl.field as keyof typeof previewUserData;
    if (previewUserData[key] && previewUserData[key].trim() !== '') {
      return previewUserData[key];
    }
    if (txtEl.field === 'coupleNames') {
      return `${previewUserData.groomName || 'Groom'} & ${previewUserData.brideName || 'Bride'}`;
    }
    return txtEl.label || 'Text Element';
  };

  // Formatting duration helper
  const formatSec = (s: number) => {
    const mins = Math.floor(s / 60);
    const secs = Math.floor(s % 60);
    const ms = Math.floor((s % 1) * 10);
    return `${mins}:${secs.toString().padStart(2, '0')}.${ms}`;
  };

  return (
    <div className="flex flex-col h-screen bg-[#0A0A10] text-slate-100 overflow-hidden select-none">
      {/* Top Header Bar */}
      <header className="h-14 bg-[#12121C] border-b border-[#232332] px-4 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 pr-1 border-r border-[#26263A]">
            <img src="/logo.png" alt="My Invitation" className="w-8 h-8 object-contain drop-shadow" />
            <span className="font-playfair text-sm font-bold tracking-wide text-white hidden sm:inline">
              My Invitation
            </span>
          </div>

          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1A1A28] hover:bg-[#252538] text-slate-300 hover:text-white text-xs font-semibold transition-all border border-[#2A2A3E]"
          >
            <ArrowLeft className="w-4 h-4" />
            Catalog
          </button>

          <div className="h-5 w-[1px] bg-[#26263A]" />

          <div>
            <div className="flex items-center gap-2">
              <span className="font-playfair text-sm font-bold text-white truncate max-w-xs sm:max-w-md">
                {template.title}
              </span>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                {template.orientation}
              </span>
            </div>
            <p className="text-[10px] text-slate-400">
              Canvas: {canvasWidth} × {canvasHeight}px • Duration: {duration}s
            </p>
          </div>
        </div>

        {/* Center element add buttons & Ghost toggle */}
        <div className="hidden md:flex items-center gap-2">
          <button
            onClick={addTextElement}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#181826] hover:bg-amber-500/15 border border-amber-500/30 hover:border-amber-500/60 text-amber-300 text-xs font-semibold transition-all shadow-sm"
          >
            <Type className="w-3.5 h-3.5" />
            + Add Text
          </button>

          <button
            onClick={addImageElement}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#181826] hover:bg-purple-500/15 border border-purple-500/30 hover:border-purple-500/60 text-purple-300 text-xs font-semibold transition-all shadow-sm"
          >
            <ImageIcon className="w-3.5 h-3.5" />
            + Add Photo Placeholder
          </button>

          {/* Show All Inactive Elements (Ghost Mode) */}
          <button
            onClick={() => setShowInactiveElements(!showInactiveElements)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-xs font-semibold transition-all ${
              showInactiveElements
                ? 'bg-amber-500/20 border-amber-500 text-amber-300 shadow-sm shadow-amber-500/20'
                : 'bg-[#181826] border-[#2A2A3E] text-slate-400 hover:text-white'
            }`}
            title="When active, all text & photo elements remain visible as outlines at all timestamps so you can easily edit them"
          >
            <Eye className="w-3.5 h-3.5" />
            {showInactiveElements ? 'Showing All Timings' : 'Active Time Only'}
          </button>

          <button
            onClick={() => setShowTestDataPanel(!showTestDataPanel)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-xs font-semibold transition-all ${
              showTestDataPanel
                ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                : 'bg-[#181826] border-[#2A2A3E] text-slate-400 hover:text-white'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            Test Data
          </button>
        </div>

        {/* Right actions */}
        <div className="flex items-center gap-3">
          <button
            onClick={handleTriggerRenderPreview}
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-semibold text-xs shadow-md shadow-purple-500/20 transition-all active:scale-95"
          >
            <Sparkles className="w-3.5 h-3.5" />
            Full Video Preview
          </button>

          <button
            onClick={handleSaveTemplate}
            disabled={isSaving}
            className="flex items-center gap-1.5 px-4 py-1.5 rounded-lg bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-black font-bold text-xs shadow-lg shadow-amber-500/20 transition-all active:scale-95 disabled:opacity-50"
          >
            <Save className="w-3.5 h-3.5" />
            {isSaving ? 'Saving...' : 'Publish Template'}
          </button>
        </div>
      </header>

      {/* Save Notification Toast */}
      {saveToast && (
        <div className="fixed top-16 right-6 z-50 flex items-center gap-2 px-4 py-3 rounded-xl bg-emerald-500/90 text-black font-bold text-xs shadow-2xl backdrop-blur-md animate-bounce">
          <CheckCircle2 className="w-4 h-4" />
          <span>{saveToast}</span>
        </div>
      )}

      {/* Main Workspace (Preview + Configuration Panel) */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left/Center: Video Canvas Overlay Player */}
        <div className="flex-1 flex flex-col bg-[#07070C] p-4 overflow-hidden items-center justify-center relative">
          {/* Aspect-constrained Preview Container: strictly keeps aspect ratio without height clipping */}
          <div
            ref={containerRef}
            className="relative bg-black rounded-xl border border-[#2A2A3E] shadow-2xl overflow-hidden flex items-center justify-center select-none"
            style={{
              aspectRatio: template.orientation === '9:16' ? '9 / 16' : '16 / 9',
              height: template.orientation === '9:16' ? 'min(58vh, 580px)' : 'auto',
              width: template.orientation === '9:16' ? 'auto' : 'min(100%, calc(min(58vh, 580px) * 16 / 9))',
              maxHeight: 'min(58vh, 580px)',
              maxWidth: '100%',
            }}
          >
            {/* Background Master Video */}
            <video
              ref={videoRef}
              src={template.videoUrl}
              className="w-full h-full object-cover pointer-events-none"
              muted={isMuted}
              playsInline
              onPlay={() => setIsPlaying(true)}
              onPause={() => setIsPlaying(false)}
              onEnded={() => setIsPlaying(false)}
              onSeeked={() => {
                if (videoRef.current) setCurrentTime(videoRef.current.currentTime);
              }}
              onTimeUpdate={handleTimeUpdate}
            />

            {/* Canvas Interactive Overlay Layer */}
            <div className="absolute inset-0 pointer-events-auto overflow-hidden">
              {/* Image Placeholders */}
              {(template.imageElements || []).map((imgEl, idx) => {
                const isVisible = currentTime >= imgEl.startTime && currentTime <= imgEl.endTime;
                const isSelected = selectedElementId === imgEl.id;

                // Strict timeframe visibility: only elements active at this second are shown
                if (!isVisible && !showInactiveElements) {
                  return null;
                }

                const scale = getScale();
                const left = imgEl.x * scale;
                const top = imgEl.y * scale;
                const width = imgEl.width * scale;
                const height = imgEl.height * scale;

                // Procedural brush/ink animation synced to playhead scrubbing
                const animDur = imgEl.animationDuration || 1.2;
                const elapsed = Math.max(0, currentTime - imgEl.startTime);
                const progress = isVisible ? Math.min(1, elapsed / animDur) : (showInactiveElements ? 1 : 0);

                let clipPath = 'none';
                let animOpacity = 1;
                let animTransform = 'none';

                if (imgEl.animationType === 'ink_reveal') {
                  const radius = progress >= 1 ? 140 : progress * 140;
                  clipPath = progress >= 1 ? 'none' : `circle(${radius}% at 50% 50%)`;
                  animTransform = `scale(${0.92 + 0.08 * progress})`;
                  animOpacity = progress < 0.1 ? progress * 10 : 1;
                } else if (imgEl.animationType === 'brush_stroke') {
                  const p = progress * 100;
                  clipPath = progress >= 1 ? 'none' : `polygon(0% 0%, ${Math.min(100, p * 1.15)}% 0%, ${p}% 100%, 0% 100%)`;
                  animOpacity = Math.min(1, progress * 2.5);
                } else if (imgEl.animationType === 'fade') {
                  animOpacity = progress;
                }

                return (
                  <div
                    key={imgEl.id}
                    onMouseDown={(e) => handleMouseDown(e, imgEl.id, 'image')}
                    style={{
                      left: `${left}px`,
                      top: `${top}px`,
                      width: `${width}px`,
                      height: `${height}px`,
                      opacity: !isVisible ? 0.35 : 1,
                    }}
                    className={`absolute cursor-move transition-shadow z-10 ${
                      isSelected
                        ? 'ring-2 ring-purple-500 shadow-xl shadow-purple-500/40 z-30'
                        : isVisible
                        ? 'border border-purple-400/60 hover:border-purple-300 z-10'
                        : 'border border-dashed border-purple-500/50 hover:border-purple-300 z-10'
                    }`}
                  >
                    {/* Inner image representation with procedural reveal animation */}
                    <div
                      style={{
                        clipPath,
                        opacity: animOpacity,
                        transform: animTransform,
                        transition: isPlaying ? 'none' : 'clip-path 0.05s ease-out, transform 0.05s ease-out',
                      }}
                      className="w-full h-full relative overflow-hidden bg-purple-950/40 backdrop-blur-xs"
                    >
                      <img
                        src={imgEl.placeholderUrl || `/assets/candidate_logo${(idx % 4) + 1}.png`}
                        alt={imgEl.label}
                        className={`w-full h-full ${imgEl.fit === 'contain' ? 'object-contain' : 'object-cover'}`}
                        onError={(e) => {
                          (e.target as HTMLImageElement).src = '/assets/candidate_logo1.png';
                        }}
                      />
                      {/* Photo slot tag only when selected */}
                      {isSelected && (
                        <div className="absolute top-1 left-1 px-1.5 py-0.5 rounded bg-black/80 text-[9px] font-mono text-purple-200 border border-purple-400/40 pointer-events-none">
                          {imgEl.field} ({imgEl.animationType})
                        </div>
                      )}
                    </div>

                    {/* Resize Handles (Only when selected) */}
                    {isSelected && (
                      <>
                        <div
                          onMouseDown={(e) => handleMouseDown(e, imgEl.id, 'image', 'nw')}
                          className="absolute -top-1.5 -left-1.5 w-3 h-3 bg-white border border-purple-500 rounded-full cursor-nw-resize z-40 shadow-sm"
                        />
                        <div
                          onMouseDown={(e) => handleMouseDown(e, imgEl.id, 'image', 'ne')}
                          className="absolute -top-1.5 -right-1.5 w-3 h-3 bg-white border border-purple-500 rounded-full cursor-ne-resize z-40 shadow-sm"
                        />
                        <div
                          onMouseDown={(e) => handleMouseDown(e, imgEl.id, 'image', 'sw')}
                          className="absolute -bottom-1.5 -left-1.5 w-3 h-3 bg-white border border-purple-500 rounded-full cursor-sw-resize z-40 shadow-sm"
                        />
                        <div
                          onMouseDown={(e) => handleMouseDown(e, imgEl.id, 'image', 'se')}
                          className="absolute -bottom-1.5 -right-1.5 w-3 h-3 bg-white border border-purple-500 rounded-full cursor-se-resize z-40 shadow-sm"
                        />
                      </>
                    )}
                  </div>
                );
              })}

              {/* Text Elements - Clean Typography Only, NO CSS Black Box or Debug Metadata */}
              {(template.textElements || []).map((txtEl) => {
                const isVisible = currentTime >= txtEl.startTime && currentTime <= txtEl.endTime;
                const isSelected = selectedElementId === txtEl.id;

                // Strict timeframe visibility: only elements active at this second are shown
                if (!isVisible && !showInactiveElements) {
                  return null;
                }

                const scale = getScale();
                const left = txtEl.x * scale;
                const top = txtEl.y * scale;
                const fontSize = Math.max(12, (txtEl.fontSize || 36) * scale);
                const displayText = resolveDisplayText(txtEl);

                // Text fade-in / fade-out progress
                let textOpacity = 1;
                if (isSelected) {
                  textOpacity = 1; // Always fully visible when selected
                } else if (isVisible) {
                  const elapsed = currentTime - txtEl.startTime;
                  const remaining = txtEl.endTime - currentTime;
                  const fadeIn = txtEl.fadeIn || 0.5;
                  const fadeOut = txtEl.fadeOut || 0.5;
                  if (elapsed < fadeIn && fadeIn > 0) {
                    textOpacity = Math.max(0.15, elapsed / fadeIn);
                  } else if (remaining < fadeOut && fadeOut > 0) {
                    textOpacity = Math.max(0.15, remaining / fadeOut);
                  }
                } else {
                  textOpacity = 0.65; // Clear ghosting when inactive so editor can see and drag
                }

                return (
                  <div
                    key={txtEl.id}
                    onMouseDown={(e) => handleMouseDown(e, txtEl.id, 'text')}
                    style={{
                      left: `${left}px`,
                      top: `${top}px`,
                      transform:
                        txtEl.textAlign === 'center'
                          ? 'translate(-50%, -50%)'
                          : txtEl.textAlign === 'right'
                          ? 'translate(-100%, -50%)'
                          : 'translate(0, -50%)',
                      opacity: textOpacity,
                    }}
                    className={`absolute cursor-move select-none transition-all ${
                      isSelected
                        ? 'z-50 ring-2 ring-amber-400 ring-offset-2 ring-offset-black/60 bg-black/50 backdrop-blur-xs rounded px-2.5 py-1 shadow-2xl'
                        : isVisible
                        ? 'z-40 hover:ring-1 hover:ring-amber-300/80 rounded px-1.5 py-0.5'
                        : 'z-30 ring-1 ring-dashed ring-amber-400/60 bg-amber-950/30 rounded px-1.5 py-0.5'
                    }`}
                  >
                    {/* Element identifier badge shown only when selected */}
                    {isSelected && (
                      <div className="absolute -top-6 left-0 px-1.5 py-0.5 rounded bg-black/90 text-[10px] font-mono font-medium text-amber-300 border border-amber-500/50 pointer-events-none whitespace-nowrap z-50 shadow-md">
                        {txtEl.field || txtEl.label} ({txtEl.startTime}s - {txtEl.endTime}s)
                      </div>
                    )}

                    {/* Raw, pristine styled text only */}
                    <span
                      style={{
                        fontFamily: txtEl.fontFamily || 'Cinzel',
                        fontSize: `${fontSize}px`,
                        color: txtEl.fontColor || '#FFD700',
                        textAlign: txtEl.textAlign,
                        textShadow: '0 2px 8px rgba(0,0,0,0.95), 0 0 4px #000, 0 1px 3px rgba(0,0,0,0.9)',
                      }}
                      className="block leading-tight whitespace-nowrap font-semibold pointer-events-none"
                    >
                      {displayText}
                    </span>

                    {/* Small anchor handle dots on corners when selected to indicate draggable object */}
                    {isSelected && (
                      <>
                        <div className="absolute -top-1 -left-1 w-2.5 h-2.5 rounded-full bg-amber-400 shadow-sm pointer-events-none" />
                        <div className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-amber-400 shadow-sm pointer-events-none" />
                        <div className="absolute -bottom-1 -left-1 w-2.5 h-2.5 rounded-full bg-amber-400 shadow-sm pointer-events-none" />
                        <div className="absolute -bottom-1 -right-1 w-2.5 h-2.5 rounded-full bg-amber-400 shadow-sm pointer-events-none" />
                      </>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Video Player Floating Scrub / Transport Controls */}
          <div className="w-full max-w-xl mt-3 flex items-center justify-between px-4 py-2 bg-[#12121C]/90 backdrop-blur-md rounded-xl border border-[#232334] shadow-lg">
            <div className="flex items-center gap-2">
              <button
                onClick={() => seekTo(0)}
                className="p-1.5 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
                title="Restart"
              >
                <RotateCcw className="w-4 h-4" />
              </button>
              <button
                onClick={() => stepFrame(false)}
                className="p-1.5 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
                title="Previous Frame"
              >
                <SkipBack className="w-4 h-4" />
              </button>
              <button
                onClick={togglePlay}
                className="p-2 rounded-xl bg-amber-500 text-black hover:bg-amber-400 font-bold shadow-md transition-all active:scale-95"
              >
                {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
              </button>
              <button
                onClick={() => stepFrame(true)}
                className="p-1.5 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
                title="Next Frame"
              >
                <SkipForward className="w-4 h-4" />
              </button>
            </div>

            <div className="font-mono text-xs text-amber-300 font-bold bg-[#1A1A28] px-3 py-1 rounded-lg border border-[#2B2B3E]">
              {formatSec(currentTime)} <span className="text-slate-500">/</span> {formatSec(duration)}
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => setIsMuted(!isMuted)}
                className="p-1.5 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
                title={isMuted ? 'Unmute' : 'Mute'}
              >
                {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
              </button>
            </div>
          </div>
        </div>

        {/* Right Configuration Inspector & Layers Panel */}
        <aside className="w-80 md:w-96 bg-[#11111A] border-l border-[#222232] flex flex-col shrink-0 overflow-y-auto">
          {/* Header Tab Switcher: Inspector vs Layers */}
          <div className="p-3 border-b border-[#20202E] flex items-center justify-between">
            <div className="flex items-center gap-1 bg-[#181826] p-1 rounded-lg border border-[#28283C]">
              <button
                onClick={() => setInspectorTab('inspector')}
                className={`px-3 py-1 rounded text-xs font-semibold flex items-center gap-1.5 transition-all ${
                  inspectorTab === 'inspector'
                    ? 'bg-amber-500 text-black shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <Sliders className="w-3.5 h-3.5" />
                Inspector {selectedElementId ? `(${selectedType})` : ''}
              </button>
              <button
                onClick={() => setInspectorTab('layers')}
                className={`px-3 py-1 rounded text-xs font-semibold flex items-center gap-1.5 transition-all ${
                  inspectorTab === 'layers'
                    ? 'bg-amber-500 text-black shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <Layers className="w-3.5 h-3.5" />
                All Layers ({((template.textElements || []).length + (template.imageElements || []).length)})
              </button>
            </div>

            {selectedElementId && (
              <button
                onClick={() => {
                  setSelectedElementId(null);
                  setSelectedType(null);
                }}
                className="text-[11px] text-slate-400 hover:text-white px-2 py-1 rounded hover:bg-white/5"
              >
                Deselect
              </button>
            )}
          </div>

          {/* Test Data Drawer if toggled */}
          {showTestDataPanel && (
            <div className="p-4 border-b border-[#232336] bg-[#161622] space-y-2.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-amber-300">Live Customer Test Data</span>
                <span className="text-[10px] text-slate-400">Previews text injection</span>
              </div>
              <div>
                <label className="text-[10px] text-slate-400">Groom Name</label>
                <input
                  type="text"
                  value={previewUserData.groomName}
                  onChange={(e) => setPreviewUserData({ ...previewUserData, groomName: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#28283C] text-xs text-white"
                />
              </div>
              <div>
                <label className="text-[10px] text-slate-400">Bride Name</label>
                <input
                  type="text"
                  value={previewUserData.brideName}
                  onChange={(e) => setPreviewUserData({ ...previewUserData, brideName: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#28283C] text-xs text-white"
                />
              </div>
              <div>
                <label className="text-[10px] text-slate-400">Ceremony Title</label>
                <input
                  type="text"
                  value={previewUserData.ceremonyTitle}
                  onChange={(e) => setPreviewUserData({ ...previewUserData, ceremonyTitle: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#28283C] text-xs text-white"
                />
              </div>
              <div>
                <label className="text-[10px] text-slate-400">Venue</label>
                <input
                  type="text"
                  value={previewUserData.venue}
                  onChange={(e) => setPreviewUserData({ ...previewUserData, venue: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#28283C] text-xs text-white"
                />
              </div>
            </div>
          )}

          {/* INSPECTOR VIEW: Text Element Selected */}
          {inspectorTab === 'inspector' && selectedType === 'text' && selectedTextElement && (
            <div className="p-4 space-y-4">
              <div className="flex items-center justify-between pb-2 border-b border-[#20202E]">
                <div className="flex items-center gap-2 text-amber-300 font-semibold text-xs">
                  <Type className="w-4 h-4" />
                  Text Element: {selectedTextElement.field}
                </div>
                <button
                  onClick={() => deleteElement(selectedTextElement.id, 'text')}
                  className="p-1 rounded text-slate-500 hover:text-rose-400 hover:bg-rose-500/10"
                  title="Delete element"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              {/* Jump to Time & Active Banner */}
              <div className="flex items-center justify-between p-2 rounded-lg bg-amber-500/10 border border-amber-500/20 text-xs text-amber-300">
                <span>Active: {selectedTextElement.startTime}s - {selectedTextElement.endTime}s</span>
                <button
                  type="button"
                  onClick={() => seekTo(selectedTextElement.startTime)}
                  className="px-2 py-0.5 rounded bg-amber-500 text-black font-bold text-[10px] hover:bg-amber-400 transition-colors"
                >
                  Jump Playhead
                </button>
              </div>

              {/* Dynamic Field Mapping */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Dynamic Field Mapping
                </label>
                <select
                  value={selectedTextElement.field}
                  onChange={(e) => updateTextElement(selectedTextElement.id, { field: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-[#171724] border border-[#2A2A3E] text-xs text-amber-300 font-mono outline-none"
                >
                  <option value="groomName">groomName (Groom)</option>
                  <option value="brideName">brideName (Bride)</option>
                  <option value="coupleNames">coupleNames (Groom & Bride)</option>
                  <option value="ceremonyTitle">ceremonyTitle (e.g. Subha Vivaham)</option>
                  <option value="eventDate">eventDate (Wedding Date)</option>
                  <option value="muhurthamTime">muhurthamTime (Sumuhurtham)</option>
                  <option value="venue">venue (Kalyana Mandapam)</option>
                  <option value="rsvp">rsvp (Cordial Welcome)</option>
                  <option value="parentsNames">parentsNames</option>
                  <option value="customText">customText (Static / Free)</option>
                </select>
              </div>

              {/* Default Preview Text */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Default / Fallback Text</label>
                <input
                  type="text"
                  value={selectedTextElement.defaultText}
                  onChange={(e) => updateTextElement(selectedTextElement.id, { defaultText: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-[#171724] border border-[#2A2A3E] text-xs text-white outline-none"
                />
              </div>

              {/* Coordinates (X, Y) */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Position X (px)</label>
                  <input
                    type="number"
                    value={selectedTextElement.x}
                    onChange={(e) => updateTextElement(selectedTextElement.id, { x: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Position Y (px)</label>
                  <input
                    type="number"
                    value={selectedTextElement.y}
                    onChange={(e) => updateTextElement(selectedTextElement.id, { y: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
              </div>

              {/* Quick Alignment Helpers */}
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1">Quick Alignment Snap</label>
                <div className="grid grid-cols-4 gap-1.5">
                  <button
                    type="button"
                    onClick={() => updateTextElement(selectedTextElement.id, { x: Math.round(canvasWidth / 2) })}
                    className="px-2 py-1 rounded bg-[#1A1A28] hover:bg-[#252538] border border-[#2B2B3E] text-[10px] text-amber-300 font-semibold"
                  >
                    Center X
                  </button>
                  <button
                    type="button"
                    onClick={() => updateTextElement(selectedTextElement.id, { y: 120 })}
                    className="px-2 py-1 rounded bg-[#1A1A28] hover:bg-[#252538] border border-[#2B2B3E] text-[10px] text-slate-300 font-semibold"
                  >
                    Top
                  </button>
                  <button
                    type="button"
                    onClick={() => updateTextElement(selectedTextElement.id, { y: Math.round(canvasHeight / 2) })}
                    className="px-2 py-1 rounded bg-[#1A1A28] hover:bg-[#252538] border border-[#2B2B3E] text-[10px] text-slate-300 font-semibold"
                  >
                    Middle
                  </button>
                  <button
                    type="button"
                    onClick={() => updateTextElement(selectedTextElement.id, { y: canvasHeight - 200 })}
                    className="px-2 py-1 rounded bg-[#1A1A28] hover:bg-[#252538] border border-[#2B2B3E] text-[10px] text-slate-300 font-semibold"
                  >
                    Bottom
                  </button>
                </div>
              </div>

              {/* Font Family & Size */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Font Family</label>
                  <select
                    value={selectedTextElement.fontFamily}
                    onChange={(e) => updateTextElement(selectedTextElement.id, { fontFamily: e.target.value })}
                    className="w-full px-2.5 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white"
                  >
                    <option value="Cinzel">Cinzel (Royal)</option>
                    <option value="Playfair Display">Playfair (Classic)</option>
                    <option value="Georgia">Georgia</option>
                    <option value="Montserrat">Montserrat</option>
                    <option value="Roboto">Roboto</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Font Size ({selectedTextElement.fontSize}px)</label>
                  <input
                    type="range"
                    min="18"
                    max="96"
                    value={selectedTextElement.fontSize}
                    onChange={(e) => updateTextElement(selectedTextElement.id, { fontSize: Number(e.target.value) })}
                    className="w-full accent-amber-500"
                  />
                </div>
              </div>

              {/* Font Color & Text Align */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Font Color</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="color"
                      value={selectedTextElement.fontColor}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { fontColor: e.target.value })}
                      className="w-8 h-8 rounded border border-white/20 bg-transparent cursor-pointer"
                    />
                    <input
                      type="text"
                      value={selectedTextElement.fontColor}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { fontColor: e.target.value })}
                      className="w-20 px-2 py-1 rounded bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Alignment</label>
                  <div className="flex items-center gap-1 bg-[#171724] p-1 rounded-lg border border-[#2A2A3E]">
                    {(['left', 'center', 'right'] as TextAlign[]).map((al) => (
                      <button
                        key={al}
                        type="button"
                        onClick={() => updateTextElement(selectedTextElement.id, { textAlign: al })}
                        className={`flex-1 py-1 rounded flex items-center justify-center ${
                          selectedTextElement.textAlign === al
                            ? 'bg-amber-500 text-black'
                            : 'text-slate-400 hover:text-white'
                        }`}
                      >
                        {al === 'left' && <AlignLeft className="w-3.5 h-3.5" />}
                        {al === 'center' && <AlignCenter className="w-3.5 h-3.5" />}
                        {al === 'right' && <AlignRight className="w-3.5 h-3.5" />}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Timing Controls */}
              <div className="p-3 bg-[#161622] rounded-xl border border-[#26263A] space-y-3">
                <div className="flex items-center justify-between text-xs font-bold text-amber-300">
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5" />
                    <span>Independent Timing Controls</span>
                  </div>
                  <button
                    onClick={() =>
                      updateTextElement(selectedTextElement.id, {
                        startTime: currentTime,
                        endTime: Math.min(duration, currentTime + 10),
                      })
                    }
                    className="text-[10px] text-amber-400 hover:underline"
                  >
                    Set at Playhead
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] text-slate-400">Start Time (sec)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0"
                      max={duration}
                      value={selectedTextElement.startTime}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { startTime: Number(e.target.value) })}
                      className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#2A2A3C] text-xs text-white font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] text-slate-400">End Time (sec)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0"
                      max={duration}
                      value={selectedTextElement.endTime}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { endTime: Number(e.target.value) })}
                      className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#2A2A3C] text-xs text-white font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] text-slate-400">Fade In ({selectedTextElement.fadeIn}s)</label>
                    <input
                      type="range"
                      min="0"
                      max="3"
                      step="0.1"
                      value={selectedTextElement.fadeIn}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { fadeIn: Number(e.target.value) })}
                      className="w-full accent-amber-500"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] text-slate-400">Fade Out ({selectedTextElement.fadeOut}s)</label>
                    <input
                      type="range"
                      min="0"
                      max="3"
                      step="0.1"
                      value={selectedTextElement.fadeOut}
                      onChange={(e) => updateTextElement(selectedTextElement.id, { fadeOut: Number(e.target.value) })}
                      className="w-full accent-amber-500"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* INSPECTOR VIEW: Image Element Selected */}
          {inspectorTab === 'inspector' && selectedType === 'image' && selectedImageElement && (
            <div className="p-4 space-y-4">
              <div className="flex items-center justify-between pb-2 border-b border-[#20202E]">
                <div className="flex items-center gap-2 text-purple-300 font-semibold text-xs">
                  <ImageIcon className="w-4 h-4" />
                  Image Placeholder: {selectedImageElement.field}
                </div>
                <button
                  onClick={() => deleteElement(selectedImageElement.id, 'image')}
                  className="p-1 rounded text-slate-500 hover:text-rose-400 hover:bg-rose-500/10"
                  title="Delete image placeholder"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              {/* Jump to Time Banner */}
              <div className="flex items-center justify-between p-2 rounded-lg bg-purple-500/10 border border-purple-500/20 text-xs text-purple-300">
                <span>Active: {selectedImageElement.startTime}s - {selectedImageElement.endTime}s</span>
                <button
                  type="button"
                  onClick={() => seekTo(selectedImageElement.startTime)}
                  className="px-2 py-0.5 rounded bg-purple-500 text-white font-bold text-[10px] hover:bg-purple-400 transition-colors"
                >
                  Jump Playhead
                </button>
              </div>

              {/* User upload field mapping */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  User Upload Field Mapping
                </label>
                <select
                  value={selectedImageElement.field}
                  onChange={(e) => updateImageElement(selectedImageElement.id, { field: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-[#171724] border border-[#2A2A3E] text-xs text-purple-300 font-mono outline-none"
                >
                  <option value="photo_1">photo_1 (Photo 1 Slot)</option>
                  <option value="photo_2">photo_2 (Photo 2 Slot)</option>
                  <option value="photo_3">photo_3 (Photo 3 Slot)</option>
                  <option value="photo_4">photo_4 (Photo 4 Slot)</option>
                  <option value="photo_5">photo_5 (Photo 5 Slot)</option>
                  <option value="womanPhoto">womanPhoto (Bride Portrait)</option>
                  <option value="manPhoto">manPhoto (Groom Portrait)</option>
                </select>
              </div>

              {/* Admin Slot Label */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Admin Slot Label</label>
                <input
                  type="text"
                  value={selectedImageElement.label}
                  onChange={(e) => updateImageElement(selectedImageElement.id, { label: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-[#171724] border border-[#2A2A3E] text-xs text-white outline-none"
                />
              </div>

              {/* Position and Dimensions */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">X Position (px)</label>
                  <input
                    type="number"
                    value={selectedImageElement.x}
                    onChange={(e) => updateImageElement(selectedImageElement.id, { x: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Y Position (px)</label>
                  <input
                    type="number"
                    value={selectedImageElement.y}
                    onChange={(e) => updateImageElement(selectedImageElement.id, { y: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Width (px)</label>
                  <input
                    type="number"
                    value={selectedImageElement.width}
                    onChange={(e) => updateImageElement(selectedImageElement.id, { width: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Height (px)</label>
                  <input
                    type="number"
                    value={selectedImageElement.height}
                    onChange={(e) => updateImageElement(selectedImageElement.id, { height: Number(e.target.value) })}
                    className="w-full px-3 py-1.5 rounded-lg bg-[#171724] border border-[#2A2A3E] text-xs text-white font-mono"
                  />
                </div>
              </div>

              {/* Image Fit Mode */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Image Fit Mode</label>
                <div className="grid grid-cols-2 gap-2">
                  {(['cover', 'contain'] as ImageFit[]).map((fit) => (
                    <button
                      key={fit}
                      type="button"
                      onClick={() => updateImageElement(selectedImageElement.id, { fit })}
                      className={`py-1.5 rounded-lg text-xs font-semibold uppercase ${
                        selectedImageElement.fit === fit
                          ? 'bg-purple-600 text-white shadow-md'
                          : 'bg-[#171724] text-slate-400 hover:text-white border border-[#28283C]'
                      }`}
                    >
                      {fit}
                    </button>
                  ))}
                </div>
              </div>

              {/* Reveal Animation FX */}
              <div className="p-3 bg-[#161622] rounded-xl border border-[#26263A] space-y-3">
                <div className="flex items-center gap-1.5 text-xs font-bold text-purple-300">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Reveal Animation FX</span>
                </div>

                <div>
                  <label className="block text-[11px] text-slate-400 mb-1">Animation Type</label>
                  <select
                    value={selectedImageElement.animationType}
                    onChange={(e) =>
                      updateImageElement(selectedImageElement.id, { animationType: e.target.value as any })
                    }
                    className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#2A2A3C] text-xs text-white"
                  >
                    <option value="ink_reveal">1. Ink Reveal (Organic Bleed)</option>
                    <option value="brush_stroke">2. Brush Stroke Reveal</option>
                    <option value="fade">3. Simple Fade In</option>
                    <option value="none">4. No Animation (Cut)</option>
                  </select>
                </div>

                <div>
                  <div className="flex items-center justify-between text-[11px] text-slate-400 mb-1">
                    <span>Animation Duration</span>
                    <span className="font-mono text-purple-300">{selectedImageElement.animationDuration || 1.2}s</span>
                  </div>
                  <input
                    type="range"
                    min="0.3"
                    max="3.0"
                    step="0.1"
                    value={selectedImageElement.animationDuration || 1.2}
                    onChange={(e) =>
                      updateImageElement(selectedImageElement.id, { animationDuration: Number(e.target.value) })
                    }
                    className="w-full accent-purple-500"
                  />
                </div>
              </div>

              {/* Timing Controls */}
              <div className="p-3 bg-[#161622] rounded-xl border border-[#26263A] space-y-3">
                <div className="flex items-center justify-between text-xs font-bold text-amber-300">
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5" />
                    <span>Independent Timing Controls</span>
                  </div>
                  <button
                    onClick={() =>
                      updateImageElement(selectedImageElement.id, {
                        startTime: currentTime,
                        endTime: Math.min(duration, currentTime + 8),
                      })
                    }
                    className="text-[10px] text-amber-400 hover:underline"
                  >
                    Set at Playhead
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] text-slate-400">Start Time (sec)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0"
                      max={duration}
                      value={selectedImageElement.startTime}
                      onChange={(e) =>
                        updateImageElement(selectedImageElement.id, { startTime: Number(e.target.value) })
                      }
                      className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#2A2A3C] text-xs text-white font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] text-slate-400">End Time (sec)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0"
                      max={duration}
                      value={selectedImageElement.endTime}
                      onChange={(e) =>
                        updateImageElement(selectedImageElement.id, { endTime: Number(e.target.value) })
                      }
                      className="w-full px-2.5 py-1.5 rounded bg-[#101018] border border-[#2A2A3C] text-xs text-white font-mono"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* LAYERS VIEW: Always accessible or shown when nothing is selected */}
          {(inspectorTab === 'layers' || !selectedElementId) && (
            <div className="p-4 space-y-4">
              {/* Text Layers Section */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-amber-300">
                    <Type className="w-3.5 h-3.5" />
                    <span>Text Layers ({(template.textElements || []).length})</span>
                  </div>
                  <button
                    onClick={addTextElement}
                    className="text-[10px] font-semibold text-amber-300 hover:text-white px-2 py-0.5 rounded bg-amber-500/10 border border-amber-500/30"
                  >
                    + Add Text
                  </button>
                </div>

                <div className="space-y-1.5">
                  {(template.textElements || []).map((txtEl) => {
                    const isVisible = currentTime >= txtEl.startTime && currentTime <= txtEl.endTime;
                    const isSelected = selectedElementId === txtEl.id;

                    return (
                      <div
                        key={txtEl.id}
                        onClick={() => {
                          setSelectedElementId(txtEl.id);
                          setSelectedType('text');
                          setInspectorTab('inspector');
                          seekTo(txtEl.startTime);
                        }}
                        className={`p-2.5 rounded-xl border cursor-pointer transition-all ${
                          isSelected
                            ? 'bg-amber-500/20 border-amber-500 shadow-md ring-1 ring-amber-400'
                            : 'bg-[#151522] border-[#252538] hover:border-amber-500/50 hover:bg-[#1a1a2b]'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 rounded bg-amber-500/20 text-amber-300 text-[10px] font-bold flex items-center justify-center">
                              T
                            </span>
                            <div>
                              <p className="text-xs font-semibold text-white truncate max-w-[150px]">
                                {txtEl.field}
                              </p>
                              <p className="text-[10px] text-slate-400 truncate max-w-[160px]">
                                &ldquo;{txtEl.defaultText}&rdquo;
                              </p>
                            </div>
                          </div>

                          <div className="text-right">
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9px] font-mono font-bold ${
                                isVisible
                                  ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                                  : 'bg-slate-800 text-slate-400'
                              }`}
                            >
                              {isVisible ? 'Active' : `${txtEl.startTime}s`}
                            </span>
                            <p className="text-[9px] font-mono text-slate-500 mt-0.5">
                              {txtEl.startTime}s - {txtEl.endTime}s
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Photo Placeholders Section */}
              <div className="space-y-2 pt-2 border-t border-[#20202E]">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-purple-300">
                    <ImageIcon className="w-3.5 h-3.5" />
                    <span>Photo Slots ({(template.imageElements || []).length})</span>
                  </div>
                  <button
                    onClick={addImageElement}
                    className="text-[10px] font-semibold text-purple-300 hover:text-white px-2 py-0.5 rounded bg-purple-500/10 border border-purple-500/30"
                  >
                    + Add Photo
                  </button>
                </div>

                <div className="space-y-1.5">
                  {(template.imageElements || []).map((imgEl) => {
                    const isVisible = currentTime >= imgEl.startTime && currentTime <= imgEl.endTime;
                    const isSelected = selectedElementId === imgEl.id;

                    return (
                      <div
                        key={imgEl.id}
                        onClick={() => {
                          setSelectedElementId(imgEl.id);
                          setSelectedType('image');
                          setInspectorTab('inspector');
                          seekTo(imgEl.startTime);
                        }}
                        className={`p-2.5 rounded-xl border cursor-pointer transition-all ${
                          isSelected
                            ? 'bg-purple-500/20 border-purple-500 shadow-md ring-1 ring-purple-400'
                            : 'bg-[#151522] border-[#252538] hover:border-purple-500/50 hover:bg-[#1a1a2b]'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 rounded bg-purple-500/20 text-purple-300 text-[10px] font-bold flex items-center justify-center">
                              P
                            </span>
                            <div>
                              <p className="text-xs font-semibold text-white truncate max-w-[150px]">
                                {imgEl.field}
                              </p>
                              <p className="text-[10px] text-purple-300/80">
                                {imgEl.animationType} ({imgEl.animationDuration || 1.2}s)
                              </p>
                            </div>
                          </div>

                          <div className="text-right">
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9px] font-mono font-bold ${
                                isVisible
                                  ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                                  : 'bg-slate-800 text-slate-400'
                              }`}
                            >
                              {isVisible ? 'Active' : `${imgEl.startTime}s`}
                            </span>
                            <p className="text-[9px] font-mono text-slate-500 mt-0.5">
                              {imgEl.startTime}s - {imgEl.endTime}s
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}
        </aside>
      </div>

      {/* Bottom Visual Multi-Track Timeline Editor */}
      <div className="h-64 bg-[#0E0E16] border-t border-[#232334] flex flex-col shrink-0">
        {/* Timeline Header & Track Filters */}
        <div className="h-9 bg-[#13131F] border-b border-[#20202E] px-4 flex items-center justify-between">
          <div className="flex items-center gap-3 text-xs font-semibold text-slate-400">
            <span className="text-amber-400 flex items-center gap-1.5">
              <Sliders className="w-3.5 h-3.5" />
              Timeline Multi-Tracks
            </span>

            {/* Track Filter Tabs */}
            <div className="flex items-center gap-1 bg-[#181826] p-0.5 rounded-lg border border-[#252538]">
              <button
                onClick={() => setTrackFilter('all')}
                className={`px-2.5 py-0.5 rounded text-[10px] font-semibold transition-all ${
                  trackFilter === 'all'
                    ? 'bg-amber-500 text-black shadow-sm font-bold'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                All ({((template.textElements || []).length + (template.imageElements || []).length)})
              </button>
              <button
                onClick={() => setTrackFilter('text')}
                className={`px-2.5 py-0.5 rounded text-[10px] font-semibold transition-all ${
                  trackFilter === 'text'
                    ? 'bg-amber-500 text-black shadow-sm font-bold'
                    : 'text-amber-300 hover:text-white'
                }`}
              >
                Text Tracks ({(template.textElements || []).length})
              </button>
              <button
                onClick={() => setTrackFilter('image')}
                className={`px-2.5 py-0.5 rounded text-[10px] font-semibold transition-all ${
                  trackFilter === 'image'
                    ? 'bg-purple-500 text-white shadow-sm font-bold'
                    : 'text-purple-300 hover:text-white'
                }`}
              >
                Photo Tracks ({(template.imageElements || []).length})
              </button>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={addTextElement}
              className="text-[11px] font-semibold text-amber-300 hover:text-amber-200 px-2 py-0.5 rounded bg-amber-500/10 border border-amber-500/30"
            >
              + Text
            </button>
            <button
              onClick={addImageElement}
              className="text-[11px] font-semibold text-purple-300 hover:text-purple-200 px-2 py-0.5 rounded bg-purple-500/10 border border-purple-500/30"
            >
              + Photo
            </button>
          </div>
        </div>

        {/* Tracks Container with smooth scrollbar */}
        <div
          ref={timelineRef}
          onClick={handleTimelineClick}
          className="flex-1 relative overflow-x-auto overflow-y-auto px-4 py-2 cursor-pointer select-none space-y-1.5"
        >
          {/* Time Ruler Ticks */}
          <div className="relative h-5 border-b border-[#252538] flex items-center text-[9px] font-mono text-slate-500">
            {Array.from({ length: Math.ceil(duration / 5) + 1 }).map((_, i) => {
              const sec = i * 5;
              const leftPct = (sec / duration) * 100;
              return (
                <div
                  key={sec}
                  style={{ left: `${leftPct}%` }}
                  className="absolute transform -translate-x-1/2 flex flex-col items-center"
                >
                  <span className="h-1.5 w-[1px] bg-slate-600 mb-0.5" />
                  <span>{sec}s</span>
                </div>
              );
            })}
          </div>

          {/* Master Video Track */}
          <div className="relative h-6 rounded bg-[#171724] border border-[#26263A] flex items-center px-2 text-[10px] text-slate-400 font-mono">
            <Film className="w-3 h-3 mr-2 text-slate-500" />
            <span>Master Video Layer: {template.title} ({duration}s)</span>
          </div>

          {/* Text Overlay Tracks */}
          {(trackFilter === 'all' || trackFilter === 'text') &&
            (template.textElements || []).map((txtEl) => {
              const leftPct = (txtEl.startTime / duration) * 100;
              const widthPct = Math.max(2, ((txtEl.endTime - txtEl.startTime) / duration) * 100);
              const isSelected = selectedElementId === txtEl.id;
              const isDraggingThis = timelineDrag && timelineDrag.id === txtEl.id;

              return (
                <div key={txtEl.id} className="relative h-7 rounded bg-[#12121C] border border-[#1E1E2C] flex items-center">
                  <div
                    style={{ left: `${leftPct}%`, width: `${widthPct}%` }}
                    className={`absolute top-0.5 bottom-0.5 rounded-lg flex items-center justify-between text-[11px] font-semibold transition-shadow ${
                      isSelected
                        ? 'bg-amber-500 text-black shadow-lg shadow-amber-500/30 ring-2 ring-amber-200 z-20'
                        : 'bg-amber-950/70 hover:bg-amber-900/90 text-amber-200 border border-amber-500/40 z-10'
                    }`}
                  >
                    {/* Left Trim Handle */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, txtEl.id, 'text', 'start', txtEl.startTime, txtEl.endTime)}
                      className="absolute left-0 top-0 bottom-0 w-3 cursor-ew-resize hover:bg-amber-300/50 flex items-center justify-center rounded-l z-30 group/handle"
                      title="Drag left/right to trim start time"
                    >
                      <div className="w-0.5 h-3 bg-amber-200/80 group-hover/handle:bg-white rounded-full pointer-events-none" />
                    </div>

                    {/* Middle Draggable Track Body */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, txtEl.id, 'text', 'move', txtEl.startTime, txtEl.endTime)}
                      className="flex-1 h-full flex items-center justify-between px-3 cursor-grab active:cursor-grabbing overflow-hidden select-none"
                    >
                      <div className="flex items-center gap-1.5 truncate pointer-events-none">
                        <Type className="w-3 h-3 shrink-0" />
                        <span className="truncate">{txtEl.field}: &ldquo;{txtEl.defaultText}&rdquo;</span>
                      </div>
                      <span className="text-[9px] font-mono opacity-80 shrink-0 ml-1 pointer-events-none">
                        {txtEl.startTime}s - {txtEl.endTime}s
                      </span>
                    </div>

                    {/* Right Trim Handle */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, txtEl.id, 'text', 'end', txtEl.startTime, txtEl.endTime)}
                      className="absolute right-0 top-0 bottom-0 w-3 cursor-ew-resize hover:bg-amber-300/50 flex items-center justify-center rounded-r z-30 group/handle"
                      title="Drag left/right to trim end time"
                    >
                      <div className="w-0.5 h-3 bg-amber-200/80 group-hover/handle:bg-white rounded-full pointer-events-none" />
                    </div>

                    {/* Live Timing Tooltip when dragging */}
                    {isDraggingThis && (
                      <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-black/95 text-amber-300 text-[10px] font-mono px-2 py-0.5 rounded shadow-xl border border-amber-500/50 pointer-events-none whitespace-nowrap z-50">
                        {timelineDrag.mode === 'start'
                          ? `Start: ${txtEl.startTime.toFixed(1)}s`
                          : timelineDrag.mode === 'end'
                          ? `End: ${txtEl.endTime.toFixed(1)}s`
                          : `${txtEl.startTime.toFixed(1)}s - ${txtEl.endTime.toFixed(1)}s (${(txtEl.endTime - txtEl.startTime).toFixed(1)}s)`}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}

          {/* Image Overlay Tracks (Photo 1..5) */}
          {(trackFilter === 'all' || trackFilter === 'image') &&
            (template.imageElements || []).map((imgEl) => {
              const leftPct = (imgEl.startTime / duration) * 100;
              const widthPct = Math.max(2, ((imgEl.endTime - imgEl.startTime) / duration) * 100);
              const isSelected = selectedElementId === imgEl.id;
              const isDraggingThis = timelineDrag && timelineDrag.id === imgEl.id;

              return (
                <div key={imgEl.id} className="relative h-7 rounded bg-[#12121C] border border-[#1E1E2C] flex items-center">
                  <div
                    style={{ left: `${leftPct}%`, width: `${widthPct}%` }}
                    className={`absolute top-0.5 bottom-0.5 rounded-lg flex items-center justify-between text-[11px] font-semibold transition-shadow ${
                      isSelected
                        ? 'bg-purple-600 text-white shadow-lg shadow-purple-500/30 ring-2 ring-purple-300 z-20'
                        : 'bg-purple-900/60 hover:bg-purple-800/80 text-purple-200 border border-purple-500/40 z-10'
                    }`}
                  >
                    {/* Left Trim Handle */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, imgEl.id, 'image', 'start', imgEl.startTime, imgEl.endTime)}
                      className="absolute left-0 top-0 bottom-0 w-3 cursor-ew-resize hover:bg-purple-400/50 flex items-center justify-center rounded-l z-30 group/handle"
                      title="Drag left/right to trim start time"
                    >
                      <div className="w-0.5 h-3 bg-purple-200/80 group-hover/handle:bg-white rounded-full pointer-events-none" />
                    </div>

                    {/* Middle Draggable Track Body */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, imgEl.id, 'image', 'move', imgEl.startTime, imgEl.endTime)}
                      className="flex-1 h-full flex items-center justify-between px-3 cursor-grab active:cursor-grabbing overflow-hidden select-none"
                    >
                      <div className="flex items-center gap-1.5 truncate pointer-events-none">
                        <ImageIcon className="w-3 h-3 shrink-0" />
                        <span className="truncate">{imgEl.field} ({imgEl.animationType})</span>
                      </div>
                      <span className="text-[9px] font-mono opacity-80 shrink-0 ml-1 pointer-events-none">
                        {imgEl.startTime}s - {imgEl.endTime}s
                      </span>
                    </div>

                    {/* Right Trim Handle */}
                    <div
                      onMouseDown={(e) => handleTimelineDragStart(e, imgEl.id, 'image', 'end', imgEl.startTime, imgEl.endTime)}
                      className="absolute right-0 top-0 bottom-0 w-3 cursor-ew-resize hover:bg-purple-400/50 flex items-center justify-center rounded-r z-30 group/handle"
                      title="Drag left/right to trim end time"
                    >
                      <div className="w-0.5 h-3 bg-purple-200/80 group-hover/handle:bg-white rounded-full pointer-events-none" />
                    </div>

                    {/* Live Timing Tooltip when dragging */}
                    {isDraggingThis && (
                      <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-black/95 text-purple-300 text-[10px] font-mono px-2 py-0.5 rounded shadow-xl border border-purple-500/50 pointer-events-none whitespace-nowrap z-50">
                        {timelineDrag.mode === 'start'
                          ? `Start: ${imgEl.startTime.toFixed(1)}s`
                          : timelineDrag.mode === 'end'
                          ? `End: ${imgEl.endTime.toFixed(1)}s`
                          : `${imgEl.startTime.toFixed(1)}s - ${imgEl.endTime.toFixed(1)}s (${(imgEl.endTime - imgEl.startTime).toFixed(1)}s)`}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}

          {/* Red Playhead Scrub Line */}
          <div
            style={{ left: `${(currentTime / duration) * 100}%` }}
            className="absolute top-0 bottom-0 w-0.5 bg-rose-500 pointer-events-none z-30 shadow-md"
          >
            <div className="w-3 h-3 bg-rose-500 rounded-full transform -translate-x-1.5 -translate-y-1 shadow-md shadow-rose-500/50" />
          </div>
        </div>
      </div>

      {/* Full Video Render Preview Modal */}
      {showRenderModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-fadeIn">
          <div className="relative w-full max-w-3xl bg-[#12121D] rounded-2xl border border-[#2B2B3E] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="px-6 py-4 border-b border-[#232334] flex items-center justify-between bg-[#151522]">
              <div className="flex items-center gap-2.5">
                <Sparkles className="w-5 h-5 text-purple-400" />
                <h3 className="font-playfair text-base font-bold text-white">Full Video Composition Preview</h3>
              </div>
              <button
                onClick={() => setShowRenderModal(false)}
                className="text-slate-400 hover:text-white text-xs font-semibold"
              >
                Close
              </button>
            </div>

            <div className="p-6 flex flex-col items-center justify-center">
              {isRenderingPreview ? (
                <div className="w-full max-w-md text-center py-10 space-y-4">
                  <div className="w-14 h-14 mx-auto rounded-full bg-purple-500/15 border border-purple-500/30 flex items-center justify-center animate-spin">
                    <Sparkles className="w-7 h-7 text-purple-400" />
                  </div>
                  <h4 className="text-sm font-bold text-white">Rendering 1080p Video via FFmpeg Engine</h4>
                  <p className="text-xs text-slate-400">{renderStep}</p>

                  <div className="w-full h-3 rounded-full bg-[#1A1A28] overflow-hidden border border-[#2A2A3E]">
                    <div
                      style={{ width: `${Math.round(renderProgress * 100)}%` }}
                      className="h-full bg-gradient-to-r from-purple-500 via-indigo-500 to-amber-500 transition-all duration-300"
                    />
                  </div>
                  <p className="text-xs font-mono text-purple-300 font-bold">{Math.round(renderProgress * 100)}%</p>
                </div>
              ) : renderedVideoUrl ? (
                <div className="w-full flex flex-col items-center space-y-4">
                  <div className="relative aspect-video w-full rounded-xl overflow-hidden border border-[#28283C] bg-black">
                    <video
                      src={renderedVideoUrl}
                      controls
                      autoPlay
                      className="w-full h-full object-contain"
                    />
                  </div>
                  <div className="flex items-center gap-3">
                    <a
                      href={renderedVideoUrl}
                      download="invitation_preview.mp4"
                      className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-black font-bold text-xs shadow-lg transition-all"
                    >
                      Download Rendered MP4
                    </a>
                  </div>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
