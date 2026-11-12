import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://fyohjrfsiftpqmjhrpjm.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5b2hqcmZzaWZ0cHFtamhycGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMTUzNDcsImV4cCI6MjEwOTc5MTM0N30.swSSU9nCfVu_Z6ztib4TuHAlBSY_Cao8q-5zIMuXzNc';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

