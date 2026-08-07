import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { useAuth } from '@/contexts/AuthContext'
import { ROUTES } from '@/constants/routes'
import { canAccessRoute } from '@/constants/permissions'

interface AuthorizedRouteProps {
  route: string
  children: ReactNode
}

export default function AuthorizedRoute({
  route,
  children,
}: AuthorizedRouteProps) {
  const { currentRole, loading } = useAuth()
  const location = useLocation()

  // A sessão pode existir alguns instantes antes de profile/membership terminarem
  // de carregar. Nesse intervalo currentRole ainda é null. Redirecionar para HOME
  // aqui faria a própria rota HOME redirecionar para ela mesma em loop.
  if (loading || !currentRole) {
    return (
      <div className="min-h-[40vh] flex items-center justify-center">
        <LoadingSpinner size="lg" message="Verificando permissões..." />
      </div>
    )
  }

  if (!canAccessRoute(currentRole, route)) {
    return (
      <Navigate
        to={ROUTES.HOME}
        replace
        state={{
          accessDenied: true,
          deniedRoute: location.pathname,
        }}
      />
    )
  }

  return <>{children}</>
}
