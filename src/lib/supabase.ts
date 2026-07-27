import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabasePublishableKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabasePublishableKey) {
  throw new Error(
    '[Supabase] VITE_SUPABASE_URL e ' +
      'VITE_SUPABASE_PUBLISHABLE_KEY são obrigatórias.',
  )
}

// Somente a chave publicável é utilizada no frontend.
// Nunca exponha service_role, secret key ou senha do banco.
export const supabase = createClient(
  supabaseUrl,
  supabasePublishableKey,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      flowType: 'pkce',
    },
  },
)
