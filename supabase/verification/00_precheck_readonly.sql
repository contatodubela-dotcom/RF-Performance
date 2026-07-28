-- RF Performance Comercial — Precheck somente leitura
-- Resultado esperado antes do primeiro push: nenhuma relação conflitante.

with expected_relations(name) as (
  values
    ('profiles'),
    ('organizations'),
    ('organization_members'),
    ('operations'),
    ('sales_locations'),
    ('teams'),
    ('team_members'),
    ('audit_logs')
)
select
  n.nspname as schema_name,
  c.relname as conflicting_relation,
  c.relkind
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
join expected_relations e on e.name = c.relname
where n.nspname = 'public'
order by c.relname;

-- Deve retornar 0 linhas.
