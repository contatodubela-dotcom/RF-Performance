import { Link } from 'react-router-dom'
import { ROUTES } from '@/constants/routes'

export default function NotFoundPage() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div className="text-center">
        <p className="text-6xl font-black text-brand-800 mb-4">404</p>
        <h1 className="text-xl font-semibold text-gray-900 mb-2">Página não encontrada</h1>
        <p className="text-sm text-gray-500 mb-8">
          A página que você está procurando não existe ou foi movida.
        </p>
        <Link to={ROUTES.HOME} className="btn-primary">
          Voltar ao início
        </Link>
      </div>
    </div>
  )
}
