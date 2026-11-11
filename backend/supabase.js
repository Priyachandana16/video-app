const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://fyohjrfsiftpqmjhrpjm.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5b2hqcmZzaWZ0cHFtamhycGptIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5NDIxNTM0NywiZXhwIjoyMTA5NzkxMzQ3fQ.yvx6AU-D9u0vopsMPaEUnIo3A4EZxPrboTlMSI7mPIA';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false }
});

/**
 * Fetch all occasions
 */
async function getOccasions() {
  const { data, error } = await supabase
    .from('occasions')
    .select('*')
    .eq('is_active', true)
    .order('display_order', { ascending: true });

  if (error) {
    console.error('Error fetching occasions:', error);
    return [];
  }
  return data || [];
}

/**
 * Fetch templates with filtering
 */
async function getTemplates({ religion, orientation, hasPhoto, category } = {}) {
  let query = supabase
    .from('templates')
    .select('*')
    .eq('is_published', true)
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
  if (hasPhoto !== undefined && hasPhoto !== '') {
    const photoBool = hasPhoto === 'true' || hasPhoto === true;
    query = query.eq('has_photo', photoBool);
  }

  const { data, error } = await query;
  if (error) {
    console.error('Error fetching templates from Supabase:', error);
    return [];
  }

  const rows = data || [];
  if (rows.length === 0) return [];

  // Batch fetch latest versions for these templates so textElements & imageElements are populated!
  const templateIds = rows.map(r => r.id);
  const versionsMap = {};
  try {
    const { data: verRows, error: verErr } = await supabase
      .from('template_versions')
      .select('template_id, version_number, config')
      .in('template_id', templateIds)
      .order('version_number', { ascending: false });

    if (!verErr && verRows) {
      for (const v of verRows) {
        if (!versionsMap[v.template_id]) {
          versionsMap[v.template_id] = v.config;
        }
      }
    }
  } catch (e) {
    console.warn('Could not batch fetch template_versions:', e.message);
  }

  return rows.map(row => {
    const cfg = versionsMap[row.id] || {};
    const textEls = Array.isArray(cfg.textElements) ? cfg.textElements : [];
    const imgEls = Array.isArray(cfg.imageElements) ? cfg.imageElements : [];

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
      photoSlotsCount: imgEls.length > 0 ? imgEls.length : (row.photo_slots_count || 0),
      masterVideoPath: row.master_video_url,
      videoUrl: row.master_video_url,
      thumbnailUrl: row.thumbnail_url,
      templateThumbUrl: row.thumbnail_url,
      sampleResultPath: row.sample_result_url,
      currentVersion: row.current_version,
      textElements: textEls,
      imageElements: imgEls
    };
  });
}

/**
 * Fetch single template along with its latest JSONB configuration from template_versions
 */
async function getTemplateById(id) {
  const { data: tmpl, error: tmplErr } = await supabase
    .from('templates')
    .select('*')
    .eq('id', id)
    .single();

  if (tmplErr || !tmpl) {
    console.error(`Template not found (${id}):`, tmplErr);
    return null;
  }

  // Get the latest version
  const { data: ver, error: verErr } = await supabase
    .from('template_versions')
    .select('*')
    .eq('template_id', id)
    .order('version_number', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (ver && ver.config) {
    return {
      ...ver.config,
      id: tmpl.id,
      title: tmpl.title,
      currentVersion: tmpl.current_version,
      templateVersionId: ver.id,
      textElements: Array.isArray(ver.config.textElements) ? ver.config.textElements : [],
      imageElements: Array.isArray(ver.config.imageElements) ? ver.config.imageElements : []
    };
  }

  return {
    id: tmpl.id,
    title: tmpl.title,
    description: tmpl.description,
    badgeText: tmpl.badge_text,
    category: tmpl.category,
    religion: tmpl.religion,
    orientation: tmpl.orientation,
    canvasWidth: tmpl.canvas_width,
    canvasHeight: tmpl.canvas_height,
    durationSeconds: tmpl.duration_seconds,
    hasPhoto: tmpl.has_photo,
    photoSlotsCount: tmpl.photo_slots_count,
    masterVideoPath: tmpl.master_video_url,
    thumbnailUrl: tmpl.thumbnail_url,
    sampleResultPath: tmpl.sample_result_url,
    textElements: [],
    imageElements: []
  };
}

/**
 * Admin creates a new template
 */
async function createTemplate(templateData) {
  const occasionId = (templateData.category || 'wedding').toLowerCase().replace(/\s+/g, '_');
  const templateId = templateData.id || `tmpl_custom_${Date.now()}`;

  const templateRow = {
    id: templateId,
    occasion_id: occasionId === 'wedding' || occasionId === 'birthday' || occasionId === 'half_saree' || occasionId === 'housewarming' || occasionId === 'engagement' || occasionId === 'ai_generated' ? occasionId : 'wedding',
    title: templateData.title || 'Untitled Royal Template',
    description: templateData.description || '',
    badge_text: templateData.badgeText || 'DYNAMIC TEMPLATE',
    category: templateData.category || 'Wedding',
    religion: templateData.religion || 'Universal',
    orientation: templateData.orientation || '16:9',
    canvas_width: templateData.canvasWidth || (templateData.orientation === '9:16' ? 1080 : 1920),
    canvas_height: templateData.canvasHeight || (templateData.orientation === '9:16' ? 1920 : 1080),
    duration_seconds: templateData.durationSeconds || 60,
    has_photo: templateData.hasPhoto !== false,
    photo_slots_count: templateData.photoSlotsCount || (templateData.imageElements ? templateData.imageElements.length : 2),
    master_video_url: templateData.masterVideoPath || templateData.videoUrl || 'assets/templates/template_01_green_screen.mp4',
    thumbnail_url: templateData.thumbnailUrl || '/assets/templates/thumb_01_green.jpg',
    sample_result_url: templateData.sampleResultPath || '',
    is_published: true,
    current_version: 1,
    updated_at: new Date().toISOString()
  };

  const { data: insertedTmpl, error: tmplErr } = await supabase
    .from('templates')
    .insert(templateRow)
    .select()
    .single();

  if (tmplErr) {
    throw new Error(`Failed to create template: ${tmplErr.message}`);
  }

  // Insert Version 1
  const versionRow = {
    template_id: templateId,
    version_number: 1,
    config: { ...templateData, id: templateId, currentVersion: 1 }
  };

  const { error: verErr } = await supabase.from('template_versions').insert(versionRow);
  if (verErr) {
    console.error('Failed to create initial template version:', verErr);
  }

  return { ...templateData, id: templateId, currentVersion: 1 };
}

/**
 * Admin updates / publishes a template version
 */
async function updateTemplate(id, templateData) {
  // Fetch current template
  const { data: current, error: curErr } = await supabase
    .from('templates')
    .select('*')
    .eq('id', id)
    .single();

  if (curErr || !current) {
    throw new Error(`Template not found: ${id}`);
  }

  const nextVersion = (current.current_version || 1) + 1;

  // Update master template row
  const updateFields = {
    title: templateData.title || current.title,
    description: templateData.description !== undefined ? templateData.description : current.description,
    badge_text: templateData.badgeText || current.badge_text,
    category: templateData.category || current.category,
    religion: templateData.religion || current.religion,
    orientation: templateData.orientation || current.orientation,
    canvas_width: templateData.canvasWidth || current.canvas_width,
    canvas_height: templateData.canvasHeight || current.canvas_height,
    duration_seconds: templateData.durationSeconds || current.duration_seconds,
    has_photo: templateData.imageElements ? (templateData.imageElements.length > 0) : (templateData.hasPhoto !== undefined ? templateData.hasPhoto : current.has_photo),
    photo_slots_count: templateData.imageElements ? templateData.imageElements.length : (templateData.photoSlotsCount !== undefined ? templateData.photoSlotsCount : current.photo_slots_count),
    is_published: templateData.isPublished !== undefined ? templateData.isPublished : true,
    current_version: nextVersion,
    updated_at: new Date().toISOString()
  };

  if (templateData.masterVideoPath || templateData.videoUrl) {
    updateFields.master_video_url = templateData.masterVideoPath || templateData.videoUrl;
  }
  if (templateData.thumbnailUrl) {
    updateFields.thumbnail_url = templateData.thumbnailUrl;
  }

  const { error: upErr } = await supabase
    .from('templates')
    .update(updateFields)
    .eq('id', id);

  if (upErr) {
    throw new Error(`Failed to update template: ${upErr.message}`);
  }

  // Insert new immutable version
  const config = {
    ...templateData,
    id,
    currentVersion: nextVersion,
    updatedAt: new Date().toISOString()
  };

  const { data: verData, error: verErr } = await supabase
    .from('template_versions')
    .insert({
      template_id: id,
      version_number: nextVersion,
      config
    })
    .select()
    .single();

  if (verErr) {
    console.error('Failed to insert new template version:', verErr);
  }

  return { ...config, templateVersionId: verData ? verData.id : null };
}

/**
 * Delete template
 */
async function deleteTemplate(id) {
  const { error } = await supabase.from('templates').delete().eq('id', id);
  if (error) {
    throw new Error(`Failed to delete template: ${error.message}`);
  }
  return true;
}

/**
 * Create a new generation job record in invitation_generations
 */
async function createGenerationRecord(jobId, {
  userId = null,
  templateId,
  templateVersionId = null,
  title,
  coupleNames,
  userData = {},
  inputPhotos = {}
}) {
  const row = {
    id: jobId,
    user_id: (userId && userId.startsWith('usr_')) ? null : userId,
    template_id: templateId,
    template_version_id: templateVersionId,
    title: title || `${coupleNames || 'Wedding'} Invitation`,
    couple_names: coupleNames || '',
    status: 'processing',
    progress: 0.05,
    current_step: 'Initializing invitation engine...',
    user_data: userData,
    input_photos: inputPhotos,
    created_at: new Date().toISOString()
  };

  const { error } = await supabase.from('invitation_generations').upsert(row, { onConflict: 'id' });
  if (error) {
    console.error('Error creating invitation_generation record:', error);
  }
  return row;
}

/**
 * Update live progress on invitation_generations
 */
async function updateGenerationProgress(jobId, progress, currentStep) {
  const { error } = await supabase
    .from('invitation_generations')
    .update({
      progress,
      current_step: currentStep
    })
    .eq('id', jobId);

  if (error) {
    console.error(`Error updating progress for job ${jobId}:`, error);
  }
}

/**
 * Complete generation job with final video URL
 */
async function completeGenerationRecord(jobId, outputVideoUrl, thumbnailUrl = '') {
  const { error } = await supabase
    .from('invitation_generations')
    .update({
      status: 'completed',
      progress: 1.0,
      current_step: 'Video ready!',
      output_video_url: outputVideoUrl,
      thumbnail_url: thumbnailUrl,
      completed_at: new Date().toISOString()
    })
    .eq('id', jobId);

  if (error) {
    console.error(`Error completing job ${jobId}:`, error);
  }
}

/**
 * Fail generation job
 */
async function failGenerationRecord(jobId, errorMessage) {
  const { error } = await supabase
    .from('invitation_generations')
    .update({
      status: 'failed',
      current_step: 'Rendering encountered an error',
      error_message: errorMessage
    })
    .eq('id', jobId);

  if (error) {
    console.error(`Error failing job ${jobId}:`, error);
  }
}

/**
 * Upload final rendered MP4 to generated-videos bucket
 */
async function uploadRenderedVideo(jobId, localFilePath, userId = 'guest') {
  if (!fs.existsSync(localFilePath)) {
    throw new Error(`Rendered video file not found: ${localFilePath}`);
  }

  const fileBuf = fs.readFileSync(localFilePath);
  const storagePath = `renders/${userId}/${jobId}_invitation.mp4`;

  console.log(`[Supabase Storage] Uploading final video -> generated-videos/${storagePath} (${(fileBuf.length / 1024 / 1024).toFixed(2)} MB)...`);

  const { data, error } = await supabase.storage
    .from('generated-videos')
    .upload(storagePath, fileBuf, {
      contentType: 'video/mp4',
      upsert: true
    });

  if (error) {
    console.error('[Supabase Storage] Error uploading final video:', error);
    return null;
  }

  const { data: urlData } = supabase.storage
    .from('generated-videos')
    .getPublicUrl(storagePath);

  console.log(`[Supabase Storage] Final video live at: ${urlData.publicUrl}`);
  return urlData.publicUrl;
}

/**
 * Download a file from Supabase Storage (e.g. user-uploads photo or master video) to a local path
 */
async function downloadStorageAsset(bucket, storagePath, localDestPath) {
  try {
    const { data, error } = await supabase.storage
      .from(bucket)
      .download(storagePath);

    if (error || !data) {
      console.warn(`[Supabase Storage] Failed to download ${bucket}/${storagePath}:`, error);
      return false;
    }

    const arrayBuffer = await data.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    fs.mkdirSync(path.dirname(localDestPath), { recursive: true });
    fs.writeFileSync(localDestPath, buffer);
    return true;
  } catch (err) {
    console.error(`Download asset error for ${storagePath}:`, err);
    return false;
  }
}

module.exports = {
  supabase,
  getOccasions,
  getTemplates,
  getTemplateById,
  createTemplate,
  updateTemplate,
  deleteTemplate,
  createGenerationRecord,
  updateGenerationProgress,
  completeGenerationRecord,
  failGenerationRecord,
  uploadRenderedVideo,
  downloadStorageAsset
};
