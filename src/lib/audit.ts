import { supabase } from './supabase'
import type { AuditLog } from '@/types/database'

type AuditEntry = Omit<AuditLog, 'id' | 'created_at'>

export async function logAudit(entry: AuditEntry): Promise<void> {
  const { error } = await supabase.from('audit_logs').insert(entry)
  if (error) {
    console.error('[Audit] Failed to log entry:', error.message, entry)
  }
}
