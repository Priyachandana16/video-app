import { createClient } from '@supabase/supabase-js';

export const SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://fyohjrfsiftpqmjhrpjm.supabase.co';
export const SUPABASE_ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5b2hqcmZzaWZ0cHFtamhycGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMTUzNDcsImV4cCI6MjEwOTc5MTM0N30.swSSU9nCfVu_Z6ztib4TuHAlBSY_Cao8q-5zIMuXzNc';

export const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export interface DirectUploadResult {
  publicUrl: string;
  filePath: string;
  bucket: string;
}

/**
 * Uploads a file directly from the browser to Supabase Storage using XMLHttpRequest.
 * Completely bypasses Vercel's 4.5MB Serverless Function payload limit (HTTP 413).
 * Provides real byte-level progress reporting (0-100%).
 */
export async function uploadDirectToSupabase(
  file: File,
  bucket: string = 'template-assets',
  subfolder?: string,
  onProgress?: (percent: number) => void
): Promise<DirectUploadResult> {
  const isAudio = file.type.startsWith('audio/') || !!file.name.match(/\.(mp3|wav|m4a|aac|ogg)$/i);
  const isImage = file.type.startsWith('image/') || !!file.name.match(/\.(png|jpe?g|webp|gif|svg)$/i);
  const folder = subfolder || (isAudio ? 'audio' : isImage ? 'images' : 'videos');
  const sanitizedName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const filePath = `${folder}/${Date.now()}_${sanitizedName}`;
  const contentType = file.type || (isAudio ? 'audio/mpeg' : isImage ? 'image/jpeg' : 'video/mp4');

  const uploadToBucket = (targetBucket: string): Promise<DirectUploadResult> => {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      const targetUrl = `${SUPABASE_URL}/storage/v1/object/${targetBucket}/${filePath}`;

      xhr.open('POST', targetUrl, true);
      xhr.setRequestHeader('apikey', SUPABASE_ANON_KEY);
      xhr.setRequestHeader('Authorization', `Bearer ${SUPABASE_ANON_KEY}`);
      xhr.setRequestHeader('Content-Type', contentType);
      xhr.setRequestHeader('x-upsert', 'true');

      if (xhr.upload && onProgress) {
        xhr.upload.onprogress = (evt) => {
          if (evt.lengthComputable && evt.total > 0) {
            const percent = Math.min(99, Math.round((evt.loaded / evt.total) * 100));
            onProgress(percent);
          }
        };
      }

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${targetBucket}/${filePath}`;
          if (onProgress) onProgress(100);
          resolve({ publicUrl, filePath, bucket: targetBucket });
        } else {
          try {
            const errData = JSON.parse(xhr.responseText);
            reject(new Error(errData.message || errData.error || `Upload failed with status ${xhr.status}`));
          } catch {
            reject(new Error(xhr.responseText || `Upload failed with status ${xhr.status}`));
          }
        }
      };

      xhr.onerror = () => {
        reject(new Error('Network error during upload to Supabase Storage. Please check internet connection.'));
      };

      xhr.send(file);
    });
  };

  try {
    return await uploadToBucket(bucket);
  } catch (err: any) {
    // If primary bucket fails, try fallback bucket
    const fallbackBucket = bucket === 'template-assets' ? 'invitation-templates' : 'template-assets';
    console.warn(`Upload to ${bucket} failed:`, err?.message, `Retrying with ${fallbackBucket}...`);
    return await uploadToBucket(fallbackBucket);
  }
}

