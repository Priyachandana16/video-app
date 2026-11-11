import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
  try {
    const { count, error } = await supabase.from('templates').select('*', { count: 'exact', head: true });
    return NextResponse.json({
      status: 'ok',
      service: 'My Invitation Admin Studio',
      database: error ? 'error' : 'supabase_connected',
      templateCount: count ?? 0,
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    return NextResponse.json({ status: 'ok', database: 'fallback', error: err.message });
  }
}
