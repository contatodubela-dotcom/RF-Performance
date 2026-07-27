import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from '@/contexts/AuthContext'
import { Suspense, lazy } from 'react'
import ProtectedRoute from '@/components/features/auth/ProtectedRoute'
import AppLayout from '@/components/layout/AppLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { ROUTES } from '@/constants/routes'

// Auth pages
import LoginPage from '@/pages/auth/LoginPage'
import RecoverPasswordPage from '@/pages/auth/RecoverPasswordPage'
import UpdatePasswordPage from '@/pages/auth/UpdatePasswordPage'

// App pages
import HomePage from '@/pages/app/HomePage'
import OrganizationsPage from '@/pages/app/OrganizationsPage'
import OperationsPage from '@/pages/app/OperationsPage'
import SalesLocationsPage from '@/pages/app/SalesLocationsPage'
import TeamsPage from '@/pages/app/TeamsPage'
import UsersPage from '@/pages/app/UsersPage'
import SettingsPage from '@/pages/app/SettingsPage'
import PlaceholderPage from '@/pages/app/PlaceholderPage'
import NotFoundPage from '@/pages/NotFoundPage'

function AppFallback() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <LoadingSpinner size="lg" message="Carregando..." />
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* ── Public Routes ── */}
          <Route path={ROUTES.LOGIN} element={<LoginPage />} />
          <Route path={ROUTES.RECOVER_PASSWORD} element={<RecoverPasswordPage />} />
          <Route path={ROUTES.UPDATE_PASSWORD} element={<UpdatePasswordPage />} />

          {/* ── Protected Routes ── */}
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              {/* Redirect /app → /app/inicio */}
              <Route path={ROUTES.APP} element={<Navigate to={ROUTES.HOME} replace />} />

              {/* Gestão */}
              <Route path={ROUTES.HOME} element={<HomePage />} />
              <Route path={ROUTES.PLAN_90_DAYS} element={
                <PlaceholderPage title="Plano de 90 Dias" description="Planejamento estratégico da operação comercial em ciclos de 90 dias, com metas, indicadores e ações programadas." icon="Calendar" />
              } />
              <Route path={ROUTES.GOALS} element={
                <PlaceholderPage title="Metas" description="Definição e acompanhamento de metas individuais, por equipe e por PDV — cotas, conversão e receita." icon="Target" />
              } />
              <Route path={ROUTES.RESULTS} element={
                <PlaceholderPage title="Resultados" description="Acompanhamento de cotas vendidas, conversão e desempenho comercial em tempo real." icon="TrendingUp" />
              } />
              <Route path={ROUTES.ACTIONS} element={
                <PlaceholderPage title="Ações" description="Planos de ação corretivos e preventivos para melhoria de desempenho individual e de equipe." icon="Zap" />
              } />
              <Route path={ROUTES.MEETINGS} element={
                <PlaceholderPage title="Reuniões" description="Registro e acompanhamento de reuniões de equipe, feedbacks coletivos e decisões estratégicas." icon="Users2" />
              } />

              {/* Desenvolvimento */}
              <Route path={ROUTES.TRAINING} element={
                <PlaceholderPage title="Treinamentos" description="Trilhas de desenvolvimento, capacitações, módulos e controle de participação por colaborador." icon="BookOpen" />
              } />
              <Route path={ROUTES.EVALUATIONS} element={
                <PlaceholderPage title="Avaliações" description="Avaliações de desempenho individual, comportamental e técnica por período." icon="ClipboardCheck" />
              } />
              <Route path={ROUTES.FEEDBACKS} element={
                <PlaceholderPage title="Feedbacks" description="Registro estruturado de feedbacks entre líderes e colaboradores — pontual e de período." icon="MessageSquare" />
              } />

              {/* Análise */}
              <Route path={ROUTES.REPORTS} element={
                <PlaceholderPage title="Relatórios" description="Painéis analíticos e relatórios gerenciais consolidados da operação comercial." icon="FileText" />
              } />

              {/* Administração */}
              <Route path={ROUTES.ORGANIZATIONS} element={<OrganizationsPage />} />
              <Route path={ROUTES.OPERATIONS} element={<OperationsPage />} />
              <Route path={ROUTES.SALES_LOCATIONS} element={<SalesLocationsPage />} />
              <Route path={ROUTES.TEAMS} element={<TeamsPage />} />
              <Route path={ROUTES.USERS} element={<UsersPage />} />
              <Route path={ROUTES.SETTINGS} element={<SettingsPage />} />
            </Route>
          </Route>

          {/* Redirect root */}
          <Route path="/" element={<Navigate to={ROUTES.APP} replace />} />

          {/* 404 */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
