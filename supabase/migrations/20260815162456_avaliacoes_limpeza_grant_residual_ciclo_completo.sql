begin;

-- Limpeza pontual do grant residual da homologação do ciclo completo.
-- Grant:
-- f88a45e7-c9ac-4064-b0cf-96ba310a7600

do $$
declare
  v_count integer;
begin
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.id = 'f88a45e7-c9ac-4064-b0cf-96ba310a7600'::uuid
    and g.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and g.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and g.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and g.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and g.access_scope = 'member'
    and g.status = 'revoked'
    and g.archived_at is null
    and g.metadata ->> 'source' = 'assessment_admin_ui'
    and g.metadata ->> 'managed_by' = 'platform_admin';

  if v_count <> 1 then
    raise exception
      'RESIDUAL_GRANT_CLEANUP_ABORTED: expected exactly 1 matching revoked grant, found %',
      v_count;
  end if;
end;
$$;


delete from private.assessment_test_access_grants
where id = 'f88a45e7-c9ac-4064-b0cf-96ba310a7600'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
  and test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  and organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
  and access_scope = 'member'
  and status = 'revoked'
  and archived_at is null
  and metadata ->> 'source' = 'assessment_admin_ui'
  and metadata ->> 'managed_by' = 'platform_admin';


do $$
declare
  v_remaining integer;
begin
  select count(*)
    into v_remaining
  from private.assessment_test_access_grants
  where id = 'f88a45e7-c9ac-4064-b0cf-96ba310a7600'::uuid;

  if v_remaining <> 0 then
    raise exception
      'RESIDUAL_GRANT_CLEANUP_POSTCONDITION_FAILED: grant still exists';
  end if;
end;
$$;

commit;