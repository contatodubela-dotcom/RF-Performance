import {
  createClient,
  type SupabaseClient,
} from '@supabase/supabase-js'
type OrganizationRole =
  | 'director'
  | 'supervisor'
  | 'salesperson'

type CallerRole =
  | 'platform_admin'
  | OrganizationRole

type ResendAccessRequest = {
  organization_id?: unknown
  membership_id?: unknown
}

type JsonRecord = Record<string, unknown>

type CallerMembership = {
  id: string
  role: OrganizationRole
}

type TargetMembership = {
  id: string
  user_id: string
  role: OrganizationRole
  status: string
  archived_at: string | null
}

type TargetProfile = {
  id: string
  full_name: string | null
  email: string | null
  system_role: string | null
  status: string
  archived_at: string | null
}

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

const RESEND_COOLDOWN_MS = 60_000

function getNamedKey(
  mapVariable: string,
  legacyVariable: string,
): string {
  const mappedValue = Deno.env.get(mapVariable)

  if (mappedValue) {
    try {
      const parsed =
        JSON.parse(mappedValue) as Record<string, string>

      return (
        parsed.default ??
        Object.values(parsed)[0] ??
        ''
      )
    } catch {
      return mappedValue
    }
  }

  return Deno.env.get(legacyVariable) ?? ''
}

function normalizeOrigin(
  value: string,
): string | null {
  try {
    return new URL(value).origin
  } catch {
    return null
  }
}

function getAllowedOrigins(
  appUrl: string,
): Set<string> {
  const configured = (
    Deno.env.get('ALLOWED_ORIGINS') ?? ''
  )
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean)
    .map(normalizeOrigin)
    .filter(
      (value): value is string =>
        Boolean(value),
    )

  const appOrigin = normalizeOrigin(appUrl)

  if (appOrigin) {
    configured.push(appOrigin)
  }

  return new Set(configured)
}

function buildCorsHeaders(
  origin: string | null,
  allowedOrigins: Set<string>,
): HeadersInit {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods':
      'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  }

  if (
    origin &&
    allowedOrigins.has(origin)
  ) {
    headers['Access-Control-Allow-Origin'] =
      origin
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
      'Content-Type':
        'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  })
}

async function supervisorCanManageTarget(
  adminClient: SupabaseClient,
  organizationId: string,
  supervisorMembershipId: string,
  targetMembershipId: string,
): Promise<boolean> {
  const {
    data: assignments,
    error: assignmentsError,
  } = await adminClient
    .from('team_members')
    .select('team_id')
    .eq(
      'organization_id',
      organizationId,
    )
    .eq(
      'organization_member_id',
      targetMembershipId,
    )
    .eq('status', 'active')
    .eq(
      'membership_type',
      'salesperson',
    )
    .is('archived_at', null)

  if (assignmentsError) {
    throw assignmentsError
  }

  const teamIds = Array.from(
    new Set(
      (assignments ?? [])
        .map(
          (assignment) =>
            assignment.team_id,
        )
        .filter(Boolean),
    ),
  )

  if (teamIds.length === 0) {
    return false
  }

  const {
    data: managedTeams,
    error: teamsError,
  } = await adminClient
    .from('teams')
    .select('id')
    .eq(
      'organization_id',
      organizationId,
    )
    .eq(
      'supervisor_member_id',
      supervisorMembershipId,
    )
    .eq('status', 'active')
    .is('archived_at', null)
    .in('id', teamIds)
    .limit(1)

  if (teamsError) {
    throw teamsError
  }

  return (managedTeams ?? []).length > 0
}

Deno.serve(
  async (request: Request) => {
    const appUrl =
      Deno.env.get('APP_URL') ?? ''

    const allowedOrigins =
      getAllowedOrigins(appUrl)

    const origin =
      request.headers.get('origin')

    const corsHeaders =
      buildCorsHeaders(
        origin,
        allowedOrigins,
      )

    if (
      origin &&
      !allowedOrigins.has(origin)
    ) {
      return jsonResponse(
        {
          error:
            'Origem não autorizada.',
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
          error:
            'Método não permitido.',
          code: 'METHOD_NOT_ALLOWED',
        },
        405,
        corsHeaders,
      )
    }

    const supabaseUrl =
      Deno.env.get('SUPABASE_URL') ?? ''

    const publishableKey =
      getNamedKey(
        'SUPABASE_PUBLISHABLE_KEYS',
        'SUPABASE_ANON_KEY',
      )

    const secretKey =
      getNamedKey(
        'SUPABASE_SECRET_KEYS',
        'SUPABASE_SERVICE_ROLE_KEY',
      )

    if (
      !supabaseUrl ||
      !publishableKey ||
      !secretKey ||
      !appUrl
    ) {
      return jsonResponse(
        {
          error:
            'Configuração incompleta da função.',
          code:
            'FUNCTION_CONFIGURATION_ERROR',
        },
        500,
        corsHeaders,
      )
    }

    const authorization =
      request.headers.get(
        'authorization',
      )

    if (
      !authorization?.startsWith(
        'Bearer ',
      )
    ) {
      return jsonResponse(
        {
          error:
            'Sessão de usuário não fornecida.',
          code:
            'AUTHORIZATION_REQUIRED',
        },
        401,
        corsHeaders,
      )
    }

    const accessToken =
      authorization
        .slice('Bearer '.length)
        .trim()

    const callerClient =
      createClient(
        supabaseUrl,
        publishableKey,
        {
          global: {
            headers: {
              Authorization:
                authorization,
            },
          },
          auth: {
            autoRefreshToken: false,
            persistSession: false,
            detectSessionInUrl: false,
          },
        },
      )

    const adminClient =
      createClient(
        supabaseUrl,
        secretKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
            detectSessionInUrl: false,
          },
        },
      )

    const {
      data: {
        user: caller,
      },
      error: callerError,
    } =
      await callerClient.auth.getUser(
        accessToken,
      )

    if (
      callerError ||
      !caller
    ) {
      return jsonResponse(
        {
          error:
            'Sessão inválida ou expirada.',
          code: 'INVALID_SESSION',
        },
        401,
        corsHeaders,
      )
    }

    let body: ResendAccessRequest

    try {
      body =
        await request.json()
    } catch {
      return jsonResponse(
        {
          error:
            'Corpo da requisição inválido.',
          code: 'INVALID_JSON',
        },
        400,
        corsHeaders,
      )
    }

    const organizationId =
      typeof body.organization_id ===
        'string'
        ? body.organization_id.trim()
        : ''

    const membershipId =
      typeof body.membership_id ===
        'string'
        ? body.membership_id.trim()
        : ''

    if (
      !UUID_PATTERN.test(
        organizationId,
      )
    ) {
      return jsonResponse(
        {
          error:
            'Organização inválida.',
          code:
            'INVALID_ORGANIZATION_ID',
        },
        400,
        corsHeaders,
      )
    }

    if (
      !UUID_PATTERN.test(
        membershipId,
      )
    ) {
      return jsonResponse(
        {
          error:
            'Usuário inválido.',
          code:
            'INVALID_MEMBERSHIP_ID',
        },
        400,
        corsHeaders,
      )
    }

    const {
      data: callerProfile,
      error: callerProfileError,
    } = await adminClient
      .from('profiles')
      .select(
        'system_role, status, archived_at',
      )
      .eq('id', caller.id)
      .maybeSingle()

    if (
      callerProfileError ||
      !callerProfile ||
      callerProfile.status !==
        'active' ||
      callerProfile.archived_at
    ) {
      return jsonResponse(
        {
          error:
            'Perfil do solicitante inativo ou inexistente.',
          code:
            'CALLER_PROFILE_INACTIVE',
        },
        403,
        corsHeaders,
      )
    }

    const isPlatformAdmin =
      callerProfile.system_role ===
      'platform_admin'

    let callerRole: CallerRole =
      'platform_admin'

    let callerMembership:
      CallerMembership | null = null

    if (!isPlatformAdmin) {
      const {
        data: membership,
        error: membershipError,
      } = await adminClient
        .from(
          'organization_members',
        )
        .select('id, role')
        .eq(
          'organization_id',
          organizationId,
        )
        .eq('user_id', caller.id)
        .eq('status', 'active')
        .is('archived_at', null)
        .maybeSingle()

      if (
        membershipError ||
        !membership
      ) {
        return jsonResponse(
          {
            error:
              'Você não possui permissão para reenviar acessos nesta organização.',
            code:
              'RESEND_PERMISSION_DENIED',
          },
          403,
          corsHeaders,
        )
      }

      callerMembership =
        membership as CallerMembership

      callerRole =
        callerMembership.role

      if (
        callerRole ===
        'salesperson'
      ) {
        return jsonResponse(
          {
            error:
              'Vendedores não possuem permissão para reenviar acessos.',
            code:
              'RESEND_PERMISSION_DENIED',
          },
          403,
          corsHeaders,
        )
      }
    }

    const {
      data: organization,
      error: organizationError,
    } = await adminClient
      .from('organizations')
      .select('id')
      .eq('id', organizationId)
      .eq('status', 'active')
      .is('archived_at', null)
      .maybeSingle()

    if (
      organizationError ||
      !organization
    ) {
      return jsonResponse(
        {
          error:
            'Organização não encontrada ou inativa.',
          code:
            'ORGANIZATION_NOT_FOUND',
        },
        404,
        corsHeaders,
      )
    }

    const {
      data: membership,
      error: targetMembershipError,
    } = await adminClient
      .from(
        'organization_members',
      )
      .select(
        'id, user_id, role, status, archived_at',
      )
      .eq('id', membershipId)
      .eq(
        'organization_id',
        organizationId,
      )
      .maybeSingle()

    if (
      targetMembershipError ||
      !membership
    ) {
      return jsonResponse(
        {
          error:
            'Usuário não encontrado nesta organização.',
          code:
            'TARGET_MEMBERSHIP_NOT_FOUND',
        },
        404,
        corsHeaders,
      )
    }

    const targetMembership =
      membership as TargetMembership

    if (
      targetMembership.status !==
        'active' ||
      targetMembership.archived_at
    ) {
      return jsonResponse(
        {
          error:
            'O usuário está inativo. Reative o vínculo antes de reenviar o acesso.',
          code:
            'TARGET_MEMBERSHIP_INACTIVE',
        },
        409,
        corsHeaders,
      )
    }

    if (
      callerRole === 'director' &&
      targetMembership.role ===
        'director'
    ) {
      return jsonResponse(
        {
          error:
            'Somente o administrador da plataforma pode reenviar acesso de diretores.',
          code:
            'DIRECTOR_RESEND_REQUIRES_PLATFORM_ADMIN',
        },
        403,
        corsHeaders,
      )
    }

    if (
      callerRole ===
      'supervisor'
    ) {
      if (
        targetMembership.role !==
        'salesperson'
      ) {
        return jsonResponse(
          {
            error:
              'Supervisores podem reenviar acesso somente para vendedores.',
            code:
              'SUPERVISOR_CAN_RESEND_ONLY_SALESPERSON',
          },
          403,
          corsHeaders,
        )
      }

      if (!callerMembership) {
        return jsonResponse(
          {
            error:
              'Não foi possível determinar o vínculo do supervisor.',
            code:
              'SUPERVISOR_MEMBERSHIP_REQUIRED',
          },
          403,
          corsHeaders,
        )
      }

      let canManageTarget = false

      try {
        canManageTarget =
          await supervisorCanManageTarget(
            adminClient,
            organizationId,
            callerMembership.id,
            targetMembership.id,
          )
      } catch {
        return jsonResponse(
          {
            error:
              'Não foi possível validar o vínculo do vendedor com a equipe.',
            code:
              'SUPERVISOR_SCOPE_CHECK_FAILED',
          },
          500,
          corsHeaders,
        )
      }

      if (!canManageTarget) {
        return jsonResponse(
          {
            error:
              'Você só pode reenviar acesso para vendedores das equipes sob sua responsabilidade.',
            code:
              'SUPERVISOR_TEAM_SCOPE_DENIED',
          },
          403,
          corsHeaders,
        )
      }
    }

    const {
      data: profile,
      error: targetProfileError,
    } = await adminClient
      .from('profiles')
      .select(
        'id, full_name, email, system_role, status, archived_at',
      )
      .eq(
        'id',
        targetMembership.user_id,
      )
      .maybeSingle()

    if (
      targetProfileError ||
      !profile
    ) {
      return jsonResponse(
        {
          error:
            'Perfil do usuário não encontrado.',
          code:
            'TARGET_PROFILE_NOT_FOUND',
        },
        404,
        corsHeaders,
      )
    }

    const targetProfile =
      profile as TargetProfile

    if (
      targetProfile.system_role ===
      'platform_admin'
    ) {
      return jsonResponse(
        {
          error:
            'Administradores da plataforma não utilizam este fluxo de reenvio.',
          code:
            'TARGET_IS_PLATFORM_ADMIN',
        },
        409,
        corsHeaders,
      )
    }

    if (
      targetProfile.status !==
        'active' ||
      targetProfile.archived_at
    ) {
      return jsonResponse(
        {
          error:
            'O perfil do usuário está inativo.',
          code:
            'TARGET_PROFILE_INACTIVE',
        },
        409,
        corsHeaders,
      )
    }

    const {
      data: authData,
      error: authUserError,
    } =
      await adminClient.auth.admin
        .getUserById(
          targetMembership.user_id,
        )

    if (
      authUserError ||
      !authData.user
    ) {
      return jsonResponse(
        {
          error:
            'Conta de autenticação não encontrada.',
          code:
            'TARGET_AUTH_USER_NOT_FOUND',
        },
        404,
        corsHeaders,
      )
    }

    const authUser =
      authData.user

    const email =
      authUser.email
        ?.trim()
        .toLowerCase() ?? ''

    if (!email) {
      return jsonResponse(
        {
          error:
            'A conta não possui um e-mail válido para reenvio.',
          code:
            'TARGET_EMAIL_NOT_FOUND',
        },
        409,
        corsHeaders,
      )
    }

    if (
      authUser.email_confirmed_at
    ) {
      return jsonResponse(
        {
          error:
            'Este usuário já ativou o acesso. Se não souber a senha, utilize o fluxo de recuperação de senha.',
          code:
            'ACCESS_ALREADY_ACTIVATED',
        },
        409,
        corsHeaders,
      )
    }

    const cooldownSince =
      new Date(
        Date.now() -
          RESEND_COOLDOWN_MS,
      ).toISOString()

    const {
      data: recentResend,
      error: cooldownError,
    } = await adminClient
      .from('audit_logs')
      .select('id, created_at')
      .eq(
        'organization_id',
        organizationId,
      )
      .eq(
        'action',
        'access_invite_resent',
      )
      .eq(
        'entity_type',
        'organization_members',
      )
      .eq(
        'entity_id',
        membershipId,
      )
      .gte(
        'created_at',
        cooldownSince,
      )
      .order(
        'created_at',
        { ascending: false },
      )
      .limit(1)
      .maybeSingle()

    if (cooldownError) {
      return jsonResponse(
        {
          error:
            'Não foi possível validar o intervalo de reenvio.',
          code:
            'RESEND_COOLDOWN_CHECK_FAILED',
        },
        500,
        corsHeaders,
      )
    }

    if (recentResend) {
      return jsonResponse(
        {
          error:
            'Um novo acesso foi enviado recentemente. Aguarde pelo menos 1 minuto antes de tentar novamente.',
          code:
            'ACCESS_RESEND_COOLDOWN',
        },
        429,
        corsHeaders,
      )
    }

    const redirectTo =
      `${appUrl.replace(/\/$/, '')}/atualizar-senha`

    const {
      data: inviteData,
      error: inviteError,
    } =
      await adminClient.auth.admin
        .inviteUserByEmail(
          email,
          {
            redirectTo,
          },
        )

    if (
      inviteError ||
      !inviteData.user
    ) {
      return jsonResponse(
        {
          error:
            inviteError?.message ??
            'Não foi possível reenviar o acesso.',
          code:
            'ACCESS_RESEND_FAILED',
        },
        400,
        corsHeaders,
      )
    }

    if (
      inviteData.user.id !==
      targetMembership.user_id
    ) {
      console.error(
        '[resend-user-access] O Auth retornou um usuário diferente do vínculo solicitado.',
      )

      return jsonResponse(
        {
          error:
            'O reenvio retornou uma conta inesperada. A operação precisa ser revisada.',
          code:
            'ACCESS_RESEND_USER_MISMATCH',
        },
        500,
        corsHeaders,
      )
    }

    const {
      error: auditError,
    } = await adminClient
      .from('audit_logs')
      .insert({
        organization_id:
          organizationId,
        user_id: caller.id,
        action:
          'access_invite_resent',
        entity_type:
          'organization_members',
        entity_id:
          targetMembership.id,
        new_values: {
          target_user_id:
            targetMembership.user_id,
          target_role:
            targetMembership.role,
          actor_role:
            callerRole,
          invite_resent: true,
          redirect_to:
            redirectTo,
        },
      })

    if (auditError) {
      console.error(
        '[resend-user-access] Falha ao registrar auditoria do reenvio.',
        auditError.message,
      )
    }

    return jsonResponse(
      {
        success: true,
        user_id:
          targetMembership.user_id,
        membership_id:
          targetMembership.id,
        invite_sent: true,
        message:
          'Novo link de acesso enviado com sucesso.',
      },
      200,
      corsHeaders,
    )
  },
)