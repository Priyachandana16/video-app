'use client';

import React, { useState, useEffect } from 'react';
import Navbar from '../components/Navbar';
import TemplateCard from '../components/TemplateCard';
import CreateTemplateModal from '../components/CreateTemplateModal';
import VisualTimelineEditor from '../components/VisualTimelineEditor';
import MediaAssetsList from '../components/MediaAssetsList';
import AdminLogin from '../components/AdminLogin';
import { InvitationTemplate } from '../types/template';
import { Film, Sparkles, Filter, RefreshCw, AlertCircle, Layers, CheckCircle } from 'lucide-react';

export default function AdminDashboardPage() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [adminUser, setAdminUser] = useState<string>('admin');
  const [isCheckingAuth, setIsCheckingAuth] = useState<boolean>(true);

  const [templates, setTemplates] = useState<InvitationTemplate[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Check Admin session on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem('my_invitation_admin_session');
      if (stored) {
        const session = JSON.parse(stored);
        if (session && session.user) {
          setAdminUser(session.user);
          setIsAuthenticated(true);
        }
      }
    } catch (_) {}
    setIsCheckingAuth(false);
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('my_invitation_admin_session');
    setIsAuthenticated(false);
  };

  // Filters
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedOrientation, setSelectedOrientation] = useState('All');

  // Modal / Editor State
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<InvitationTemplate | null>(null);
  const [activeTab, setActiveTab] = useState('templates');

  const categories = ['All', 'Wedding', 'First Birthday', 'Birthday', 'Anniversary', 'Festivals'];
  const orientations = ['All', '16:9', '9:16'];

  const fetchTemplates = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/templates');
      if (!res.ok) throw new Error(`Server returned ${res.status}`);
      const data = await res.json();
      setTemplates(data.templates || []);
    } catch (err: any) {
      console.error('Failed to load templates:', err);
      setError(err.message || 'Could not connect to backend server');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchTemplates();
  }, []);

  const handleDeleteTemplate = async (id: string) => {
    try {
      const res = await fetch(`/api/templates/${id}`, { method: 'DELETE' });
      if (res.ok) {
        setTemplates((prev) => prev.filter((t) => t.id !== id));
      } else {
        alert('Failed to delete template');
      }
    } catch (err: any) {
      alert(`Delete error: ${err.message}`);
    }
  };

  const handleTemplateSaved = (updated: InvitationTemplate) => {
    setTemplates((prev) =>
      prev.map((t) => (t.id === updated.id ? updated : t))
    );
  };

  const handleEditTemplate = async (tmpl: InvitationTemplate) => {
    // Immediate safe fallback so editor opens instantly without throwing
    const safeTmpl: InvitationTemplate = {
      ...tmpl,
      textElements: tmpl.textElements || [],
      imageElements: tmpl.imageElements || [],
    };
    setEditingTemplate(safeTmpl);

    // Fetch the full rich config (with all text & photo placeholders from template_versions)
    try {
      const res = await fetch(`/api/templates/${tmpl.id}`);
      if (res.ok) {
        const fullTmpl = await res.json();
        if (fullTmpl && fullTmpl.id) {
          setEditingTemplate({
            ...fullTmpl,
            textElements: fullTmpl.textElements || [],
            imageElements: fullTmpl.imageElements || [],
          });
        }
      }
    } catch (err) {
      console.warn('Could not fetch full template configuration:', err);
    }
  };

  // Render loading state while reading localStorage session
  if (isCheckingAuth) {
    return (
      <div className="min-h-screen bg-[#0A0A10] flex items-center justify-center">
        <div className="w-8 h-8 rounded-full border-2 border-amber-400 border-t-transparent animate-spin" />
      </div>
    );
  }

  // Require Admin Login if not authenticated
  if (!isAuthenticated) {
    return (
      <AdminLogin
        onLoginSuccess={(user) => {
          setAdminUser(user);
          setIsAuthenticated(true);
        }}
      />
    );
  }

  // If in Visual Timeline Editor mode, render editor full-screen
  if (editingTemplate) {
    return (
      <VisualTimelineEditor
        template={editingTemplate}
        onBack={() => setEditingTemplate(null)}
        onSave={handleTemplateSaved}
      />
    );
  }

  // Filter templates
  const filteredTemplates = templates.filter((t) => {
    if (selectedCategory !== 'All' && t.category.toLowerCase() !== selectedCategory.toLowerCase()) {
      return false;
    }
    if (selectedOrientation !== 'All' && t.orientation !== selectedOrientation) {
      return false;
    }
    return true;
  });

  return (
    <div className="min-h-screen bg-[#0A0A10] flex flex-col">
      <Navbar
        onNewTemplateClick={() => setIsCreateModalOpen(true)}
        activeTab={activeTab}
        onTabChange={(tab) => setActiveTab(tab)}
        adminUser={adminUser}
        onLogout={handleLogout}
      />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Hero Banner */}
        <div className="relative rounded-3xl bg-gradient-to-r from-[#1E1711] via-[#14121F] to-[#12121D] p-8 border border-[#2D232A] overflow-hidden shadow-2xl">
          <div className="absolute top-0 right-0 -mr-16 -mt-16 w-80 h-80 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />
          <div className="relative z-10 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/15 border border-amber-500/30 text-amber-300 text-xs font-semibold mb-3">
              <Sparkles className="w-3.5 h-3.5" />
              Dynamic Video Invitation Configuration Engine
            </div>
            <h1 className="font-playfair text-3xl sm:text-4xl font-bold tracking-tight text-white">
              Admin Template Studio & Visual Timeline Editor
            </h1>
            <p className="text-sm text-slate-300 mt-2.5 leading-relaxed">
              Design video invitations once by positioning dynamic text overlays and multiple photo placeholders (up to 5 photos) with animated ink reveals, brush strokes, and exact timestamps. Customers automatically generate personalized 1080p videos.
            </p>
          </div>
        </div>

        {/* Tab Content */}
        {activeTab === 'assets' ? (
          <MediaAssetsList />
        ) : (
          <div className="space-y-6">
            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-4 rounded-2xl bg-[#13131D] border border-[#232334]">
              {/* Category pills */}
              <div className="flex items-center gap-2 overflow-x-auto max-w-full pb-1 sm:pb-0">
                {categories.map((cat) => (
                  <button
                    key={cat}
                    onClick={() => setSelectedCategory(cat)}
                    className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                      selectedCategory === cat
                        ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-black shadow-md shadow-amber-500/20'
                        : 'bg-[#181824] hover:bg-white/5 text-slate-400 hover:text-white border border-[#26263A]'
                    }`}
                  >
                    {cat}
                  </button>
                ))}
              </div>

              {/* Orientation & Actions */}
              <div className="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end">
                <div className="flex items-center gap-1.5 bg-[#181824] p-1 rounded-xl border border-[#26263A]">
                  {orientations.map((ori) => (
                    <button
                      key={ori}
                      onClick={() => setSelectedOrientation(ori)}
                      className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                        selectedOrientation === ori
                          ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40'
                          : 'text-slate-400 hover:text-white'
                      }`}
                    >
                      {ori}
                    </button>
                  ))}
                </div>

                <button
                  onClick={fetchTemplates}
                  className="p-2 rounded-xl bg-[#181824] border border-[#26263A] text-slate-400 hover:text-white hover:border-slate-500 transition-colors"
                  title="Refresh templates catalog"
                >
                  <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
                </button>
              </div>
            </div>

            {/* Error Message */}
            {error && (
              <div className="flex items-center gap-3 p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-sm">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <span>{error}. Please verify the backend service on port 5000 is active.</span>
              </div>
            )}

            {/* Templates Grid */}
            {isLoading ? (
              <div className="py-24 text-center text-slate-400 space-y-3">
                <div className="w-10 h-10 mx-auto rounded-full border-2 border-amber-500 border-t-transparent animate-spin" />
                <p className="text-sm font-medium">Loading templates catalog from backend...</p>
              </div>
            ) : filteredTemplates.length === 0 ? (
              <div className="py-24 text-center bg-[#111119] rounded-3xl border border-[#222232] space-y-4">
                <Layers className="w-12 h-12 mx-auto text-slate-600" />
                <h3 className="text-base font-bold text-white">No Templates Found</h3>
                <p className="text-xs text-slate-400 max-w-sm mx-auto">
                  No templates match the selected filter criteria. Create your first dynamic invitation template now.
                </p>
                <button
                  onClick={() => setIsCreateModalOpen(true)}
                  className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-black font-semibold text-xs tracking-wide shadow-lg shadow-amber-500/20 transition-all"
                >
                  Create Invitation Template
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredTemplates.map((template) => (
                  <TemplateCard
                    key={template.id}
                    template={template}
                    onSelect={(tmpl) => handleEditTemplate(tmpl)}
                    onDelete={handleDeleteTemplate}
                  />
                ))}
              </div>
            )}
          </div>
        )}
      </main>

      {/* Create Template Modal */}
      <CreateTemplateModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        onCreated={(newTemplate) => {
          setTemplates((prev) => [newTemplate, ...prev]);
          setEditingTemplate(newTemplate);
        }}
      />
    </div>
  );
}

