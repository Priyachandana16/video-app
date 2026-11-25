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
    const videoSource = row.master_video_url || cfg.videoUrl || cfg.masterVideoPath || '';

    const template = {
      ...cfg,
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
      masterVideoUrl: videoSource,
      videoUrl: videoSource,
      masterVideoPath: videoSource,
      audioUrl: cfg.audioUrl || cfg.audioPath || (row as any).audio_url || '',
      audioPath: cfg.audioPath || cfg.audioUrl || (row as any).audio_url || '',
      thumbnailUrl: row.thumbnail_url || cfg.thumbnailUrl,
      sampleResultUrl: row.sample_result_url || cfg.sampleResultUrl,
      isPublished: row.is_published,
      currentVersion: row.current_version,
      textElements: Array.isArray(cfg.textElements) ? cfg.textElements : [],
      imageElements: Array.isArray(cfg.imageElements) ? cfg.imageElements : [],
      timelineConfig: cfg.timelineConfig || null,
      masterVideoChromaKey: cfg.masterVideoChromaKey || cfg.chromaKey || false,
      masterVideoChromaKeyColor: cfg.masterVideoChromaKeyColor || cfg.chromaKeyColor || '#0DAB0D',
      masterVideoChromaKeySimilarity: cfg.masterVideoChromaKeySimilarity ?? cfg.chromaSimilarity ?? 0.38,
      masterVideoChromaKeyBlend: cfg.masterVideoChromaKeyBlend ?? cfg.chromaBlend ?? 0.12,
      updatedAt: row.updated_at,
    };

    return NextResponse.json(template);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

function getOccasionId(category?: string): string {
  const cat = (category || '').toLowerCase();
  if (cat.includes('saree') || cat.includes('voni')) return 'half_saree';
  if (cat.includes('birth')) return 'birthday';
  if (cat.includes('house') || cat.includes('gruha')) return 'housewarming';
  if (cat.includes('engage') || cat.includes('nishchit')) return 'engagement';
  if (cat.includes('ai')) return 'ai_generated';
  return 'wedding';
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
    const resolvedCategory = body.category || current.category;
    const resolvedOccasion = body.occasion_id || body.occasionId || current.occasion_id || getOccasionId(resolvedCategory);

    const updateFields: any = {
      occasion_id: resolvedOccasion,
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
      masterVideoChromaKey: body.masterVideoChromaKey || body.chromaKey || false,
      masterVideoChromaKeyColor: body.masterVideoChromaKeyColor || body.chromaKeyColor || '#0DAB0D',
      masterVideoChromaKeySimilarity: body.masterVideoChromaKeySimilarity ?? body.chromaSimilarity ?? 0.38,
      masterVideoChromaKeyBlend: body.masterVideoChromaKeyBlend ?? body.chromaBlend ?? 0.12,
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

    // 1. Delete associated invitation generations (foreign key constraint)
    await supabase.from('invitation_generations').delete().eq('template_id', id);

    // 2. Delete associated template versions (foreign key constraint)
    await supabase.from('template_versions').delete().eq('template_id', id);

    // 3. Delete the template itself
    const { error } = await supabase.from('templates').delete().eq('id', id);
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({ success: true, message: 'Template deleted' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
