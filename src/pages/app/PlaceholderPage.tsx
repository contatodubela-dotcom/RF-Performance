import { Calendar, Target, TrendingUp, Zap, Users2, BookOpen, ClipboardCheck, MessageSquare, FileText } from 'lucide-react'

const ICONS: Record<string, React.ElementType> = {
  Calendar, Target, TrendingUp, Zap, Users2, BookOpen, ClipboardCheck, MessageSquare, FileText,
}

interface PlaceholderPageProps {
  title: string
  description: string
  icon?: string
}

export default function PlaceholderPage({ title, description, icon = 'Calendar' }: PlaceholderPageProps) {
  const Icon = ICONS[icon] ?? Calendar

  return (
    <div className="page-container">
      <div className="max-w-lg mx-auto text-center py-20">
        <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center mx-auto mb-5">
          <Icon className="h-8 w-8 text-gray-400" />
        </div>
        <h1 className="text-xl font-bold text-gray-900 mb-2">{title}</h1>
        <p className="text-sm text-gray-600 mb-6">{description}</p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-yellow-50 border border-yellow-200 text-yellow-800 text-sm font-medium">
          <span>⏳</span>
          <span>Módulo em preparação — Fase 2</span>
        </div>
        <p className="mt-6 text-xs text-gray-400">
          Este módulo será implementado após a conclusão e validação da Fase 1.
          Nenhum dado fictício é exibido aqui.
        </p>
      </div>
    </div>
  )
}
