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

// Aplicação web cliente: o fluxo implícito permite aceitar convites
// administrativos em um navegador diferente daquele que iniciou o envio.
// Nunca exponha secret key, service_role ou senha do banco no frontend.
export const supabase = createClient(
  supabaseUrl,
  supabasePublishableKey,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      flowType: 'implicit',
    },
  },
)
