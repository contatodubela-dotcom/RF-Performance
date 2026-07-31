import type { ReactNode } from 'react'
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
} from 'react-router-dom'

import AuthorizedRoute from '@/components/features/auth/AuthorizedRoute'
import ProtectedRoute from '@/components/features/auth/ProtectedRoute'
import AppLayout from '@/components/layout/AppLayout'
import { ROUTES } from '@/constants/routes'
import { AuthProvider } from '@/contexts/AuthContext'

// Auth pages
import LoginPage from '@/pages/auth/LoginPage'
import RecoverPasswordPage from '@/pages/auth/RecoverPasswordPage'
import UpdatePasswordPage from '@/pages/auth/UpdatePasswordPage'

// App pages
import ActionsPage from '@/pages/app/ActionsPage'
import FeedbacksPage from '@/pages/app/FeedbacksPage'
import GoalsPage from '@/pages/app/GoalsPage'
import HomePage from '@/pages/app/HomePage'
import MeetingsPage from '@/pages/app/MeetingsPage'
import OperationsPage from '@/pages/app/OperationsPage'
import OrganizationsPage from '@/pages/app/OrganizationsPage'
import PlaceholderPage from '@/pages/app/PlaceholderPage'
import Plan90DaysPage from '@/pages/app/Plan90DaysPage'
import SalesLocationsPage from '@/pages/app/SalesLocationsPage'
import SettingsPage from '@/pages/app/SettingsPage'
import TeamsPage from '@/pages/app/TeamsPage'
import TrainingPage from '@/pages/app/TrainingPage'
import UsersPage from '@/pages/app/UsersPage'
import NotFoundPage from '@/pages/NotFoundPage'

function authorized(route: string, element: ReactNode) {
  return (
    <AuthorizedRoute route={route}>
      {element}
    </AuthorizedRoute>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Rotas públicas */}
          <Route
            path={ROUTES.LOGIN}
            element={<LoginPage />}
          />

          <Route
            path={ROUTES.RECOVER_PASSWORD}
            element={<RecoverPasswordPage />}
          />

          <Route
            path={ROUTES.UPDATE_PASSWORD}
            element={<UpdatePasswordPage />}
          />

          {/* Rotas autenticadas */}
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route
                path={ROUTES.APP}
                element={
                  <Navigate
                    to={ROUTES.HOME}
                    replace
                  />
                }
              />

              {/* Gestão */}
              <Route
                path={ROUTES.HOME}
                element={authorized(
                  ROUTES.HOME,
                  <HomePage />,
                )}
              />

              <Route
                path={ROUTES.PLAN_90_DAYS}
                element={authorized(
                  ROUTES.PLAN_90_DAYS,
                  <Plan90DaysPage />,
                )}
              />

              <Route
                path={ROUTES.GOALS}
                element={authorized(
                  ROUTES.GOALS,
                  <GoalsPage />,
                )}
              />

              <Route
                path={ROUTES.RESULTS}
                element={authorized(
                  ROUTES.RESULTS,
                  <PlaceholderPage
                    title="Resultados"
                    description="Acompanhamento de cotas vendidas, conversão e desempenho comercial em tempo real."
                    icon="TrendingUp"
                  />,
                )}
              />

              <Route
                path={ROUTES.ACTIONS}
                element={authorized(
                  ROUTES.ACTIONS,
                  <ActionsPage />,
                )}
              />

              <Route
                path={ROUTES.MEETINGS}
                element={authorized(
                  ROUTES.MEETINGS,
                  <MeetingsPage />,
                )}
              />

              {/* Desenvolvimento */}
              <Route
                path={ROUTES.TRAINING}
                element={authorized(
                  ROUTES.TRAINING,
                  <TrainingPage />,
                )}
              />

              <Route
                path={ROUTES.EVALUATIONS}
                element={authorized(
                  ROUTES.EVALUATIONS,
                  <PlaceholderPage
                    title="Avaliações"
                    description="Avaliações de desempenho individual, comportamental e técnica por período."
                    icon="ClipboardCheck"
                  />,
                )}
              />

              <Route
                path={ROUTES.FEEDBACKS}
                element={authorized(
                  ROUTES.FEEDBACKS,
                  <FeedbacksPage />,
                )}
              />

              {/* Análise */}
              <Route
                path={ROUTES.REPORTS}
                element={authorized(
                  ROUTES.REPORTS,
                  <PlaceholderPage
                    title="Relatórios"
                    description="Painéis analíticos e relatórios gerenciais consolidados da operação comercial."
                    icon="FileText"
                  />,
                )}
              />

              {/* Administração */}
              <Route
                path={ROUTES.ORGANIZATIONS}
                element={authorized(
                  ROUTES.ORGANIZATIONS,
                  <OrganizationsPage />,
                )}
              />

              <Route
                path={ROUTES.OPERATIONS}
                element={authorized(
                  ROUTES.OPERATIONS,
                  <OperationsPage />,
                )}
              />

              <Route
                path={ROUTES.SALES_LOCATIONS}
                element={authorized(
                  ROUTES.SALES_LOCATIONS,
                  <SalesLocationsPage />,
                )}
              />

              <Route
                path={ROUTES.TEAMS}
                element={authorized(
                  ROUTES.TEAMS,
                  <TeamsPage />,
                )}
              />

              <Route
                path={ROUTES.USERS}
                element={authorized(
                  ROUTES.USERS,
                  <UsersPage />,
                )}
              />

              <Route
                path={ROUTES.SETTINGS}
                element={authorized(
                  ROUTES.SETTINGS,
                  <SettingsPage />,
                )}
              />
            </Route>
          </Route>

          {/* Redirecionamento da raiz */}
          <Route
            path="/"
            element={
              <Navigate
                to={ROUTES.APP}
                replace
              />
            }
          />

          {/* Página não encontrada */}
          <Route
            path="*"
            element={<NotFoundPage />}
          />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}