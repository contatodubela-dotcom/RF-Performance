// Date, currency and number formatters — pt-BR / America/Sao_Paulo

const LOCALE = 'pt-BR'
const TIMEZONE = 'America/Sao_Paulo'

export function formatDate(value: string | null | undefined): string {
  if (!value) return '—'
  return new Intl.DateTimeFormat(LOCALE, {
    day: '2-digit', month: '2-digit', year: 'numeric', timeZone: TIMEZONE,
  }).format(new Date(value))
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '—'
  return new Intl.DateTimeFormat(LOCALE, {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit', timeZone: TIMEZONE,
  }).format(new Date(value))
}

export function formatRelativeDate(value: string | null | undefined): string {
  if (!value) return '—'
  const date = new Date(value)
  const diffDays = Math.floor((Date.now() - date.getTime()) / 86_400_000)
  if (diffDays === 0) return 'Hoje'
  if (diffDays === 1) return 'Ontem'
  if (diffDays < 7) return `${diffDays} dias atrás`
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} sem. atrás`
  if (diffDays < 365) return `${Math.floor(diffDays / 30)} meses atrás`
  return `${Math.floor(diffDays / 365)} anos atrás`
}

export function formatCurrency(value: number | null | undefined): string {
  if (value == null) return 'R$ —'
  return new Intl.NumberFormat(LOCALE, { style: 'currency', currency: 'BRL' }).format(value)
}

export function formatNumber(value: number | null | undefined): string {
  if (value == null) return '—'
  return new Intl.NumberFormat(LOCALE).format(value)
}

export function formatPhone(phone: string | null | undefined): string {
  if (!phone) return '—'
  const d = phone.replace(/\D/g, '')
  if (d.length === 11) return `(${d.slice(0,2)}) ${d.slice(2,7)}-${d.slice(7)}`
  if (d.length === 10) return `(${d.slice(0,2)}) ${d.slice(2,6)}-${d.slice(6)}`
  return phone
}
