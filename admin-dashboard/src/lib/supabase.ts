import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://fyohjrfsiftpqmjhrpjm.supabase.co';
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5b2hqcmZzaWZ0cHFtamhycGptIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5NDIxNTM0NywiZXhwIjoyMTA5NzkxMzQ3fQ.yvx6AU-D9u0vopsMPaEUnIo3A4EZxPrboTlMSI7mPIA';

export const supabase = createClient(supabaseUrl, supabaseKey);
