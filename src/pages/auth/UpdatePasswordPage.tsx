import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  AlertTriangle,
  BarChart2,
  CheckCircle,
  Eye,
  EyeOff,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { ROUTES } from '@/constants/routes'
import { toast } from 'sonner'

const schema = z
  .object({
    password: z.string().min(6, 'Mínimo 6 caracteres'),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'As senhas não conferem',
    path: ['confirmPassword'],
  })

type FormData = z.infer<typeof schema>

const TOKEN_VALIDATION_TIMEOUT_MS = 8000

function getAuthErrorFromUrl(): string | null {
  const hashParams = new URLSearchParams(
    window.location.hash.startsWith('#')
      ? window.location.hash.slice(1)
      : window.location.hash,
  )

  const searchParams = new URLSearchParams(window.location.search)

  const errorCode =
    hashParams.get('error_code') ??
    searchParams.get('error_code')

  const error =
    hashParams.get('error') ??
    searchParams.get('error')

  if (errorCode === 'otp_expired') {
    return 'Este link de acesso expirou ou já foi utilizado.'
  }

  if (error === 'access_denied') {
    return 'Este link de acesso não é mais válido.'
  }

  const errorDescription =
    hashParams.get('error_description') ??
    searchParams.get('error_description')

  if (errorDescription) {
    return 'Não foi possível validar este link de acesso.'
  }

  return null
}

export default function UpdatePasswordPage() {
  const navigate = useNavigate()

  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)
  const [showPw, setShowPw] = useState(false)
  const [showPw2, setShowPw2] = useState(false)
  const [ready, setReady] = useState(false)
  const [tokenError, setTokenError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  useEffect(() => {
    let active = true

    const urlError = getAuthErrorFromUrl()

    if (urlError) {
      setTokenError(urlError)
      return undefined
    }

    const timeoutId = window.setTimeout(() => {
      if (!active) return

      setTokenError(
        'Não foi possível validar este link. Ele pode ter expirado ou já ter sido utilizado.',
      )
    }, TOKEN_VALIDATION_TIMEOUT_MS)

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event) => {
      if (!active) return

      if (event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') {
        window.clearTimeout(timeoutId)
        setReady(true)
        setTokenError(null)
      }
    })

    void supabase.auth
      .getSession()
      .then(({ data: { session }, error }) => {
        if (!active) return

        if (error) {
          window.clearTimeout(timeoutId)
          setTokenError(
            'Não foi possível validar este link de acesso.',
          )
          return
        }

        if (session) {
          window.clearTimeout(timeoutId)
          setReady(true)
          setTokenError(null)
        }
      })
      .catch(() => {
        if (!active) return

        window.clearTimeout(timeoutId)
        setTokenError(
          'Não foi possível validar este link de acesso.',
        )
      })

    return () => {
      active = false
      window.clearTimeout(timeoutId)
      subscription.unsubscribe()
    }
  }, [])

  const onSubmit = async (data: FormData) => {
    setLoading(true)

    const { error } = await supabase.auth.updateUser({
      password: data.password,
    })

    if (error) {
      toast.error(error.message)
      setLoading(false)
      return
    }

    setDone(true)

    window.setTimeout(() => {
      navigate(ROUTES.HOME)
    }, 2000)
  }

  if (tokenError && !ready) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-brand-950 via-brand-900 to-brand-800 flex items-center justify-center px-4">
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-brand-700 mb-4 shadow-lg">
              <BarChart2 className="h-7 w-7 text-white" />
            </div>

            <h1 className="text-2xl font-bold text-white">
              RF Performance Comercial
            </h1>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl p-8 text-center">
            <div className="w-14 h-14 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <AlertTriangle className="h-7 w-7 text-amber-600" />
            </div>

            <h2 className="text-lg font-semibold text-gray-900 mb-2">
              Link de acesso inválido
            </h2>

            <p className="text-sm text-gray-600 mb-6">
              {tokenError}
            </p>

            <p className="text-sm text-gray-600 mb-6">
              Acesse o RF Performance pelo endereço oficial. Se você
              ainda não definiu sua senha, solicite um novo convite ao
              seu supervisor.
            </p>

            <a
              href="https://performance.epsacore.com.br"
              className="btn-primary inline-flex w-full items-center justify-center py-2.5"
            >
              Ir para o RF Performance
            </a>
          </div>
        </div>
      </div>
    )
  }

  if (!ready) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-brand-950 via-brand-900 to-brand-800 flex items-center justify-center">
        <div className="text-white text-center">
          <div className="animate-spin rounded-full h-10 w-10 border-2 border-white border-t-transparent mx-auto mb-3" />

          <p>Validando token...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-brand-950 via-brand-900 to-brand-800 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-brand-700 mb-4 shadow-lg">
            <BarChart2 className="h-7 w-7 text-white" />
          </div>

          <h1 className="text-2xl font-bold text-white">
            RF Performance Comercial
          </h1>
        </div>

        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {done ? (
            <div className="text-center">
              <div className="w-14 h-14 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-7 w-7 text-green-600" />
              </div>

              <h2 className="text-lg font-semibold text-gray-900 mb-2">
                Senha atualizada
              </h2>

              <p className="text-sm text-gray-600">
                Redirecionando para o sistema...
              </p>
            </div>
          ) : (
            <>
              <h2 className="text-lg font-semibold text-gray-900 mb-2">
                Definir nova senha
              </h2>

              <p className="text-sm text-gray-600 mb-6">
                Escolha uma senha segura com no mínimo 6 caracteres.
              </p>

              <form
                onSubmit={handleSubmit(onSubmit)}
                className="space-y-4"
              >
                <div>
                  <label className="form-label">
                    Nova senha
                  </label>

                  <div className="relative">
                    <input
                      {...register('password')}
                      type={showPw ? 'text' : 'password'}
                      placeholder="••••••••"
                      className="form-input pr-10"
                    />

                    <button
                      type="button"
                      onClick={() => setShowPw(!showPw)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      aria-label={
                        showPw
                          ? 'Ocultar nova senha'
                          : 'Mostrar nova senha'
                      }
                    >
                      {showPw ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>

                  {errors.password && (
                    <p className="form-error">
                      {errors.password.message}
                    </p>
                  )}
                </div>

                <div>
                  <label className="form-label">
                    Confirmar senha
                  </label>

                  <div className="relative">
                    <input
                      {...register('confirmPassword')}
                      type={showPw2 ? 'text' : 'password'}
                      placeholder="••••••••"
                      className="form-input pr-10"
                    />

                    <button
                      type="button"
                      onClick={() => setShowPw2(!showPw2)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      aria-label={
                        showPw2
                          ? 'Ocultar confirmação de senha'
                          : 'Mostrar confirmação de senha'
                      }
                    >
                      {showPw2 ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>

                  {errors.confirmPassword && (
                    <p className="form-error">
                      {errors.confirmPassword.message}
                    </p>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="btn-primary w-full py-2.5 mt-2"
                >
                  {loading ? 'Salvando...' : 'Salvar nova senha'}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
