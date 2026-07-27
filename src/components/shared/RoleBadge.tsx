import { cn } from '@/lib/utils'
import { ROLE_LABELS } from '@/constants/roles'

interface RoleBadgeProps {
  role: string
  className?: string
}

const ROLE_STYLES: Record<string, string> = {
  platform_admin: 'bg-purple-100 text-purple-800',
  director: 'bg-brand-100 text-brand-800',
  supervisor: 'bg-blue-100 text-blue-800',
  salesperson: 'bg-orange-100 text-orange-800',
}

export default function RoleBadge({ role, className }: RoleBadgeProps) {
  const style = ROLE_STYLES[role] ?? 'bg-gray-100 text-gray-600'
  const label = ROLE_LABELS[role] ?? role

  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', style, className)}>
      {label}
    </span>
  )
}
