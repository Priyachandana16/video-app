import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';
import fs from 'fs';
import path from 'path';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const assets: Array<{
      name: string;
      filePath: string;
      url: string;
      type: 'video' | 'image';
      sizeBytes: number;
    }> = [];

    // 1. Fetch from Supabase Storage
    try {
      const buckets = ['template-assets', 'invitation-templates'];
      for (const b of buckets) {
        const { data: files } = await supabase.storage.from(b).list('videos', { limit: 100 });
        if (files) {
          for (const f of files) {
            if (f.name && !f.name.startsWith('.')) {
              const fullPath = `videos/${f.name}`;
              const { data: pubData } = supabase.storage.from(b).getPublicUrl(fullPath);
              assets.push({
                name: f.name,
                filePath: pubData.publicUrl,
                url: pubData.publicUrl,
                type: 'video',
                sizeBytes: f.metadata?.size || 0,
              });
            }
          }
        }
      }
    } catch (sbErr) {
      console.warn('Could not list from Supabase storage:', sbErr);
    }

    // 2. Also check local public and assets directories
    const candidateDirs = [
      path.join(process.cwd(), 'public', 'assets', 'templates'),
      path.join(process.cwd(), '..', 'assets', 'templates'),
      path.join(process.cwd(), 'public', 'assets'),
    ];

    for (const cDir of candidateDirs) {
      if (fs.existsSync(cDir)) {
        try {
          const fileNames = fs.readdirSync(cDir);
          for (const fn of fileNames) {
            const ext = path.extname(fn).toLowerCase();
            if (['.mp4', '.mov', '.webm', '.jpg', '.jpeg', '.png'].includes(ext)) {
              const fullPath = path.join(cDir, fn);
              const stats = fs.statSync(fullPath);
              const isVideo = ['.mp4', '.mov', '.webm'].includes(ext);
              const webPath = `/assets/templates/${fn}`;
              // Avoid duplicates
              if (!assets.some((a) => a.name === fn)) {
                assets.push({
                  name: fn,
                  filePath: webPath,
                  url: webPath,
                  type: isVideo ? 'video' : 'image',
                  sizeBytes: stats.size,
                });
              }
            }
          }
        } catch (e) {
          // ignore directory read errors
        }
      }
    }

    return NextResponse.json({ success: true, count: assets.length, assets });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

