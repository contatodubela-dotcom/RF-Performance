import { useEffect, useState } from 'react'
import { Download } from 'lucide-react'

type InstallPromptVariant = 'login' | 'sidebar'

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{
    outcome: 'accepted' | 'dismissed'
    platform: string
  }>
}

interface PwaInstallPromptProps {
  variant?: InstallPromptVariant
}

function isIosDevice() {
  const userAgent = window.navigator.userAgent.toLowerCase()

  return (
    /iphone|ipad|ipod/.test(userAgent) ||
    (
      window.navigator.platform === 'MacIntel' &&
      window.navigator.maxTouchPoints > 1
    )
  )
}

function isAndroidDevice() {
  return /android/i.test(window.navigator.userAgent)
}

function isStandaloneMode() {
  const navigatorWithStandalone = window.navigator as Navigator & {
    standalone?: boolean
  }

  return (
    window.matchMedia('(display-mode: standalone)').matches ||
    navigatorWithStandalone.standalone === true
  )
}

export default function PwaInstallPrompt({
  variant = 'login',
}: PwaInstallPromptProps) {
  const [deferredPrompt, setDeferredPrompt] =
    useState<BeforeInstallPromptEvent | null>(null)

  const [isMobile, setIsMobile] = useState(false)
  const [isIos, setIsIos] = useState(false)
  const [isAndroid, setIsAndroid] = useState(false)
  const [isInstalled, setIsInstalled] = useState(false)
  const [showInstructions, setShowInstructions] = useState(false)

    useEffect(() => {
    const ios = isIosDevice()
    const android = isAndroidDevice()
    const mobileViewport = window.matchMedia('(max-width: 1023px)')

    const updateMobileState = () => {
      setIsMobile(
        ios ||
        android ||
        mobileViewport.matches,
      )
    }

    setIsIos(ios)
    setIsAndroid(android)
    updateMobileState()
    setIsInstalled(isStandaloneMode())

    const handleBeforeInstallPrompt = (event: Event) => {
      event.preventDefault()

      setDeferredPrompt(
        event as BeforeInstallPromptEvent,
      )
    }

    const handleAppInstalled = () => {
      setIsInstalled(true)
      setDeferredPrompt(null)
      setShowInstructions(false)
    }

    window.addEventListener(
      'beforeinstallprompt',
      handleBeforeInstallPrompt,
    )

    window.addEventListener(
      'appinstalled',
      handleAppInstalled,
    )

    mobileViewport.addEventListener(
      'change',
      updateMobileState,
    )

    return () => {
      window.removeEventListener(
        'beforeinstallprompt',
        handleBeforeInstallPrompt,
      )

      window.removeEventListener(
        'appinstalled',
        handleAppInstalled,
      )

      mobileViewport.removeEventListener(
        'change',
        updateMobileState,
      )
    }
  }, [])

  const handleInstall = async () => {
    if (deferredPrompt) {
      await deferredPrompt.prompt()

      const choice = await deferredPrompt.userChoice

      if (choice.outcome === 'accepted') {
        setIsInstalled(true)
      }

      setDeferredPrompt(null)
      return
    }

    setShowInstructions(true)
  }

  if (!isMobile || isInstalled) {
    return null
  }

  const isSidebar = variant === 'sidebar'

  return (
    <div
      className={
        isSidebar
          ? 'border-t border-brand-800 px-4 py-3 lg:hidden'
          : 'mt-5 rounded-xl border border-green-100 bg-green-50 p-4'
      }
    >
      {!isSidebar && (
        <>
          <p className="text-sm font-semibold text-gray-900">
            Tenha o RF Performance no seu celular
          </p>

          <p className="mt-1 text-xs leading-relaxed text-gray-600">
            Instale o aplicativo para acessar mais rápido,
            direto pela tela inicial.
          </p>
        </>
      )}

      <button
        type="button"
        onClick={handleInstall}
        className={
          isSidebar
            ? 'flex w-full items-center justify-center gap-2 rounded-lg border border-green-500/30 bg-brand-800 px-3 py-2 text-sm font-medium text-green-300 transition hover:bg-brand-700 hover:text-white'
            : 'mt-3 flex w-full items-center justify-center gap-2 rounded-lg bg-brand-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-800'
        }
      >
        <Download className="h-4 w-4" />

        Instalar RF Performance
      </button>

      {showInstructions && (
        <div
          className={
            isSidebar
              ? 'mt-2 rounded-lg bg-brand-950/40 p-3 text-xs leading-relaxed text-green-100'
              : 'mt-3 rounded-lg border border-green-200 bg-white p-3 text-xs leading-relaxed text-gray-700'
          }
        >
          {isIos ? (
            <>
              No iPhone ou iPad, toque em{' '}
              <strong>Compartilhar</strong> no navegador e depois em{' '}
              <strong>Adicionar à Tela de Início</strong>.
            </>
          ) : isAndroid ? (
            <>
              Abra o menu <strong>⋮</strong> do navegador e escolha{' '}
              <strong>Instalar app</strong> ou{' '}
              <strong>Adicionar à tela inicial</strong>.
            </>
          ) : (
            <>
              Abra o menu do navegador e escolha a opção para instalar
              ou adicionar o aplicativo à tela inicial.
            </>
          )}
        </div>
      )}
    </div>
  )
}
