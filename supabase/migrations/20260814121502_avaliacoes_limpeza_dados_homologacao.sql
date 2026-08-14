-- Limpeza idempotente dos dados conhecidos de homologação de Avaliações.
-- Preserva testes, versões, questões e configurações.

do $$
declare
  v_org uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  v_attempts uuid[] := array[
    '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid,
    '29f132ea-4ceb-4d96-975b-cb44ae9a7257'::uuid,
    'b657283a-ff78-4ce8-9882-eac150ac440e'::uuid,
    'a69f969b-dcb1-4398-824c-63f59deddf5e'::uuid,
    'bd116368-0a6a-4722-a8fb-d585718fc550'::uuid,
    'cdcb7fd5-6d3b-4e21-bdf1-b148a73bb597'::uuid
  ];

  v_grants uuid[] := array[
    '986fbc2a-bc95-4930-a827-25d92cdf3cf4'::uuid,
    '2c37c3a3-5a01-57c5-8312-40c7bc5eadea'::uuid,
    'ba3eeeeb-3a67-5599-a229-453b6b8f004f'::uuid,
    '14bd3682-b4d3-57ac-8c6d-80bef00261e3'::uuid,
    '7bc7b693-46fa-5fda-956e-eb7e7a951a7c'::uuid,
    '8f2553ac-9710-52e5-96d1-817cf836134b'::uuid,
    'c5df038b-6e54-5250-ad77-94837ff7486d'::uuid,
    '0ce84a28-aeb3-5cbb-a560-2e5ca295378e'::uuid,
    'e266716c-b90e-5526-a9cb-03a714823bd3'::uuid,
    '98cd8c18-108c-522c-b8db-6e167003ce45'::uuid
  ];
begin
  delete from public.assessment_attempt_answers
  where organization_id = v_org and attempt_id = any(v_attempts);

  delete from public.assessment_competency_scores
  where organization_id = v_org and attempt_id = any(v_attempts);

  delete from private.assessment_attempt_grades
  where organization_id = v_org and attempt_id = any(v_attempts);

  delete from public.member_certifications
  where organization_id = v_org and source_attempt_id = any(v_attempts);

  delete from public.assessment_attempt_items
  where organization_id = v_org and attempt_id = any(v_attempts);

  delete from public.assessment_attempts
  where organization_id = v_org and id = any(v_attempts);

  delete from private.assessment_test_access_grants
  where organization_id = v_org
    and id = any(v_grants)
    and metadata ->> 'pilot' = 'true';

  if exists (
    select 1 from public.assessment_attempts
    where organization_id = v_org and id = any(v_attempts)
  ) then
    raise exception 'CLEANUP: tentativa de homologacao permaneceu';
  end if;

  if exists (
    select 1 from private.assessment_test_access_grants
    where organization_id = v_org and id = any(v_grants)
  ) then
    raise exception 'CLEANUP: grant de homologacao permaneceu';
  end if;
end
$$;