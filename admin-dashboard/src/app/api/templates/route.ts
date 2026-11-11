import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const religion = searchParams.get('religion');
    const orientation = searchParams.get('orientation');

    let query = supabase
      .from('templates')
      .select('*')
      .order('created_at', { ascending: true });

    if (category && category !== 'All') {
      query = query.ilike('category', category);
    }
    if (religion && religion !== 'All') {
      query = query.ilike('religion', religion);
    }
    if (orientation && orientation !== 'All') {
      query = query.eq('orientation', orientation);
    }

    const { data: rows, error } = await query;
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    const templateIds = (rows || []).map((r) => r.id);
    const versionsMap: Record<string, any> = {};

    if (templateIds.length > 0) {
      const { data: verRows } = await supabase
        .from('template_versions')
        .select('template_id, version_number, config')
        .in('template_id', templateIds)
        .order('version_number', { ascending: false });

      if (verRows) {
        for (const v of verRows) {
          if (!versionsMap[v.template_id]) {
            versionsMap[v.template_id] = v.config;
          }
        }
      }
    }

    const templates = (rows || []).map((row) => {
      const cfg = versionsMap[row.id] || {};
      return {
        id: row.id,
        title: row.title,
        description: row.description,
        badgeText: row.badge_text,
        category: row.category,
        religion: row.religion,
        orientation: row.orientation,
        canvasWidth: row.canvas_width,
        canvasHeight: row.canvas_height,
        durationSeconds: row.duration_seconds,
        hasPhoto: row.has_photo,
        photoSlotsCount: row.photo_slots_count,
        masterVideoUrl: row.master_video_url,
        videoUrl: row.master_video_url,
        thumbnailUrl: row.thumbnail_url,
        sampleResultUrl: row.sample_result_url,
        isPublished: row.is_published,
        currentVersion: row.current_version,
        textElements: Array.isArray(cfg.textElements) ? cfg.textElements : [],
        imageElements: Array.isArray(cfg.imageElements) ? cfg.imageElements : [],
        timelineConfig: cfg.timelineConfig || null,
        updatedAt: row.updated_at,
      };
    });

    return NextResponse.json({ count: templates.length, templates });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const id = body.id || `tmpl_${(body.category || 'custom').toLowerCase().replace(/[^a-z0-9]/g, '_')}_${Date.now()}`;
    const orientation = body.orientation || '16:9';
    const canvasWidth = body.canvasWidth || (orientation === '9:16' ? 1080 : 1920);
    const canvasHeight = body.canvasHeight || (orientation === '9:16' ? 1920 : 1080);
    const durationSeconds = body.durationSeconds || 60;
    const imageElements = Array.isArray(body.imageElements) ? body.imageElements : [];
    const textElements = Array.isArray(body.textElements) ? body.textElements : [];

    const newRow = {
      id,
      title: body.title || 'Untitled Template',
      description: body.description || '',
      badge_text: body.badgeText || 'NEW',
      category: body.category || 'Wedding',
      religion: body.religion || 'Hindu',
      orientation,
      canvas_width: canvasWidth,
      canvas_height: canvasHeight,
      duration_seconds: durationSeconds,
      has_photo: imageElements.length > 0,
      photo_slots_count: imageElements.length,
      master_video_url: body.masterVideoPath || body.videoUrl || 'assets/templates/template_01_green_screen.mp4',
      thumbnail_url: body.thumbnailUrl || 'assets/templates/thumb_01_green.jpg',
      is_published: body.isPublished !== undefined ? body.isPublished : true,
      current_version: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { error: insErr } = await supabase.from('templates').insert(newRow);
    if (insErr) {
      return NextResponse.json({ error: insErr.message }, { status: 500 });
    }

    const config = {
      ...body,
      id,
      currentVersion: 1,
      textElements,
      imageElements,
      updatedAt: new Date().toISOString(),
    };

    await supabase.from('template_versions').insert({
      template_id: id,
      version_number: 1,
      config,
    });

    return NextResponse.json({
      success: true,
      message: 'Template created successfully in Supabase',
      template: { ...config, ...newRow },
    }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
