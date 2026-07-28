import { createClient, type SupabaseClient, type User } from 'npm:@supabase/supabase-js@2'

type OrganizationRole = 'director' | 'supervisor' | 'salesperson'

type InviteRequest = {
  email?: unknown
  full_name?: unknown
  role?: unknown
  organization_id?: unknown
}

type JsonRecord = Record<string, unknown>

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const ALLOWED_ROLES: OrganizationRole[] = [
  'director',
  'supervisor',
  'salesperson',
]

function getNamedKey(
  mapVariable: string,
  legacyVariable: string,
): string {
  const mappedValue = Deno.env.get(mapVariable)

  if (mappedValue) {
    try {
      const parsed = JSON.parse(mappedValue) as Record<string, string>
      return parsed.default ?? Object.values(parsed)[0] ?? ''
    } catch {
      return mappedValue
    }
  }

  return Deno.env.get(legacyVariable) ?? ''
}

function normalizeOrigin(value: string): string | null {
  try {
    return new URL(value).origin
  } catch {
    return null
  }
}

function getAllowedOrigins(appUrl: string): Set<string> {
  const configured = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean)
    .map(normalizeOrigin)
    .filter((value): value is string => Boolean(value))

  const appOrigin = normalizeOrigin(appUrl)
  if (appOrigin) configured.push(appOrigin)

  return new Set(configured)
}

function buildCorsHeaders(
  origin: string | null,
  allowedOrigins: Set<string>,
): HeadersInit {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  }

  if (origin && allowedOrigins.has(origin)) {
    headers['Access-Control-Allow-Origin'] = origin
  }

  return headers
}

function jsonResponse(
  body: JsonRecord,
  status: number,
  corsHeaders: HeadersInit,
): Response {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  })
}

async function findAuthUserByEmail(
  adminClient: SupabaseClient,
  email: string,
): Promise<User | null> {
  const perPage = 1000

  for (let page = 1; page <= 100; page += 1) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage,
    })

    if (error) throw error

    const match = data.users.find(
      (user) => user.email?.trim().toLowerCase() === email,
    )

    if (match) return match
    if (data.users.length < perPage) return null
  }

  throw new Error(
    'A busca de usuários excedeu o limite de paginação permitido.',
  )
}

async function removeNewlyInvitedUser(
  adminClient: SupabaseClient,
  userId: string | null,
  shouldRemove: boolean,
): Promise<void> {
  if (!userId || !shouldRemove) return

  const { error } = await adminClient.auth.admin.deleteUser(userId)
  if (error) {
    console.error(
      '[invite-user] Falha ao compensar usuário recém-convidado.',
      error.message,
    )
  }
}

Deno.serve(async (request: Request) => {
  const appUrl = Deno.env.get('APP_URL') ?? ''
  const allowedOrigins = getAllowedOrigins(appUrl)
  const origin = request.headers.get('origin')
  const corsHeaders = buildCorsHeaders(origin, allowedOrigins)

  if (origin && !allowedOrigins.has(origin)) {
    return jsonResponse(
      {
        error: 'Origem não autorizada.',
        code: 'ORIGIN_NOT_ALLOWED',
      },
      403,
      corsHeaders,
    )
  }

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    })
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        error: 'Método não permitido.',
        code: 'METHOD_NOT_ALLOWED',
      },
      405,
      corsHeaders,
    )
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const publishableKey = getNamedKey(
    'SUPABASE_PUBLISHABLE_KEYS',
    'SUPABASE_ANON_KEY',
  )
  const secretKey = getNamedKey(
    'SUPABASE_SECRET_KEYS',
    'SUPABASE_SERVICE_ROLE_KEY',
  )

  if (!supabaseUrl || !publishableKey || !secretKey || !appUrl) {
    return jsonResponse(
      {
        error: 'Configuração incompleta da função.',
        code: 'FUNCTION_CONFIGURATION_ERROR',
      },
      500,
      corsHeaders,
    )
  }

  const authorization = request.headers.get('authorization')
  if (!authorization?.startsWith('Bearer ')) {
    return jsonResponse(
      {
        error: 'Sessão de usuário não fornecida.',
        code: 'AUTHORIZATION_REQUIRED',
      },
      401,
      corsHeaders,
    )
  }

  const accessToken = authorization.slice('Bearer '.length).trim()

  const callerClient = createClient(supabaseUrl, publishableKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  })

  const adminClient = createClient(supabaseUrl, secretKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  })

  const {
    data: { user: caller },
    error: callerError,
  } = await callerClient.auth.getUser(accessToken)

  if (callerError || !caller) {
    return jsonResponse(
      {
        error: 'Sessão inválida ou expirada.',
        code: 'INVALID_SESSION',
      },
      401,
      corsHeaders,
    )
  }

  let body: InviteRequest

  try {
    body = await request.json()
  } catch {
    return jsonResponse(
      {
        error: 'Corpo da requisição inválido.',
        code: 'INVALID_JSON',
      },
      400,
      corsHeaders,
    )
  }

  const email =
    typeof body.email === 'string'
      ? body.email.trim().toLowerCase()
      : ''
  const fullName =
    typeof body.full_name === 'string'
      ? body.full_name.trim()
      : ''
  const organizationId =
    typeof body.organization_id === 'string'
      ? body.organization_id.trim()
      : ''
  const role =
    typeof body.role === 'string' &&
    ALLOWED_ROLES.includes(body.role as OrganizationRole)
      ? body.role as OrganizationRole
      : null

  if (!email || !fullName || !organizationId || !role) {
    return jsonResponse(
      {
        error:
          'Informe nome completo, e-mail, organização e perfil válidos.',
        code: 'INVALID_INPUT',
      },
      400,
      corsHeaders,
    )
  }

  if (!EMAIL_PATTERN.test(email)) {
    return jsonResponse(
      {
        error: 'E-mail inválido.',
        code: 'INVALID_EMAIL',
      },
      400,
      corsHeaders,
    )
  }

  if (fullName.length < 2 || fullName.length > 200) {
    return jsonResponse(
      {
        error: 'O nome deve possuir entre 2 e 200 caracteres.',
        code: 'INVALID_FULL_NAME',
      },
      400,
      corsHeaders,
    )
  }

  const { data: callerProfile, error: callerProfileError } =
    await adminClient
      .from('profiles')
      .select('system_role, status, archived_at')
      .eq('id', caller.id)
      .maybeSingle()

  if (
    callerProfileError ||
    !callerProfile ||
    callerProfile.status !== 'active' ||
    callerProfile.archived_at
  ) {
    return jsonResponse(
      {
        error: 'Perfil do solicitante inativo ou inexistente.',
        code: 'CALLER_PROFILE_INACTIVE',
      },
      403,
      corsHeaders,
    )
  }

  const isPlatformAdmin =
    callerProfile.system_role === 'platform_admin'

  if (!isPlatformAdmin) {
    const { data: directorMembership, error: membershipError } =
      await adminClient
        .from('organization_members')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('user_id', caller.id)
        .eq('role', 'director')
        .eq('status', 'active')
        .is('archived_at', null)
        .maybeSingle()

    if (membershipError || !directorMembership) {
      return jsonResponse(
        {
          error:
            'Você não possui permissão para convidar usuários nesta organização.',
          code: 'INVITE_PERMISSION_DENIED',
        },
        403,
        corsHeaders,
      )
    }

    if (role === 'director') {
      return jsonResponse(
        {
          error: 'Somente o administrador da plataforma pode convidar diretores.',
          code: 'DIRECTOR_INVITE_REQUIRES_PLATFORM_ADMIN',
        },
        403,
        corsHeaders,
      )
    }
  }

  const { data: organization, error: organizationError } =
    await adminClient
      .from('organizations')
      .select('id, trade_name')
      .eq('id', organizationId)
      .eq('status', 'active')
      .is('archived_at', null)
      .maybeSingle()

  if (organizationError || !organization) {
    return jsonResponse(
      {
        error: 'Organização não encontrada ou inativa.',
        code: 'ORGANIZATION_NOT_FOUND',
      },
      404,
      corsHeaders,
    )
  }

  let existingUser: User | null

  try {
    existingUser = await findAuthUserByEmail(adminClient, email)
  } catch {
    return jsonResponse(
      {
        error: 'Não foi possível consultar os usuários existentes.',
        code: 'AUTH_USER_LOOKUP_FAILED',
      },
      500,
      corsHeaders,
    )
  }

  let targetUserId = existingUser?.id ?? null
  let inviteSent = false

  const { data: existingProfile } = targetUserId
    ? await adminClient
        .from('profiles')
        .select(
          'id, full_name, system_role, status, archived_at',
        )
        .eq('id', targetUserId)
        .maybeSingle()
    : {
        data: null,
      }

  if (existingProfile?.system_role === 'platform_admin') {
    return jsonResponse(
      {
        error:
          'Administradores da plataforma não devem receber vínculo empresarial por convite.',
        code: 'TARGET_IS_PLATFORM_ADMIN',
      },
      409,
      corsHeaders,
    )
  }

  if (
    existingProfile &&
    (
      existingProfile.status !== 'active' ||
      existingProfile.archived_at
    ) &&
    !isPlatformAdmin
  ) {
    return jsonResponse(
      {
        error:
          'O usuário existente está inativo. Solicite a reativação ao administrador da plataforma.',
        code: 'TARGET_PROFILE_INACTIVE',
      },
      403,
      corsHeaders,
    )
  }

  if (!targetUserId) {
    const redirectTo =
      `${appUrl.replace(/\/$/, '')}/atualizar-senha`

    const { data: inviteData, error: inviteError } =
      await adminClient.auth.admin.inviteUserByEmail(email, {
        redirectTo,
        data: {
          full_name: fullName,
          organization_id: organizationId,
          organization_name: organization.trade_name,
          requested_role: role,
        },
      })

    if (inviteError || !inviteData.user) {
      return jsonResponse(
        {
          error:
            inviteError?.message ??
            'Não foi possível enviar o convite.',
          code: 'INVITE_SEND_FAILED',
        },
        400,
        corsHeaders,
      )
    }

    targetUserId = inviteData.user.id
    existingUser = inviteData.user
    inviteSent = true
  }

  const normalizedName =
    existingProfile?.full_name?.trim() || fullName

  const { error: profileError } = await adminClient
    .from('profiles')
    .upsert(
      {
        id: targetUserId,
        full_name: normalizedName,
        email,
        status: 'active',
        archived_at: null,
        updated_by: caller.id,
      },
      {
        onConflict: 'id',
      },
    )

  if (profileError) {
    await removeNewlyInvitedUser(
      adminClient,
      targetUserId,
      inviteSent,
    )

    return jsonResponse(
      {
        error: 'Não foi possível preparar o perfil do usuário.',
        code: 'PROFILE_PREPARATION_FAILED',
      },
      500,
      corsHeaders,
    )
  }

  const { data: activeMembership, error: activeMembershipError } =
    await adminClient
      .from('organization_members')
      .select('id, role')
      .eq('organization_id', organizationId)
      .eq('user_id', targetUserId)
      .eq('status', 'active')
      .is('archived_at', null)
      .maybeSingle()

  if (activeMembershipError) {
    await removeNewlyInvitedUser(
      adminClient,
      targetUserId,
      inviteSent,
    )

    return jsonResponse(
      {
        error: 'Não foi possível verificar o vínculo empresarial.',
        code: 'MEMBERSHIP_LOOKUP_FAILED',
      },
      500,
      corsHeaders,
    )
  }

  if (activeMembership) {
    if (activeMembership.role !== role) {
      return jsonResponse(
        {
          error:
            'O usuário já possui vínculo ativo com outro perfil. Altere o perfil por um fluxo administrativo específico.',
          code: 'ACTIVE_MEMBERSHIP_ROLE_CONFLICT',
        },
        409,
        corsHeaders,
      )
    }

    return jsonResponse(
      {
        success: true,
        user_id: targetUserId,
        membership_id: activeMembership.id,
        invite_sent: false,
        already_member: true,
        message:
          'O usuário já possui vínculo ativo com esta organização.',
      },
      200,
      corsHeaders,
    )
  }

  const { data: inactiveMembership, error: inactiveMembershipError } =
    await adminClient
      .from('organization_members')
      .select('id, invited_at, joined_at')
      .eq('organization_id', organizationId)
      .eq('user_id', targetUserId)
      .in('status', ['inactive', 'archived'])
      .order('created_at', {
        ascending: false,
      })
      .limit(1)
      .maybeSingle()

  if (inactiveMembershipError) {
    await removeNewlyInvitedUser(
      adminClient,
      targetUserId,
      inviteSent,
    )

    return jsonResponse(
      {
        error: 'Não foi possível verificar vínculos anteriores.',
        code: 'INACTIVE_MEMBERSHIP_LOOKUP_FAILED',
      },
      500,
      corsHeaders,
    )
  }

  const now = new Date().toISOString()
  const joinedAt =
    existingUser?.email_confirmed_at
      ? inactiveMembership?.joined_at ?? now
      : inactiveMembership?.joined_at ?? null

  let membershipId: string
  let membershipAction: 'create' | 'reactivate'

  if (inactiveMembership) {
    const { data: reactivatedMembership, error: reactivationError } =
      await adminClient
        .from('organization_members')
        .update({
          role,
          status: 'active',
          archived_at: null,
          invited_at:
            inviteSent
              ? now
              : inactiveMembership.invited_at,
          joined_at: joinedAt,
          updated_by: caller.id,
        })
        .eq('id', inactiveMembership.id)
        .select('id')
        .single()

    if (reactivationError) {
      await removeNewlyInvitedUser(
        adminClient,
        targetUserId,
        inviteSent,
      )

      return jsonResponse(
        {
          error: 'Não foi possível reativar o vínculo empresarial.',
          code: 'MEMBERSHIP_REACTIVATION_FAILED',
        },
        500,
        corsHeaders,
      )
    }

    membershipId = reactivatedMembership.id
    membershipAction = 'reactivate'
  } else {
    const { data: createdMembership, error: creationError } =
      await adminClient
        .from('organization_members')
        .insert({
          organization_id: organizationId,
          user_id: targetUserId,
          role,
          status: 'active',
          invited_at: inviteSent ? now : null,
          joined_at: joinedAt,
          source_system: 'rf_performance',
          created_by: caller.id,
          updated_by: caller.id,
          metadata: {
            created_via: 'invite-user',
          },
        })
        .select('id')
        .single()

    if (creationError) {
      await removeNewlyInvitedUser(
        adminClient,
        targetUserId,
        inviteSent,
      )

      return jsonResponse(
        {
          error: 'Não foi possível criar o vínculo empresarial.',
          code: 'MEMBERSHIP_CREATION_FAILED',
        },
        500,
        corsHeaders,
      )
    }

    membershipId = createdMembership.id
    membershipAction = 'create'
  }

  const { error: auditError } = await adminClient
    .from('audit_logs')
    .insert({
      organization_id: organizationId,
      user_id: caller.id,
      action:
        inviteSent
          ? 'invite_sent'
          : membershipAction === 'reactivate'
            ? 'membership_reactivated'
            : 'membership_created',
      entity_type: 'organization_members',
      entity_id: membershipId,
      new_values: {
        target_user_id: targetUserId,
        role,
        invite_sent: inviteSent,
        organization_id: organizationId,
      },
    })

  if (auditError) {
    console.error(
      '[invite-user] Falha ao registrar evento complementar de auditoria.',
      auditError.message,
    )
  }

  return jsonResponse(
    {
      success: true,
      user_id: targetUserId,
      membership_id: membershipId,
      invite_sent: inviteSent,
      already_member: false,
      message:
        inviteSent
          ? 'Convite enviado e vínculo criado com sucesso.'
          : membershipAction === 'reactivate'
            ? 'Vínculo reativado com sucesso. O usuário já possuía uma conta.'
            : 'Vínculo criado com sucesso. O usuário já possuía uma conta.',
    },
    201,
    corsHeaders,
  )
})
