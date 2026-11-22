import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File | null;
    const bucket = (formData.get('bucket') as string) || 'template-assets';

    if (!file) {
      return NextResponse.json({ error: 'No file uploaded' }, { status: 400 });
    }

    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    // Sanitize file name
    const sanitizedName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const isAudio = file.type.startsWith('audio/') || !!file.name.match(/\.(mp3|wav|m4a|aac|ogg)$/i);
    const isImage = file.type.startsWith('image/') || !!file.name.match(/\.(png|jpe?g|webp|gif|svg)$/i);
    const subfolder = isAudio ? 'audio' : isImage ? 'images' : 'videos';
    const filePath = `${subfolder}/${Date.now()}_${sanitizedName}`;
    const contentType = file.type || (isAudio ? 'audio/mpeg' : isImage ? 'image/jpeg' : 'video/mp4');

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(filePath, buffer, {
        contentType,
        upsert: true,
      });

    if (uploadError) {
      // If template-assets bucket failed, try invitation-templates bucket
      console.warn(`Upload to ${bucket} failed:`, uploadError.message, 'trying fallback bucket...');
      const fallbackBucket = bucket === 'template-assets' ? 'invitation-templates' : 'template-assets';
      const { data: fbData, error: fbErr } = await supabase.storage
        .from(fallbackBucket)
        .upload(filePath, buffer, {
          contentType,
          upsert: true,
        });

      if (fbErr) {
        return NextResponse.json({ error: fbErr.message }, { status: 500 });
      }

      const { data: pubData } = supabase.storage.from(fallbackBucket).getPublicUrl(filePath);
      return NextResponse.json({
        success: true,
        publicUrl: pubData.publicUrl,
        filePath,
        fileName: file.name,
        sizeBytes: file.size,
        bucket: fallbackBucket,
      });
    }

    const { data: pubData } = supabase.storage.from(bucket).getPublicUrl(filePath);

    return NextResponse.json({
      success: true,
      publicUrl: pubData.publicUrl,
      filePath,
      fileName: file.name,
      sizeBytes: file.size,
      bucket,
    });
  } catch (err: any) {
    console.error('File upload error:', err);
    return NextResponse.json({ error: err.message || 'Internal upload error' }, { status: 500 });
  }
}

