-- ============================================================================
-- RF Performance Comercial
-- Generaliza rótulos do template comercial para uso multiempresa
-- ============================================================================

begin;

update public.management_rituals
set
  title = 'Reunião executiva de performance',
  responsible_role = 'EPSA / Direção',
  updated_at = now(),
  metadata = metadata || jsonb_build_object(
    'generic_template_label', true,
    'previous_title', title
  )
where title = 'ROPRE com Raphael'
  and archived_at is null;

update public.management_rituals
set
  responsible_role = 'EPSA / Empresa',
  updated_at = now()
where responsible_role = 'EPSA / RF'
  and title <> 'Reunião executiva de performance'
  and archived_at is null;

commit;
