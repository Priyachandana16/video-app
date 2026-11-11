import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET(request: Request, { params }: { params: { id: string } }) {
  try {
    const id = params.id;
    const { data: row, error } = await supabase
      .from('templates')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !row) {
      return NextResponse.json({ error: 'Template not found' }, { status: 404 });
    }

    const { data: verRows } = await supabase
      .from('template_versions')
      .select('version_number, config')
      .eq('template_id', id)
      .order('version_number', { ascending: false })
      .limit(1);

    const cfg = (verRows && verRows.length > 0) ? (verRows[0].config as Record<string, any>) : {};

    const template = {
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

    return NextResponse.json(template);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

export async function PUT(request: Request, { params }: { params: { id: string } }) {
  try {
    const id = params.id;
    const body = await request.json();

    const { data: current, error: curErr } = await supabase
      .from('templates')
      .select('*')
      .eq('id', id)
      .single();

    if (curErr || !current) {
      return NextResponse.json({ error: `Template not found: ${id}` }, { status: 404 });
    }

    const nextVersion = (current.current_version || 1) + 1;

    const updateFields: any = {
      title: body.title || current.title,
      description: body.description !== undefined ? body.description : current.description,
      badge_text: body.badgeText || current.badge_text,
      category: body.category || current.category,
      religion: body.religion || current.religion,
      orientation: body.orientation || current.orientation,
      canvas_width: body.canvasWidth || current.canvas_width,
      canvas_height: body.canvasHeight || current.canvas_height,
      duration_seconds: body.durationSeconds || current.duration_seconds,
      has_photo: body.imageElements ? body.imageElements.length > 0 : current.has_photo,
      photo_slots_count: body.imageElements ? body.imageElements.length : current.photo_slots_count,
      is_published: body.isPublished !== undefined ? body.isPublished : true,
      current_version: nextVersion,
      updated_at: new Date().toISOString(),
    };

    if (body.masterVideoPath || body.videoUrl) {
      updateFields.master_video_url = body.masterVideoPath || body.videoUrl;
    }
    if (body.thumbnailUrl) {
      updateFields.thumbnail_url = body.thumbnailUrl;
    }

    const { error: upErr } = await supabase
      .from('templates')
      .update(updateFields)
      .eq('id', id);

    if (upErr) {
      return NextResponse.json({ error: upErr.message }, { status: 500 });
    }

    const config = {
      ...body,
      id,
      currentVersion: nextVersion,
      updatedAt: new Date().toISOString(),
    };

    const { error: verErr } = await supabase
      .from('template_versions')
      .insert({
        template_id: id,
        version_number: nextVersion,
        config,
      });

    if (verErr) {
      console.error('Failed to insert template version:', verErr);
      return NextResponse.json({ error: verErr.message }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      message: 'Template configuration published successfully to Supabase',
      template: { ...config, ...updateFields },
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: { id: string } }) {
  try {
    const id = params.id;
    const { error } = await supabase.from('templates').delete().eq('id', id);
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({ success: true, message: 'Template deleted' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
