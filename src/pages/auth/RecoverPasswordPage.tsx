import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { BarChart2, ArrowLeft, CheckCircle } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { ROUTES } from '@/constants/routes'
import { toast } from 'sonner'

const schema = z.object({
  email: z.string().email('E-mail inválido'),
})

type FormData = z.infer<typeof schema>

export default function RecoverPasswordPage() {
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    const { error } = await supabase.auth.resetPasswordForEmail(data.email, {
      redirectTo: `${window.location.origin}${ROUTES.UPDATE_PASSWORD}`,
    })
    if (error) {
      toast.error(error.message)
      setLoading(false)
      return
    }
    setSent(true)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-brand-950 via-brand-900 to-brand-800 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-brand-700 mb-4 shadow-lg">
            <BarChart2 className="h-7 w-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">RF Performance Comercial</h1>
        </div>

        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {sent ? (
            <div className="text-center">
              <div className="w-14 h-14 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-7 w-7 text-green-600" />
              </div>
              <h2 className="text-lg font-semibold text-gray-900 mb-2">E-mail enviado</h2>
              <p className="text-sm text-gray-600 mb-6">
                Se o e-mail estiver cadastrado, você receberá as instruções para redefinir sua senha.
              </p>
              <Link to={ROUTES.LOGIN} className="btn-primary w-full">
                Voltar ao Login
              </Link>
            </div>
          ) : (
            <>
              <h2 className="text-lg font-semibold text-gray-900 mb-2">Recuperar senha</h2>
              <p className="text-sm text-gray-600 mb-6">
                Informe seu e-mail e enviaremos as instruções de recuperação.
              </p>

              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="form-label">E-mail</label>
                  <input
                    {...register('email')}
                    type="email"
                    autoComplete="email"
                    placeholder="seu@email.com"
                    className="form-input"
                  />
                  {errors.email && <p className="form-error">{errors.email.message}</p>}
                </div>

                <button type="submit" disabled={loading} className="btn-primary w-full py-2.5">
                  {loading ? 'Enviando...' : 'Enviar instruções'}
                </button>
              </form>

              <Link
                to={ROUTES.LOGIN}
                className="mt-4 flex items-center justify-center gap-2 text-sm text-gray-500 hover:text-gray-700"
              >
                <ArrowLeft className="h-4 w-4" />
                Voltar ao login
              </Link>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
