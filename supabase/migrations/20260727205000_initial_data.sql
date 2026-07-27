-- ============================================================================
-- RF Performance Comercial
-- Migration 003 — Dados iniciais legítimos
-- Data: 2026-07-27
--
-- Não cria usuários, vendedores, supervisores, vendas, metas ou resultados
-- fictícios. Os nomes dos três PDVs são provisórios e editáveis.
-- ============================================================================

begin;

insert into public.organizations (
  id,
  trade_name,
  slug,
  status,
  external_id,
  source_system,
  metadata
) values (
  '414a2e84-bc62-4c64-99ee-76db1cbc4654',
  'RF Consórcios',
  'rf-consorcios',
  'active',
  'rf-consorcios',
  'rf_performance',
  '{"initial_seed": true}'::jsonb
)
on conflict (slug) do update
set
  trade_name = excluded.trade_name,
  status = excluded.status,
  external_id = excluded.external_id,
  source_system = excluded.source_system,
  updated_at = now();

insert into public.operations (
  id,
  organization_id,
  name,
  slug,
  operation_type,
  status,
  external_id,
  source_system,
  metadata
) values (
  'c3982529-3988-47f5-a216-8e4b04187a10',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654',
  'Consórcio de Automóveis',
  'consorcio-automoveis',
  'automotive_consortium',
  'active',
  'consorcio-automoveis',
  'rf_performance',
  '{"initial_seed": true}'::jsonb
)
on conflict (organization_id, slug) do update
set
  name = excluded.name,
  operation_type = excluded.operation_type,
  status = excluded.status,
  external_id = excluded.external_id,
  source_system = excluded.source_system,
  updated_at = now();

insert into public.sales_locations (
  id,
  organization_id,
  operation_id,
  name,
  slug,
  location_type,
  timezone,
  status,
  external_id,
  source_system,
  metadata
) values
  (
    '2971c7eb-93dd-45ea-99c4-165770570b25',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    'PDV 1',
    'pdv-1',
    'shopping_kiosk',
    'America/Sao_Paulo',
    'active',
    'pdv-1',
    'rf_performance',
    '{"initial_seed": true, "provisional_name": true}'::jsonb
  ),
  (
    '192d8616-5dfe-4f0c-8444-328be19a0613',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    'PDV 2',
    'pdv-2',
    'shopping_kiosk',
    'America/Sao_Paulo',
    'active',
    'pdv-2',
    'rf_performance',
    '{"initial_seed": true, "provisional_name": true}'::jsonb
  ),
  (
    '3f903b49-3268-4d12-a3d4-76bcb4bbc01f',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    'PDV 3',
    'pdv-3',
    'shopping_kiosk',
    'America/Sao_Paulo',
    'active',
    'pdv-3',
    'rf_performance',
    '{"initial_seed": true, "provisional_name": true}'::jsonb
  )
on conflict (organization_id, slug) do update
set
  name = excluded.name,
  operation_id = excluded.operation_id,
  location_type = excluded.location_type,
  timezone = excluded.timezone,
  status = excluded.status,
  external_id = excluded.external_id,
  source_system = excluded.source_system,
  updated_at = now();

commit;
