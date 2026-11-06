'use client';

import React, { useState, useEffect } from 'react';
import { MediaAsset } from '../types/template';
import { Video, Image as ImageIcon, Upload, Check, RefreshCw, FileText } from 'lucide-react';

export default function MediaAssetsList() {
  const [assets, setAssets] = useState<MediaAsset[]>([]);
  const [filter, setFilter] = useState<'all' | 'video' | 'image'>('all');
  const [isLoading, setIsLoading] = useState(true);
  const [isUploading, setIsUploading] = useState(false);
  const [previewAsset, setPreviewAsset] = useState<MediaAsset | null>(null);

  const loadAssets = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/admin/media-assets');
      const data = await res.json();
      setAssets(data.assets || []);
    } catch (err) {
      console.error('Failed to load assets:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadAssets();
  }, []);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const formData = new FormData();
    formData.append('file', file);

    try {
      const res = await fetch('/api/admin/upload-asset', {
        method: 'POST',
        body: formData,
      });
      if (res.ok) {
        await loadAssets();
      } else {
        alert('Upload failed');
      }
    } catch (err: any) {
      alert(`Error: ${err.message}`);
    } finally {
      setIsUploading(false);
      e.target.value = '';
    }
  };

  const filtered = assets.filter((a) => {
    if (filter === 'all') return true;
    return a.type === filter;
  });

  return (
    <div className="space-y-6">
      {/* Action Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-4 rounded-2xl bg-[#13131D] border border-[#232334]">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold border ${
              filter === 'all'
                ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                : 'bg-[#181824] border-[#262638] text-slate-400'
            }`}
          >
            All Assets ({assets.length})
          </button>
          <button
            onClick={() => setFilter('video')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold border ${
              filter === 'video'
                ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                : 'bg-[#181824] border-[#262638] text-slate-400'
            }`}
          >
            Videos ({assets.filter((a) => a.type === 'video').length})
          </button>
          <button
            onClick={() => setFilter('image')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold border ${
              filter === 'image'
                ? 'bg-amber-500/20 border-amber-500 text-amber-300'
                : 'bg-[#181824] border-[#262638] text-slate-400'
            }`}
          >
            Images ({assets.filter((a) => a.type === 'image').length})
          </button>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={loadAssets}
            className="p-2 rounded-xl bg-[#181824] border border-[#28283C] text-slate-300 hover:text-white"
            title="Refresh"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          </button>

          <label className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 text-black font-semibold text-xs cursor-pointer shadow-lg hover:shadow-amber-500/20 transition-all">
            <Upload className="w-4 h-4" />
            <span>{isUploading ? 'Uploading...' : 'Upload Video/Image'}</span>
            <input
              type="file"
              accept="video/*,image/*"
              onChange={handleFileUpload}
              disabled={isUploading}
              className="hidden"
            />
          </label>
        </div>
      </div>

      {/* Grid */}
      {isLoading ? (
        <div className="py-20 text-center text-slate-400 text-sm">Loading media assets...</div>
      ) : filtered.length === 0 ? (
        <div className="py-20 text-center text-slate-500 text-sm">No media assets found</div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {filtered.map((asset) => (
            <div
              key={asset.filePath}
              onClick={() => setPreviewAsset(asset)}
              className="group relative bg-[#13131C] rounded-2xl border border-[#232332] hover:border-amber-500/40 overflow-hidden cursor-pointer shadow-md transition-all flex flex-col justify-between"
            >
              <div className="relative aspect-video w-full bg-black overflow-hidden flex items-center justify-center">
                {asset.type === 'video' ? (
                  <video
                    src={asset.url}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                    muted
                    preload="metadata"
                  />
                ) : (
                  <img
                    src={asset.url}
                    alt={asset.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                )}
                <div className="absolute top-2 left-2 px-2 py-0.5 rounded bg-black/75 text-[10px] font-bold text-amber-300 border border-white/10 uppercase">
                  {asset.type}
                </div>
              </div>

              <div className="p-3">
                <p className="text-xs font-semibold text-white truncate group-hover:text-amber-300">
                  {asset.name}
                </p>
                <div className="flex items-center justify-between text-[10px] text-slate-500 mt-1 font-mono">
                  <span>{(asset.sizeBytes / (1024 * 1024)).toFixed(2)} MB</span>
                  <span className="truncate max-w-[120px]">{asset.filePath}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Media Preview Modal */}
      {previewAsset && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md">
          <div className="relative w-full max-w-2xl bg-[#12121C] rounded-2xl border border-[#2B2B3E] overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-playfair text-sm font-bold text-white truncate">{previewAsset.name}</h3>
              <button
                onClick={() => setPreviewAsset(null)}
                className="text-xs text-slate-400 hover:text-white"
              >
                Close
              </button>
            </div>

            <div className="aspect-video w-full rounded-xl overflow-hidden bg-black flex items-center justify-center">
              {previewAsset.type === 'video' ? (
                <video src={previewAsset.url} controls autoPlay className="w-full h-full object-contain" />
              ) : (
                <img src={previewAsset.url} alt={previewAsset.name} className="w-full h-full object-contain" />
              )}
            </div>

            <div className="text-xs text-slate-400 font-mono bg-[#181826] p-3 rounded-xl border border-[#26263A] break-all">
              Path: {previewAsset.filePath}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

