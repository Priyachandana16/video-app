# COMPLETE SUPABASE & STORAGE INTEGRATION — VIDEO INVITATION PLATFORM

## 1. PROJECT CREDENTIALS & MCP CONNECTION

- **Supabase Personal Access Token**: `[CONFIGURED_SECURELY_VIA_ENV_OR_SECRET]` (Starts with `sbp_...`)
- **Scope**: Dedicated Invitation Video Generation Platform project.

### Instructions for Connecting Supabase MCP:
1. Disconnect any previously connected Supabase project.
2. Connect to the Invitation Platform project using the provided Supabase token.
3. Verify connection by running a project and table check before executing any DDL.
4. Keep the token and `service_role` keys secure on backend/admin services only.
5. Provide the project `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the Flutter client.

---

## 2. EXISTING APPLICATION ARCHITECTURE

We already have a working, full-stack video invitation platform across 3 layers:

1. **Next.js Admin Studio** (`admin-dashboard/`):
   - Multi-track visual timeline editor (`VisualTimelineEditor.tsx`).
   - Standard 1920×1080 canvas coordinate mapping with 60 FPS playhead scrubbing.
   - Element inspector for typography (fonts, sizes, colors, drop shadows) and multi-photo slots.
   - Procedural alpha reveal animation configurator (`ink_reveal`, `brush_stroke`, `fade`).
2. **Flutter Customer Mobile & Web App** (`lib/`):
   - Browse occasions & dynamic template catalog.
   - Multi-photo dynamic upload slots (`photo_1` to `photo_5+` based on template requirements).
   - Real-time video rendering progress tracker with milestone steps.
3. **Backend API & Accelerated FFmpeg Render Engine** (`backend/`):
   - Node.js Express server (`server.js`) on port 5000 managing jobs and streaming progress.
   - Python FFmpeg engine (`render_engine.py`) executing active-segment compositing in ~35–45 seconds with time-offset mask reveal animations (`setpts=PTS-STARTPTS+st/TB`).

> **CRITICAL ARCHITECTURAL CONSTRAINTS**:
> - **DO NOT rebuild the UI or redesign existing screens.**
> - **DO NOT change the 1920×1080 coordinate system.**
> - **Video rendering is executed by the backend Python/FFmpeg engine (`backend/render_engine.py`), NOT on the customer's phone.**
> - The objective is to migrate from local JSON files (`templates.json`, `db.json`) and local disk storage to **Supabase Database (PostgreSQL + JSONB)** and **Supabase Storage**.

---

## 3. SUPABASE DATABASE SCHEMA SPECIFICATION

Execute the following migrations with Row Level Security (RLS) enabled:

### A. Profiles (`profiles`)
Linked directly to Supabase Auth:
```sql
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);
```

### B. Occasions (`occasions`)
Dynamic categorization for browsing:
```sql
CREATE TABLE IF NOT EXISTS public.occasions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    subtitle TEXT,
    icon_url TEXT,
    thumbnail_url TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.occasions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Occasions are viewable by everyone" 
ON public.occasions FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage occasions" 
ON public.occasions FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
```

### C. Templates (`templates`)
Master catalog metadata:
```sql
CREATE TABLE IF NOT EXISTS public.templates (
    id TEXT PRIMARY KEY,
    occasion_id TEXT NOT NULL REFERENCES public.occasions(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    description TEXT,
    badge_text TEXT DEFAULT 'CHROMA KEY PRO',
    category TEXT NOT NULL DEFAULT 'Wedding',
    religion TEXT DEFAULT 'Universal',
    orientation TEXT NOT NULL DEFAULT '16:9' CHECK (orientation IN ('16:9', '9:16')),
    canvas_width INT NOT NULL DEFAULT 1920,
    canvas_height INT NOT NULL DEFAULT 1080,
    duration_seconds NUMERIC NOT NULL DEFAULT 60.0,
    has_photo BOOLEAN NOT NULL DEFAULT true,
    photo_slots_count INT NOT NULL DEFAULT 5,
    master_video_url TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    sample_result_url TEXT,
    is_published BOOLEAN NOT NULL DEFAULT true,
    current_version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Published templates are viewable by everyone" 
ON public.templates FOR SELECT USING (is_published = true);

CREATE POLICY "Admins can manage templates" 
ON public.templates FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
```

### D. Template Versions (`template_versions`)
Stores immutable published JSONB configurations (the single source of truth for rendering):
```sql
CREATE TABLE IF NOT EXISTS public.template_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id TEXT NOT NULL REFERENCES public.templates(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    config JSONB NOT NULL,
    published_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (template_id, version_number)
);

ALTER TABLE public.template_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Template versions viewable by everyone" 
ON public.template_versions FOR SELECT USING (true);

CREATE POLICY "Admins can insert template versions" 
ON public.template_versions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
```

### E. Invitation Generations (`invitation_generations`)
Tracks personalized customer rendering jobs and results:
```sql
CREATE TABLE IF NOT EXISTS public.invitation_generations (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    template_id TEXT NOT NULL REFERENCES public.templates(id),
    template_version_id UUID REFERENCES public.template_versions(id),
    title TEXT,
    couple_names TEXT,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
    progress NUMERIC NOT NULL DEFAULT 0.05,
    current_step TEXT NOT NULL DEFAULT 'Initializing invitation engine...',
    user_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    input_photos JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_video_url TEXT,
    thumbnail_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    completed_at TIMESTAMPTZ
);

ALTER TABLE public.invitation_generations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own creations" 
ON public.invitation_generations FOR SELECT USING (
    auth.uid() = user_id OR user_id IS NULL
);

CREATE POLICY "Service role and backend can manage all jobs" 
ON public.invitation_generations FOR ALL USING (true);
```

---

## 4. SUPABASE STORAGE ARCHITECTURE

Configure 4 dedicated storage buckets:

| Bucket Name | Access | Purpose & Folder Conventions |
| :--- | :--- | :--- |
| `invitation-templates` | **Public** | Master MP4 background videos and preview thumbnails.<br>`/masters/{template_id}_master.mp4`<br>`/thumbnails/{template_id}_thumb.jpg` |
| `template-assets` | **Public** | Reusable masks and font assets.<br>`/masks/ink_reveal.mp4`<br>`/masks/brush_stroke.mp4`<br>`/fonts/{font_name}.ttf` |
| `user-uploads` | **Authenticated / Signed** | Customer uploaded photographs for rendering.<br>`/raw/{user_id}/{job_id}/photo_1.jpg`<br>`/raw/{user_id}/{job_id}/photo_2.jpg` |
| `generated-videos` | **Public / Signed** | Final personalized MP4 videos.<br>`/renders/{user_id}/{job_id}_invitation.mp4` |

### Storage Bucket Creation Script:
```sql
INSERT INTO storage.buckets (id, name, public) VALUES 
('invitation-templates', 'invitation-templates', true),
('template-assets', 'template-assets', true),
('user-uploads', 'user-uploads', false),
('generated-videos', 'generated-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for public reading of template assets
CREATE POLICY "Public read invitation-templates" ON storage.objects FOR SELECT USING (bucket_id = 'invitation-templates');
CREATE POLICY "Public read template-assets" ON storage.objects FOR SELECT USING (bucket_id = 'template-assets');
CREATE POLICY "Public read generated-videos" ON storage.objects FOR SELECT USING (bucket_id = 'generated-videos');

-- Policy for customer photo uploads
CREATE POLICY "Users upload to user-uploads" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'user-uploads' AND auth.role() = 'authenticated'
);
CREATE POLICY "Users read own user-uploads" ON storage.objects FOR SELECT USING (
    bucket_id = 'user-uploads' AND auth.uid()::text = (storage.foldername(name))[2]
);
```

---

## 5. SEEDING INITIAL ASSETS & TEMPLATES

Seed existing local files from the repository into Supabase:

1. **Upload Assets to Storage**:
   - `assets/templates/template_01_green_screen.mp4` -> `invitation-templates/masters/template_01_green_screen.mp4`
   - `assets/templates/thumb_01_green.jpg` -> `invitation-templates/thumbnails/thumb_01_green.jpg`
   - `assets/masks/ink_reveal.mp4` -> `template-assets/masks/ink_reveal.mp4`
   - `assets/masks/brush_stroke.mp4` -> `template-assets/masks/brush_stroke.mp4`

2. **Insert Occasions**:
   - `'wedding'` -> Title: `"Wedding / Vivaham"`
   - `'birthday'` -> Title: `"Birthday Celebration"`
   - `'half_saree'` -> Title: `"Half Saree Ceremony"`
   - `'housewarming'` -> Title: `"Housewarming / Gruhapravesam"`
   - `'engagement'` -> Title: `"Engagement Ceremony"`

3. **Insert Template & Version 1**:
   - Insert `'tmpl_telugu_chroma_01'` into `templates` referencing the storage URLs.
   - Insert row into `template_versions` containing the full JSON from `backend/data/templates.json` with active element coordinates, active timeframes, and animation types.

---

## 6. END-TO-END WORKFLOW INTEGRATION

### Step A: Next.js Admin Studio (`admin-dashboard/`)
1. Replace `backend/data/templates.json` reads/writes with Supabase Client queries.
2. When admin edits elements and clicks **"Publish Template"**:
   - Updates `templates` row.
   - Inserts new version into `template_versions` with the complete JSONB configuration.
3. Master video uploads in Admin Studio go directly to Supabase Storage bucket `invitation-templates`.

### Step B: Flutter Customer App (`lib/`)
1. Integrate `supabase_flutter` package.
2. Connect login/signup to `supabase.auth`.
3. Fetch occasions and active templates dynamically from Supabase `templates` table.
4. Dynamically generate photo upload slots based on `template.imageElements.length`.
5. Upload selected photos to Supabase Storage bucket `user-uploads`.
6. Send render request to Backend API with photo storage paths.
7. Poll `invitation_generations` or listen via Supabase Realtime to show live progress (0% to 100%).
8. Play final MP4 video directly from Supabase Storage `generated-videos` URL.

### Step C: Backend API & Python Render Engine (`backend/`)
1. Fetch template JSONB config from Supabase `template_versions`.
2. Cache master video and animation masks locally in `/tmp` or `assets/` if not present.
3. Download user photos from `user-uploads` bucket.
4. Execute `render_engine.py` using active-segment FFmpeg compositing (renders in ~35s).
5. Stream progress updates (`PROGRESS: 0.XX | <step>`) to `invitation_generations` table.
6. Upload completed MP4 to Supabase Storage bucket `generated-videos`.
7. Update `invitation_generations` status to `completed` with `output_video_url`.

---

## 7. VERIFICATION CHECKLIST

- [ ] Supabase connection verified via MCP tool.
- [ ] Database tables and RLS policies created.
- [ ] 4 storage buckets created with appropriate permissions.
- [ ] Master video and mask files uploaded to Storage.
- [ ] Admin Studio publishes template updates directly to Supabase `template_versions`.
- [ ] Flutter app loads dynamic templates from Supabase.
- [ ] Customer can upload 5 photos and generate video.
- [ ] Render engine completes in <45s and uploads final MP4 to `generated-videos`.
- [ ] Customer can preview and download the rendered MP4.
