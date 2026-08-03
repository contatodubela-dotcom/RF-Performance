# Hardening Fase 2 — plano comercial e rituais

## Objetivo

Encerrar a etapa temporária de compatibilidade criada na migration
`20260802190000_segrega_plano_rituais_reunioes_por_perfil.sql`.

A versão de produção já utiliza:

- `get_commercial_plan_reference(uuid)` para a referência mínima do plano;
- `get_management_rituals_for_current_user(uuid)` para rituais filtrados por perfil.

## Alteração

A migration desta fase remove somente:

- `commercial_plans_select_members`;
- `management_rituals_select_members`.

As policies abaixo permanecem ativas:

- `commercial_plans_manage_leadership`;
- `management_rituals_manage_leadership`.

Como são policies `ALL`, elas continuam permitindo o `SELECT` direto para
administrador da plataforma e diretor, além das operações de gestão já
autorizadas.

## Resultado esperado

- vendedor e supervisor deixam de consultar diretamente o plano comercial;
- vendedor e supervisor deixam de consultar diretamente todos os rituais;
- telas operacionais continuam funcionando pelas RPCs seguras;
- administrador e diretor preservam a visão e a gestão completas;
- nenhuma linha de negócio é criada, alterada ou removida.

## Guardas da migration

A migration aborta antes de remover as policies quando encontra:

- RLS desativada;
- uma das RPCs ausente;
- RPC sem `SECURITY DEFINER`;
- `authenticated` sem `EXECUTE`;
- `anon` com `EXECUTE`;
- policy de liderança ausente.

## Validação

Execute, depois da migration:

`supabase/verification/15_validate_hardening_fase2_plano_rituais_readonly.sql`

Resultado esperado:

- `result = PASS`;
- `checks_passed = 20`;
- `checks_total = 20`;
- todos os itens de `details` com `passed = true`.

## Reversão emergencial

Somente em caso de falha operacional confirmada, recrie temporariamente as
policies de compatibilidade:

```sql
create policy commercial_plans_select_members
on public.commercial_plans
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_active_membership(organization_id)
);

create policy management_rituals_select_members
on public.management_rituals
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_active_membership(organization_id)
);
```

Depois investigue a dependência que ainda faz leitura direta. A reversão não
deve substituir a correção definitiva.
