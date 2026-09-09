begin;

-- RF Performance
-- Hardening da transferência de vendedor entre equipes.
--
-- Estratégia:
--   * preserva integralmente a implementação já validada;
--   * move a implementação SECURITY DEFINER para o schema private;
--   * mantém em public somente um wrapper SECURITY INVOKER;
--   * anon continua sem acesso;
--   * authenticated pode chamar a RPC pública;
--   * a autorização Admin Master/Diretor continua sendo validada
--     dentro da implementação privilegiada.

alter function public.transfer_salesperson_team(
  uuid,
  uuid,
  uuid
)
set schema private;

alter function private.transfer_salesperson_team(
  uuid,
  uuid,
  uuid
)
rename to transfer_salesperson_team_impl;

comment on function private.transfer_salesperson_team_impl(
  uuid,
  uuid,
  uuid
) is
  'Implementação privilegiada da transferência atômica de vendedor entre equipes. Mantém validação interna de platform_admin/director, capacidade, histórico e auditoria.';

-- Normaliza os privilégios da implementação privada.
-- authenticated precisa de EXECUTE porque o wrapper público é SECURITY INVOKER.
-- O schema private não é exposto pela Data API.
revoke all on function private.transfer_salesperson_team_impl(
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

grant execute on function private.transfer_salesperson_team_impl(
  uuid,
  uuid,
  uuid
) to authenticated;

create or replace function public.transfer_salesperson_team(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_destination_team_id uuid
)
returns jsonb
language sql
volatile
security invoker
set search_path = ''
as $function$
  select private.transfer_salesperson_team_impl(
    p_organization_id,
    p_organization_member_id,
    p_destination_team_id
  );
$function$;

comment on function public.transfer_salesperson_team(
  uuid,
  uuid,
  uuid
) is
  'Wrapper SECURITY INVOKER para transferência segura de vendedor entre equipes. A implementação privilegiada permanece no schema private.';

revoke all on function public.transfer_salesperson_team(
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

grant execute on function public.transfer_salesperson_team(
  uuid,
  uuid,
  uuid
) to authenticated;

commit;
