import { cn } from '@/lib/utils'
import { STATUS_LABELS } from '@/constants/roles'

interface StatusBadgeProps {
  status: string
  className?: string
}

const STATUS_STYLES: Record<string, string> = {
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-yellow-100 text-yellow-800',
  archived: 'bg-gray-100 text-gray-600',
}

export default function StatusBadge({ status, className }: StatusBadgeProps) {
  const style = STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-600'
  const label = STATUS_LABELS[status] ?? status

  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', style, className)}>
      {label}
    </span>
  )
}
