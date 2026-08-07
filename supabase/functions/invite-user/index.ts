import { createClient, type SupabaseClient, type User } from 'npm:@supabase/supabase-js@2'

type OrganizationRole = 'director' | 'supervisor' | 'salesperson'
type CallerRole = 'platform_admin' | OrganizationRole

type InviteRequest = {
  email?: unknown
  full_name?: unknown
  role?: unknown
  organization_id?: unknown
  team_id?: unknown
}

type JsonRecord = Record<string, unknown>

type CallerMembership = {
  id: string
  role: OrganizationRole
}

type TeamContext = {
  id: string
  organization_id: string
  sales_location_id: string | null
  supervisor_member_id: string | null
  status: string
  archived_at: string | null
}

type PreviousMembershipState = {
  id: string
  role: OrganizationRole
  status: 'inactive' | 'archived'
  archived_at: string | null
  invited_at: string | null
  joined_at: string | null
}

type MembershipAction = 'existing' | 'create' | 'reactivate'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
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

async function compensateMembershipChange(
  adminClient: SupabaseClient,
  action: MembershipAction,
  membershipId: string,
  previousMembership: PreviousMembershipState | null,
  callerId: string,
): Promise<void> {
  if (action === 'existing') return

  if (action === 'create') {
    const { error } = await adminClient
      .from('organization_members')
      .delete()
      .eq('id', membershipId)

    if (error) {
      console.error(
        '[invite-user] Falha ao remover vínculo criado durante compensação.',
        error.message,
      )
    }
    return
  }

  if (!previousMembership) return

  const { error } = await adminClient
    .from('organization_members')
    .update({
      role: previousMembership.role,
      status: previousMembership.status,
      archived_at: previousMembership.archived_at,
      invited_at: previousMembership.invited_at,
      joined_at: previousMembership.joined_at,
      updated_by: callerId,
    })
    .eq('id', membershipId)

  if (error) {
    console.error(
      '[invite-user] Falha ao restaurar vínculo reativado durante compensação.',
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
  const teamId =
    typeof body.team_id === 'string'
      ? body.team_id.trim()
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

  if (teamId && !UUID_PATTERN.test(teamId)) {
    return jsonResponse(
      {
        error: 'Equipe inválida.',
        code: 'INVALID_TEAM_ID',
      },
      400,
      corsHeaders,
    )
  }

  if (role === 'salesperson' && !teamId) {
    return jsonResponse(
      {
        error: 'Selecione a equipe do vendedor.',
        code: 'SALESPERSON_TEAM_REQUIRED',
      },
      400,
      corsHeaders,
    )
  }

  if (role === 'director' && teamId) {
    return jsonResponse(
      {
        error: 'Diretores não devem ser vinculados a uma equipe pelo fluxo de convite.',
        code: 'DIRECTOR_TEAM_NOT_ALLOWED',
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

  let callerRole: CallerRole = 'platform_admin'
  let callerMembership: CallerMembership | null = null

  if (!isPlatformAdmin) {
    const { data: membership, error: membershipError } =
      await adminClient
        .from('organization_members')
        .select('id, role')
        .eq('organization_id', organizationId)
        .eq('user_id', caller.id)
        .eq('status', 'active')
        .is('archived_at', null)
        .maybeSingle()

    if (membershipError || !membership) {
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

    callerMembership = membership as CallerMembership
    callerRole = callerMembership.role

    if (callerRole === 'salesperson') {
      return jsonResponse(
        {
          error: 'Vendedores não possuem permissão para convidar usuários.',
          code: 'INVITE_PERMISSION_DENIED',
        },
        403,
        corsHeaders,
      )
    }

    if (callerRole === 'director' && role === 'director') {
      return jsonResponse(
        {
          error: 'Somente o administrador da plataforma pode convidar diretores.',
          code: 'DIRECTOR_INVITE_REQUIRES_PLATFORM_ADMIN',
        },
        403,
        corsHeaders,
      )
    }

    if (callerRole === 'supervisor') {
      if (role !== 'salesperson') {
        return jsonResponse(
          {
            error: 'Supervisores podem cadastrar somente vendedores.',
            code: 'SUPERVISOR_CAN_INVITE_ONLY_SALESPERSON',
          },
          403,
          corsHeaders,
        )
      }

      if (!teamId) {
        return jsonResponse(
          {
            error: 'Selecione uma equipe sob sua responsabilidade.',
            code: 'SUPERVISOR_TEAM_REQUIRED',
          },
          400,
          corsHeaders,
        )
      }
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

  let teamContext: TeamContext | null = null

  if (teamId) {
    const { data: team, error: teamError } = await adminClient
      .from('teams')
      .select(
        'id, organization_id, sales_location_id, supervisor_member_id, status, archived_at',
      )
      .eq('id', teamId)
      .eq('organization_id', organizationId)
      .eq('status', 'active')
      .is('archived_at', null)
      .maybeSingle()

    if (teamError || !team) {
      return jsonResponse(
        {
          error: 'Equipe não encontrada ou inativa nesta organização.',
          code: 'TEAM_NOT_FOUND',
        },
        404,
        corsHeaders,
      )
    }

    teamContext = team as TeamContext

    if (!teamContext.sales_location_id) {
      return jsonResponse(
        {
          error: 'A equipe precisa estar vinculada a um PDV antes de receber usuários.',
          code: 'TEAM_LOCATION_REQUIRED',
        },
        409,
        corsHeaders,
      )
    }

    if (role === 'salesperson' && !teamContext.supervisor_member_id) {
      return jsonResponse(
        {
          error: 'A equipe precisa ter um supervisor antes de receber vendedores.',
          code: 'TEAM_SUPERVISOR_REQUIRED',
        },
        409,
        corsHeaders,
      )
    }

    if (
      callerRole === 'supervisor' &&
      teamContext.supervisor_member_id !== callerMembership?.id
    ) {
      return jsonResponse(
        {
          error: 'Você só pode cadastrar vendedores nas equipes sob sua responsabilidade.',
          code: 'SUPERVISOR_TEAM_SCOPE_DENIED',
        },
        403,
        corsHeaders,
      )
    }
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
          requested_team_id: teamId || null,
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

  if (!targetUserId) {
    return jsonResponse(
      {
        error: 'Não foi possível determinar o usuário de destino.',
        code: 'TARGET_USER_RESOLUTION_FAILED',
      },
      500,
      corsHeaders,
    )
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

  if (activeMembership && activeMembership.role !== role) {
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

  const { data: inactiveMembership, error: inactiveMembershipError } =
    activeMembership
      ? { data: null, error: null }
      : await adminClient
          .from('organization_members')
          .select('id, role, status, archived_at, invited_at, joined_at')
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

  const previousMembership = inactiveMembership
    ? inactiveMembership as PreviousMembershipState
    : null

  const now = new Date().toISOString()
  const joinedAt =
    existingUser?.email_confirmed_at
      ? previousMembership?.joined_at ?? now
      : previousMembership?.joined_at ?? null

  let membershipId: string
  let membershipAction: MembershipAction

  if (activeMembership) {
    membershipId = activeMembership.id
    membershipAction = 'existing'
  } else if (previousMembership) {
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
              : previousMembership.invited_at,
          joined_at: joinedAt,
          updated_by: caller.id,
        })
        .eq('id', previousMembership.id)
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

  const failAfterMembership = async (
    error: string,
    code: string,
    status: number,
  ): Promise<Response> => {
    await compensateMembershipChange(
      adminClient,
      membershipAction,
      membershipId,
      previousMembership,
      caller.id,
    )
    await removeNewlyInvitedUser(
      adminClient,
      targetUserId,
      inviteSent,
    )

    return jsonResponse({ error, code }, status, corsHeaders)
  }

  let hierarchyLinked = false

  if (role === 'salesperson' && teamContext) {
    const { data: activeAssignments, error: assignmentsError } =
      await adminClient
        .from('team_members')
        .select('id, team_id')
        .eq('organization_id', organizationId)
        .eq('organization_member_id', membershipId)
        .eq('status', 'active')
        .is('archived_at', null)

    if (assignmentsError) {
      return await failAfterMembership(
        'Não foi possível verificar a equipe atual do vendedor.',
        'TEAM_ASSIGNMENT_LOOKUP_FAILED',
        500,
      )
    }

    if ((activeAssignments ?? []).length > 0) {
      const sameTeam = (activeAssignments ?? []).find(
        (assignment) => assignment.team_id === teamContext?.id,
      )

      if (!sameTeam || (activeAssignments ?? []).length > 1) {
        return await failAfterMembership(
          'O vendedor já possui vínculo ativo com outra equipe. Encerre o vínculo anterior antes de transferi-lo.',
          'SALESPERSON_ALREADY_ASSIGNED',
          409,
        )
      }

      hierarchyLinked = true
    } else {
      const { error: assignmentError } = await adminClient
        .from('team_members')
        .insert({
          organization_id: organizationId,
          team_id: teamContext.id,
          organization_member_id: membershipId,
          membership_type: 'salesperson',
          start_at: now,
          status: 'active',
          created_by: caller.id,
          updated_by: caller.id,
          metadata: {
            assignment_source: 'invite-user',
            assigned_by_role: callerRole,
          },
        })

      if (assignmentError) {
        console.error(
          '[invite-user] Falha ao vincular vendedor à equipe.',
          assignmentError.message,
        )

        return await failAfterMembership(
          'Não foi possível vincular o vendedor à equipe selecionada.',
          'TEAM_ASSIGNMENT_FAILED',
          500,
        )
      }

      hierarchyLinked = true
    }
  }

  if (role === 'supervisor' && teamContext) {
    if (
      teamContext.supervisor_member_id &&
      teamContext.supervisor_member_id !== membershipId
    ) {
      return await failAfterMembership(
        'A equipe selecionada já possui outro supervisor.',
        'TEAM_ALREADY_HAS_SUPERVISOR',
        409,
      )
    }

    if (teamContext.supervisor_member_id === membershipId) {
      hierarchyLinked = true
    } else {
      const { data: updatedTeam, error: teamUpdateError } =
        await adminClient
          .from('teams')
          .update({
            supervisor_member_id: membershipId,
            updated_by: caller.id,
          })
          .eq('id', teamContext.id)
          .eq('organization_id', organizationId)
          .is('supervisor_member_id', null)
          .select('id')
          .maybeSingle()

      if (teamUpdateError) {
        console.error(
          '[invite-user] Falha ao vincular supervisor à equipe.',
          teamUpdateError.message,
        )

        return await failAfterMembership(
          'Não foi possível vincular o supervisor à equipe selecionada.',
          'SUPERVISOR_TEAM_ASSIGNMENT_FAILED',
          500,
        )
      }

      if (!updatedTeam) {
        const { data: currentTeam } = await adminClient
          .from('teams')
          .select('supervisor_member_id')
          .eq('id', teamContext.id)
          .eq('organization_id', organizationId)
          .maybeSingle()

        if (currentTeam?.supervisor_member_id !== membershipId) {
          return await failAfterMembership(
            'A equipe selecionada recebeu outro supervisor durante o cadastro. Atualize a página e tente novamente.',
            'TEAM_SUPERVISOR_CONFLICT',
            409,
          )
        }
      }

      hierarchyLinked = true
    }
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
            : membershipAction === 'create'
              ? 'membership_created'
              : hierarchyLinked
                ? 'membership_hierarchy_confirmed'
                : 'membership_existing',
      entity_type: 'organization_members',
      entity_id: membershipId,
      new_values: {
        target_user_id: targetUserId,
        role,
        invite_sent: inviteSent,
        organization_id: organizationId,
        team_id: teamContext?.id ?? null,
        sales_location_id: teamContext?.sales_location_id ?? null,
        hierarchy_linked: hierarchyLinked,
        actor_role: callerRole,
      },
    })

  if (auditError) {
    console.error(
      '[invite-user] Falha ao registrar evento complementar de auditoria.',
      auditError.message,
    )
  }

  const alreadyMember = membershipAction === 'existing'
  const responseStatus = alreadyMember ? 200 : 201

  let message: string

  if (role === 'salesperson' && hierarchyLinked) {
    message = inviteSent
      ? 'Convite enviado e vendedor vinculado à equipe com sucesso.'
      : alreadyMember
        ? 'O vendedor já possuía vínculo ativo; a equipe foi confirmada com sucesso.'
        : membershipAction === 'reactivate'
          ? 'Vínculo reativado e vendedor associado à equipe com sucesso.'
          : 'Vendedor vinculado à organização e à equipe com sucesso.'
  } else if (role === 'supervisor' && hierarchyLinked) {
    message = inviteSent
      ? 'Convite enviado e supervisor vinculado à equipe com sucesso.'
      : 'Supervisor vinculado à equipe com sucesso.'
  } else {
    message = inviteSent
      ? 'Convite enviado e vínculo criado com sucesso.'
      : alreadyMember
        ? 'O usuário já possui vínculo ativo com esta organização.'
        : membershipAction === 'reactivate'
          ? 'Vínculo reativado com sucesso. O usuário já possuía uma conta.'
          : 'Vínculo criado com sucesso. O usuário já possuía uma conta.'
  }

  return jsonResponse(
    {
      success: true,
      user_id: targetUserId,
      membership_id: membershipId,
      invite_sent: inviteSent,
      already_member: alreadyMember,
      hierarchy_linked: hierarchyLinked,
      team_id: teamContext?.id ?? null,
      sales_location_id: teamContext?.sales_location_id ?? null,
      message,
    },
    responseStatus,
    corsHeaders,
  )
})
