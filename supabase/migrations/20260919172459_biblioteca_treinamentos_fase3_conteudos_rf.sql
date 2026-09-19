-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 3
-- Carga inicial de conteúdos da RF Consórcios
-- ============================================================================

do $$
begin
  if not exists (
    select 1
    from public.organizations
    where id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and slug = 'rf-consorcios'
      and status = 'active'
  ) then
    raise exception 'RF Consórcios ativa não encontrada para a carga da biblioteca';
  end if;

  if exists (
    select 1
    from public.training_library_items
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  ) then
    raise exception 'A biblioteca da RF Consórcios já possui itens; carga inicial abortada';
  end if;

  if exists (
    select 1
    from public.training_library_assets
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  ) then
    raise exception 'A biblioteca da RF Consórcios já possui assets; carga inicial abortada';
  end if;
end;
$$;

insert into public.training_library_items (
  id,
  organization_id,
  sequence_no,
  title,
  description,
  category,
  audience_roles,
  status,
  is_featured,
  metadata
)
values
(
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  1,
  'Formação Comercial – Consórcio de Automóveis',
  'Treinamento comercial sobre produto, sondagem, argumentação, objeções e fechamento aplicado à venda de consórcio de automóveis.',
  'commercial_training',
  array['director','supervisor','salesperson']::text[],
  'published',
  false,
  '{}'::jsonb
),
(
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  2,
  'SPIN Selling aplicado ao Consórcio',
  'Aplicação prática do método SPIN para conduzir a sondagem e desenvolver uma venda consultiva de consórcio.',
  'sales_method',
  array['director','supervisor','salesperson']::text[],
  'published',
  false,
  '{}'::jsonb
),
(
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  3,
  'Objeções e Fechamento',
  'Treinamento para compreender objeções, responder com método e reconhecer o momento adequado de conduzir o cliente ao fechamento.',
  'sales_method',
  array['director','supervisor','salesperson']::text[],
  'published',
  false,
  '{}'::jsonb
),
(
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  4,
  'Playbook do Supervisor RF Performance',
  'Guia operacional para supervisores e líderes utilizarem os principais fluxos da RF Performance no acompanhamento da equipe.',
  'platform_guide',
  array['director','supervisor']::text[],
  'published',
  false,
  '{}'::jsonb
),
(
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  5,
  'Método VAP – Vendedor de Alta Performance',
  'Programa de desenvolvimento comercial com conteúdos de vendas, comportamento, comunicação, liderança, neurovendas, copywriting, etapas da venda, objeções e uso de IA.',
  'commercial_training',
  array['director','supervisor','salesperson']::text[],
  'published',
  false,
  '{}'::jsonb
),
(
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  6,
  'Os 5 Sims da Venda de Consórcio',
  'Treinamento para conduzir o cliente do interesse ao fechamento pelos cinco sims internos: entendimento, confiança, solução, valor e decisão.',
  'sales_method',
  array['director','supervisor','salesperson']::text[],
  'published',
  false,
  '{}'::jsonb
);

insert into public.training_library_assets (
  id,
  organization_id,
  training_id,
  sequence_no,
  asset_type,
  display_name,
  storage_bucket,
  storage_path,
  mime_type,
  file_size_bytes,
  status,
  is_downloadable,
  metadata
)
values
(
  '2870bf53-aa3e-4f16-a0a2-9ab89da5b494'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  1,
  'workbook',
  'Apostila – Formação Comercial',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/01_formacao_comercial_consorcio_automoveis.pdf',
  'application/pdf',
  454601,
  'active',
  true,
  '{}'::jsonb
),
(
  '223f1eca-fcf7-4e73-9f73-f247720aeb6f'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  2,
  'slides',
  'Apresentação – Formação Comercial',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/02_formacao_comercial_consorcio_automoveis.pptx',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  12069364,
  'active',
  true,
  '{}'::jsonb
),
(
  '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  1,
  'workbook',
  'Apostila – SPIN Selling aplicado ao Consórcio',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/3e16b785-48d8-4b78-b21a-d6fe289c00b3/01_spin_selling_aplicado_ao_consorcio.pdf',
  'application/pdf',
  555727,
  'active',
  true,
  '{}'::jsonb
),
(
  'f606df67-6a1f-4232-9dfd-c846e6b163e9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  1,
  'workbook',
  'Apostila – Objeções e Fechamento',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/01_objecoes_e_fechamento.pdf',
  'application/pdf',
  468367,
  'active',
  true,
  '{}'::jsonb
),
(
  '7be304f7-9709-4a1d-a6c0-0b27040af36b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  2,
  'slides',
  'Apresentação – Objeções e Fechamento',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/02_objecoes_e_fechamento.pptx',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  1769444,
  'active',
  true,
  '{}'::jsonb
),
(
  'afdbd8d7-6d0e-4972-9136-3664b45c5344'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  1,
  'primary',
  'Playbook do Supervisor RF Performance',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/86c1cf11-1feb-498d-ac56-3b8ad6285eae/01_playbook_supervisor_rf_performance.pdf',
  'application/pdf',
  158105,
  'active',
  true,
  '{}'::jsonb
),
(
  'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  1,
  'primary',
  'Método VAP – Vendedor de Alta Performance',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/8cf3f39c-ee82-409d-b499-7cf321a54b04/01_metodo_vap.pdf',
  'application/pdf',
  31058620,
  'active',
  true,
  '{}'::jsonb
),
(
  'a447834a-84b4-4a93-9c20-c898fb937b43'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  1,
  'slides',
  'Apresentação – Os 5 Sims da Venda de Consórcio',
  'training-materials',
  '414a2e84-bc62-4c64-99ee-76db1cbc4654/923f6553-9091-44cc-b8f9-9f7b7f855942/01_5_sims_da_venda_de_consorcio.pptx',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  5225030,
  'active',
  true,
  '{}'::jsonb
);

do $$
declare
  v_item_count bigint;
  v_asset_count bigint;
begin
  select count(*)
    into v_item_count
  from public.training_library_items
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  select count(*)
    into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_item_count <> 6 then
    raise exception 'Carga da biblioteca incompleta: esperado 6 itens, encontrado %', v_item_count;
  end if;

  if v_asset_count <> 8 then
    raise exception 'Carga da biblioteca incompleta: esperado 8 assets, encontrado %', v_asset_count;
  end if;
end;
$$;
