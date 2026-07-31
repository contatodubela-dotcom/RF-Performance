import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
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
  const { currentRole } = useAuth()
  const location = useLocation()

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