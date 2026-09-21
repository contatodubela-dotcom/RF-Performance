-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5E
-- Escala da experiência de aprendizagem: Método VAP – Vendedor de Alta Performance
--
-- Fonte publicada validada:
--   asset_id: d51e0a0e-f39a-4de7-85e0-8cf8d8063530
--   arquivo: 01_metodo_vap.pdf
--   tamanho: 31058620 bytes
--   sha256: D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84
--
-- NOTA DE INTEGRIDADE EDITORIAL
--   A capa/sumário da fonte declara "10 módulos + 1 extra · 55 aulas".
--   Porém, a versão efetivamente publicada contém 58 seções de aula explícitas:
--     módulos 1–8: 5 aulas cada (40)
--     módulo 9: 9 aulas
--     módulo 10: 5 aulas
--     módulo extra: 4 aulas
--   Total estruturado: 58.
--   Esta migration preserva a estrutura explícita da fonte e registra a
--   divergência nos metadados; não inventa, exclui nem renumera aulas.
--
-- Duração
--   A fonte não informa duração por aula. Para a experiência de aprendizagem,
--   adota-se estimativa operacional uniforme de 10 minutos por aula estruturada:
--   58 x 10 = 580 minutos. A base da estimativa fica registrada em metadata.
-- ============================================================================

-- ============================================================================
-- 0. PREFLIGHT FAIL-CLOSED
-- ============================================================================

do $preflight$
declare
  v_item_count bigint;
  v_asset_count bigint;
  v_exact_asset_count bigint;
  v_module_count bigint;
  v_lesson_count bigint;
  v_progress_count bigint;
begin
  select count(*)
  into v_item_count
  from public.training_library_items
  where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 5
    and title = 'Método VAP – Vendedor de Alta Performance'
    and description = 'Programa de desenvolvimento comercial com conteúdos de vendas, comportamento, comunicação, liderança, neurovendas, copywriting, etapas da venda, objeções e uso de IA.'
    and category = 'commercial_training'
    and to_jsonb(audience_roles) = '["director","supervisor","salesperson"]'::jsonb
    and status = 'published'
    and is_featured = false
    and metadata = '{}'::jsonb;

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: item Método VAP divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
  into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  if v_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: esperado 1 asset; encontrado %',
      v_asset_count;
  end if;

  select count(*)
  into v_exact_asset_count
  from public.training_library_assets
  where id = 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and sequence_no = 1
    and asset_type = 'primary'
    and display_name = 'Método VAP – Vendedor de Alta Performance'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/8cf3f39c-ee82-409d-b499-7cf321a54b04/01_metodo_vap.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 31058620
    and status = 'active';

  if v_exact_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: PDF publicado divergiu do snapshot';
  end if;

  select count(*) into v_module_count
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  if v_module_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: treinamento já possui módulos; encontrado %',
      v_module_count;
  end if;

  select count(*) into v_lesson_count
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  if v_lesson_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: treinamento já possui aulas; encontrado %',
      v_lesson_count;
  end if;

  select count(*) into v_progress_count
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  if v_progress_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5E_PREFLIGHT_FAILED: treinamento possui progresso inesperado; encontrado %',
      v_progress_count;
  end if;
end;
$preflight$;

-- ============================================================================
-- 1. MÓDULOS
-- ============================================================================

insert into public.training_library_modules (
  id, organization_id, training_id, sequence_no, title, description, status, metadata
)
values

(
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  1,
  'O que é o Método VAP?',
  'Fundamentos, pilares, diferenciais e aplicação prática do sistema VAP.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  2,
  'Mentalidade do VAP',
  'Base psicológica, crenças, disciplina, resiliência e construção de uma mentalidade de alta performance.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  3,
  'Valor e Venda',
  'Construção, comunicação e ampliação do valor percebido antes da discussão de preço.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  4,
  'Líder Eficaz Independente do Cenário',
  'Autoconhecimento, estilos de liderança, decisão, inteligência emocional e equipes de alta performance.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  5,
  'Perfis Comportamentais DISC',
  'Leitura de perfis, competências comportamentais, desenvolvimento e adaptação da comunicação.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  6,
  'Neurovendas',
  'Aplicação ética de princípios de neurociência, decisão, AIDA neurológico e gatilhos mentais.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  7,
  'Copywriting',
  'Estratégia de comunicação persuasiva, fórmulas, redes sociais e vendas de alto valor.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  8,
  'As Etapas da Venda',
  'Prospecção, abordagem, SPIN, argumentação, negociação, fechamento e pós-venda.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  9,
  'Contornando Objeções',
  'Compreensão das objeções, metodologia CALMA, reenquadramento, timing, autoridade e prática.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 90,
    'structured_lesson_count', 9,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  10,
  'IA em Vendas',
  'Uso de inteligência artificial para pesquisa, personalização, automação, atendimento e evolução do processo comercial.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 50,
    'structured_lesson_count', 5,
    'content_model_version', 'fase5e-v1'
  )
),
(
  '0920101e-ee38-51e6-8c02-a7d6e439a781'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  11,
  'Venda Persuasiva',
  'Módulo extra sobre persuasão ética, comunicação não-verbal, storytelling e fechamento avançado.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 40,
    'structured_lesson_count', 4,
    'content_model_version', 'fase5e-v1'
  )
);

-- ============================================================================
-- 2. AULAS
-- ============================================================================

insert into public.training_library_lessons (
  id, organization_id, training_id, module_id, sequence_no,
  title, description, lesson_type, duration_minutes,
  is_required, status, metadata
)
values

(
  'e4183ed3-2d2d-5499-a294-63e48a48f67e'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  1,
  'Introdução ao Método VAP',
  'Apresenta o sistema VAP como processo estruturado de alta performance em vendas.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(8),
    'source_module_sequence', 1,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '73bd9c2d-794f-5ab5-9444-14a4b3bfc586'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  2,
  'Os Pilares do VAP',
  'Explora os pilares interdependentes que sustentam a aplicação do método.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(9),
    'source_module_sequence', 1,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'd59f8992-1c9a-59cf-8065-d47fca7cb94a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  3,
  'Como o VAP se Diferencia',
  'Compara o método com abordagens isoladas e reforça a importância de processo replicável.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(10),
    'source_module_sequence', 1,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'b60063e2-adb9-50d5-aec6-87320810ac7f'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  4,
  'Aplicação Prática do Método VAP',
  'Mostra como levar o método do conceito para a rotina comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(11),
    'source_module_sequence', 1,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '12a39e63-b2df-5d28-9ce7-acbe805d21c6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'a8bc4c32-c52b-5dfa-9ffc-d3a9059824a8'::uuid,
  5,
  'Cases de Sucesso Usando o VAP',
  'Conecta os fundamentos do método a resultados e experiências apresentadas no material.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(12),
    'source_module_sequence', 1,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '1c6f4600-f9ab-571b-b436-4eb08d2a35b8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  1,
  'Como É a Mentalidade do VAP?',
  'Apresenta os pilares psicológicos da mentalidade de alta performance.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(18),
    'source_module_sequence', 2,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '9da50584-f717-5b5c-bc27-6f6c946c3e21'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  2,
  'Características do Vendedor com Mentalidade Vencedora',
  'Identifica comportamentos e hábitos que podem ser desenvolvidos pelo vendedor.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(19),
    'source_module_sequence', 2,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'a5130e95-fea2-5884-966e-27c25c9301a4'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  3,
  'Crenças Limitantes x Crenças Fortalecedoras',
  'Trabalha identificação, questionamento e substituição de crenças que afetam o desempenho.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(20),
    'source_module_sequence', 2,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '9620f30a-0785-5582-aab7-8ac41bc9fba3'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  4,
  'Como Desenvolver uma Mentalidade Inabalável',
  'Apresenta práticas para sustentar desempenho diante de pressão e dificuldade.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(21),
    'source_module_sequence', 2,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '448281e6-0909-5b0a-a689-269c0175f0bf'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'e5c2c10d-d2e6-537b-9f7d-fd347e856472'::uuid,
  5,
  'Disciplina, Resiliência e Motivação no Processo de Vendas',
  'Integra a tríade que sustenta consistência durante o processo comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(22),
    'source_module_sequence', 2,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '20d8e991-d8b7-5d71-8f78-796a90ba8639'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  1,
  'Definição de Valor',
  'Diferencia valor percebido e valor intrínseco no processo de venda.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(28),
    'source_module_sequence', 3,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '535c2e8b-cf56-551e-8d2f-4ab8c50ed4f8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  2,
  'Valor x Preço',
  'Mostra por que objeções de preço frequentemente indicam valor insuficientemente construído.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(29),
    'source_module_sequence', 3,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '8d06e7ee-fab8-547a-a095-9f6f98999d68'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  3,
  'Aumentar o Valor Percebido',
  'Apresenta estratégias para elevar a percepção de valor sem alterar o produto.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(30),
    'source_module_sequence', 3,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'b8d608e1-daf9-56d7-9e59-b40456a1f21d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  4,
  'Agregar Valor ao Produto/Serviço',
  'Explora formas de ampliar a entrega percebida ao longo da jornada do cliente.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(31),
    'source_module_sequence', 3,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '25fcbc7f-2140-5388-bf87-06c6004f1805'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '59910d18-212f-5cb1-963f-5accfebb630e'::uuid,
  5,
  'O VAP na Construção do Valor',
  'Integra ferramentas de valor em um processo comercial coerente.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(32),
    'source_module_sequence', 3,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'c5bacfee-513a-5cf2-b20e-7b6891b61173'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  1,
  'Autoconhecimento como Base da Liderança',
  'Usa autoconhecimento como fundamento para liderança autêntica e adaptável.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(38),
    'source_module_sequence', 4,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '4f214a8d-4404-5d13-b054-67c3b563a06c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  2,
  'Características dos Grandes Líderes de Vendas',
  'Explora características que diferenciam liderança de simples gestão de tarefas.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(39),
    'source_module_sequence', 4,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'f323a414-90e9-5d6c-a545-f562fae08ae1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  3,
  'Estilos de Liderança',
  'Apresenta estilos de liderança e a importância de adaptação ao contexto.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(40),
    'source_module_sequence', 4,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '2a3d4e96-ae4c-5c9b-9988-0d030202a9d0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  4,
  'Tomada de Decisão e Inteligência Emocional',
  'Trabalha decisão sob pressão com estrutura e inteligência emocional.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(41),
    'source_module_sequence', 4,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '0c4f7481-55a5-5962-bce4-6950b37f1f46'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'c27e9efb-3740-59cc-9b31-8652706a325c'::uuid,
  5,
  'Equipes de Alta Performance',
  'Apresenta fundamentos para construir times consistentes e autônomos.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(42),
    'source_module_sequence', 4,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'd007d897-23be-593b-8938-5facaa48442b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  1,
  'Fundamentos DISC: a Origem da Metodologia',
  'Apresenta o DISC como leitura de comportamento observável aplicada à interação comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(48),
    'source_module_sequence', 5,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '960fada6-2a28-53d9-a95a-c360af6f54bd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  2,
  'Perfis D, I, S e C',
  'Explora os quatro perfis e como cada um tende a processar decisões e comunicação.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(49,50,51,52),
    'source_module_sequence', 5,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'c6d3b804-bb2c-57ff-9b4c-6a23fe5f5185'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  3,
  'As 16 Competências Comportamentais',
  'Expande os perfis principais para competências e pontos de desenvolvimento.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(53),
    'source_module_sequence', 5,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '53fe8616-3069-51af-9afb-5529c7d2bcee'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  4,
  'Planos de Desenvolvimento por Perfil',
  'Transforma diagnóstico comportamental em ações práticas de desenvolvimento.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(54),
    'source_module_sequence', 5,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '82ab47dd-22df-5b5e-8ae2-e274dc719092'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  'b180e0c1-b9d0-58f9-858e-e9b1c38687a6'::uuid,
  5,
  'Método Espelho Comportamental',
  'Aplica adaptação consciente da comunicação ao perfil percebido do cliente.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(55,56),
    'source_module_sequence', 5,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '0ecc9e72-fa09-58a5-a851-a981cbd653cc'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  1,
  'O que É Neurovendas',
  'Introduz a aplicação ética de princípios de neurociência ao processo comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(58),
    'source_module_sequence', 6,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '7f869447-c32b-5ac6-ab58-fb1ac5d510a0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  2,
  'Os 3 Cérebros no Processo de Compra',
  'Explica como diferentes sistemas cerebrais participam da decisão de compra.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(59),
    'source_module_sequence', 6,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'ebb3f44b-e355-53bc-a294-87fc6561e1d9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  3,
  'Neurociência na Tomada de Decisão',
  'Relaciona estados neuroquímicos e processamento de decisão à experiência comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(60),
    'source_module_sequence', 6,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '6a9bb606-b693-5b94-a826-982a0b1bcfbf'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  4,
  'Modelo AIDA Neurológico',
  'Reinterpreta Atenção, Interesse, Desejo e Ação sob a ótica da neurociência.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(61,62),
    'source_module_sequence', 6,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '6ee2d4e2-4849-560c-86c0-52db0290eb4a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '46605015-bc2a-5210-8930-f6b2f37906b1'::uuid,
  5,
  'Os 12 Gatilhos Mentais em Vendas',
  'Organiza gatilhos de comunicação com ênfase em uso ético e verdadeiro.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(62,63,64,65),
    'source_module_sequence', 6,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '27bdfd9e-c811-5a6d-a0dc-97f9aae54a3c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  1,
  'O Principal Objetivo do Copywriting',
  'Apresenta copywriting como comunicação persuasiva orientada à ação comercial.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(69,70),
    'source_module_sequence', 7,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '2515b682-9ff5-5c4e-8fcf-b4e7abab3203'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  2,
  'Estratégia de Copywriting VAP',
  'Trabalha voz, personalidade, contexto e coerência estratégica da mensagem.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(71),
    'source_module_sequence', 7,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '506a2488-a392-5c65-b87f-31fc9faf7058'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  3,
  'Fórmulas de Copywriting',
  'Apresenta estruturas como AIDA e PAS para organizar mensagens.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(72),
    'source_module_sequence', 7,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '0ed2797e-4500-51d9-9aec-eaf666876075'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  4,
  'Copy para Redes Sociais e Anúncios',
  'Aplica princípios de copy a headlines, posts e comunicação de mídia.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(73),
    'source_module_sequence', 7,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '6388f495-2c6f-5189-b628-b41aae3d97b6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '61e50611-02ab-5ebb-b119-39f98cc69521'::uuid,
  5,
  'Copywriting para Vendas de Alto Valor',
  'Adapta a comunicação a contextos B2B e decisões de maior ticket.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(74),
    'source_module_sequence', 7,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'c4ed3f6e-1d9e-55e9-9ac2-ce71a1a6c904'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  1,
  'Prospecção Eficiente',
  'Estrutura prospecção a partir do perfil de cliente ideal e priorização.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(78),
    'source_module_sequence', 8,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '5c5ac5ea-1278-5e81-97ee-0f7809f162cd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  2,
  'Abordagem – Rapport e Comunicação',
  'Trabalha primeira impressão, rapport e comunicação verbal e não-verbal.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(79),
    'source_module_sequence', 8,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '38dd8e28-c807-58da-a816-1f54cabf0e63'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  3,
  'SPIN Selling',
  'Aplica perguntas de Situação, Problema, Implicação e Necessidade de Solução.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(80),
    'source_module_sequence', 8,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'd60d7991-ebcb-514d-98e2-f0440ac542d1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  4,
  'Argumentação CAB e Negociação',
  'Integra Característica, Vantagem e Benefício com negociação orientada a valor.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(81),
    'source_module_sequence', 8,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '5c62b0ea-6c21-560e-8ca8-0b3ef0444ac4'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2aac94e8-5d63-50c0-be33-041890c19dbd'::uuid,
  5,
  'Fechamento e Pós-Venda',
  'Apresenta técnicas de fechamento e continuidade do relacionamento após a decisão.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(82,83,84),
    'source_module_sequence', 8,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '6e68a758-fb30-53e5-a883-c96b59d3206f'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  1,
  'O que São Objeções e Por que Ocorrem',
  'Diferencia objeção de rejeição e trata a resistência como informação útil.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(87),
    'source_module_sequence', 9,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '78d7d4da-1900-5b62-b0e3-49b41518b94a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  2,
  'As 6 Objeções Universais',
  'Mapeia objeções recorrentes e interpreta o significado por trás de cada uma.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(88,89,90),
    'source_module_sequence', 9,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'f3c67e45-0798-5641-aeac-273bdfc97b15'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  3,
  'Metodologia CALMA: C – Compreender',
  'Apresenta a escuta completa como primeira etapa do método CALMA.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(91),
    'source_module_sequence', 9,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '01212daa-542c-51c4-97c9-6086334e5bf7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  4,
  'Metodologia CALMA: A – Acolher e L – Levantar',
  'Valida a preocupação e aprofunda sua raiz com perguntas específicas.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(92),
    'source_module_sequence', 9,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '43d8d34c-4482-5767-9f38-0cc510cc2fb8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  5,
  'Metodologia CALMA: M – Mostrar e A – Avançar',
  'Conecta a solução à dor revelada e conduz a um próximo passo concreto.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(93),
    'source_module_sequence', 9,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '2f6882c7-994f-5a13-b920-ce38ca9a75d5'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  6,
  'Técnicas Práticas: Reenquadramento e Comparação de Valor',
  'Muda a perspectiva da objeção e quantifica valor e impacto para apoiar a decisão.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(94,95),
    'source_module_sequence', 9,
    'source_lesson_sequence', 6,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '9c75272d-2b97-5fa1-83ac-ef081ad07395'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  7,
  'Objeções de Timing: Criando Urgência Sem Pressão',
  'Trabalha adiamento, prazos e custo da inação sem recorrer a falsa urgência.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(96),
    'source_module_sequence', 9,
    'source_lesson_sequence', 7,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '75d2c3cd-3f0c-5221-9ce5-974e39b12c8c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  8,
  'Objeções de Autoridade: Navegando Múltiplos Tomadores de Decisão',
  'Organiza o tratamento de decisões compartilhadas e múltiplos decisores.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(97),
    'source_module_sequence', 9,
    'source_lesson_sequence', 8,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '23183b1d-ce03-5fa7-99a5-994f20331a5a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '978efabf-0f4d-5d13-afe7-e450beadcdf7'::uuid,
  9,
  'Prática e Consolidação: Dominando o Contorno de Objeções',
  'Consolida o conteúdo por meio de exercícios e role-play.',
  'interactive',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(98,99,100),
    'source_module_sequence', 9,
    'source_lesson_sequence', 9,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '7240b0d2-7aac-5975-81d1-0ff7c1add1c0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  1,
  'Como a IA Potencializa suas Vendas',
  'Diferencia o que pode ser potencializado por IA do que continua exigindo atuação humana.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(101),
    'source_module_sequence', 10,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'f773e896-59e2-5663-a5e3-35806304ca92'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  2,
  'Ferramentas de IA por Categoria',
  'Organiza aplicações de IA em CRM, prospecção, análise, conteúdo, automação e atendimento.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(102),
    'source_module_sequence', 10,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '195841c0-c371-50f3-ac10-70813d31051a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  3,
  'IA na Personalização',
  'Aplica IA à personalização de mensagens em diferentes níveis de contexto.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(103),
    'source_module_sequence', 10,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'ca422a7e-58ea-5377-b7b0-f364291044e0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  4,
  'Chatbots e Assistentes Virtuais',
  'Explora qualificação, atendimento e automação inicial com assistentes inteligentes.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(104),
    'source_module_sequence', 10,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'b3facd62-f746-5e42-9297-96aa212ab1b8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '2862f808-ea0c-5f44-ab3d-871d05451fe8'::uuid,
  5,
  'Futuro das Vendas e Roadmap de Implementação',
  'Conecta tendências, seleção de ferramentas, métricas e plano de implementação.',
  'interactive',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(105,106,107,108),
    'source_module_sequence', 10,
    'source_lesson_sequence', 5,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '4ee41919-af82-5b48-9470-f04f170918fb'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '0920101e-ee38-51e6-8c02-a7d6e439a781'::uuid,
  1,
  'Fundamentos da Persuasão Ética',
  'Diferencia persuasão de manipulação e apresenta princípios de influência usados com transparência.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(112),
    'source_module_sequence', 11,
    'source_lesson_sequence', 1,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'c1412f1c-6848-5488-828e-3cdcd68a07c5'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '0920101e-ee38-51e6-8c02-a7d6e439a781'::uuid,
  2,
  'Comunicação Não-Verbal e Presença Persuasiva',
  'Trabalha presença, tom, linguagem corporal e adaptação da comunicação.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(113),
    'source_module_sequence', 11,
    'source_lesson_sequence', 2,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  '8182ae96-312a-5026-8e8e-6e6ba083e9c7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '0920101e-ee38-51e6-8c02-a7d6e439a781'::uuid,
  3,
  'Storytelling Persuasivo',
  'Estrutura narrativas comerciais com o cliente como protagonista da transformação.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(114),
    'source_module_sequence', 11,
    'source_lesson_sequence', 3,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
),
(
  'e8a4ffb7-76c6-52b6-9d37-65f1949d238c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid,
  '0920101e-ee38-51e6-8c02-a7d6e439a781'::uuid,
  4,
  'Técnicas Avançadas de Fechamento',
  'Explora sinais de prontidão, técnicas de fechamento, recuperação e follow-up.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
    'source_pdf_pages', jsonb_build_array(115,116,117,118,119),
    'source_module_sequence', 11,
    'source_lesson_sequence', 4,
    'duration_basis', 'instructional_estimate_10_minutes',
    'content_model_version', 'fase5e-v1'
  )
);

-- ============================================================================
-- 3. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'module_count', 11,
  'lesson_count', 58,
  'estimated_duration_minutes', 580,
  'estimated_duration_basis', '10_minutes_per_structured_lesson',
  'content_model_version', 'fase5e-v1',
  'source_primary_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
  'source_primary_sha256', 'D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84',
  'source_declared_module_count', 11,
  'source_declared_lesson_count', 55,
  'source_structured_lesson_count', 58,
  'source_lesson_count_discrepancy', true,
  'source_lesson_count_note',
    'A fonte declara 55 aulas na capa/sumário, mas a versão publicada contém 58 seções de aula explícitas; a experiência preserva as 58.'
)
where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

-- ============================================================================
-- 4. PÓS-CONDIÇÕES FAIL-CLOSED
-- ============================================================================

do $postconditions$
declare
  v_modules bigint;
  v_lessons bigint;
  v_required_lessons bigint;
  v_duration bigint;
  v_progress bigint;
  v_assets bigint;
  v_exact_asset bigint;
  v_learning_experience boolean;
  v_module_count_meta integer;
  v_lesson_count_meta integer;
  v_duration_meta integer;
  v_content_model_version text;
  v_source_primary_asset_id text;
  v_source_primary_sha256 text;
  v_source_declared_lesson_count integer;
  v_source_structured_lesson_count integer;
  v_source_lesson_count_discrepancy boolean;
begin
  select count(*) into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  select count(*) into v_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  select count(*) into v_required_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and is_required = true
    and status = 'published';

  select coalesce(sum(duration_minutes), 0) into v_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published';

  select count(*) into v_progress
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  select count(*) into v_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid;

  select count(*) into v_exact_asset
  from public.training_library_assets
  where id = 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and sequence_no = 1
    and asset_type = 'primary'
    and display_name = 'Método VAP – Vendedor de Alta Performance'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/8cf3f39c-ee82-409d-b499-7cf321a54b04/01_metodo_vap.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 31058620
    and status = 'active';

  select
    coalesce((metadata ->> 'learning_experience')::boolean, false),
    coalesce((metadata ->> 'module_count')::integer, 0),
    coalesce((metadata ->> 'lesson_count')::integer, 0),
    coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0),
    metadata ->> 'content_model_version',
    metadata ->> 'source_primary_asset_id',
    metadata ->> 'source_primary_sha256',
    coalesce((metadata ->> 'source_declared_lesson_count')::integer, 0),
    coalesce((metadata ->> 'source_structured_lesson_count')::integer, 0),
    coalesce((metadata ->> 'source_lesson_count_discrepancy')::boolean, false)
  into
    v_learning_experience,
    v_module_count_meta,
    v_lesson_count_meta,
    v_duration_meta,
    v_content_model_version,
    v_source_primary_asset_id,
    v_source_primary_sha256,
    v_source_declared_lesson_count,
    v_source_structured_lesson_count,
    v_source_lesson_count_discrepancy
  from public.training_library_items
  where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_modules <> 11 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: esperado 11 módulos; encontrado %', v_modules;
  end if;

  if v_lessons <> 58 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: esperado 58 aulas estruturadas; encontrado %', v_lessons;
  end if;

  if v_required_lessons <> 58 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: esperado 58 aulas obrigatórias publicadas; encontrado %', v_required_lessons;
  end if;

  if v_duration <> 580 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: duração estimada esperada 580 minutos; encontrado %', v_duration;
  end if;

  if v_progress <> 0 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: progresso artificial detectado; encontrado %', v_progress;
  end if;

  if v_assets <> 1 or v_exact_asset <> 1 then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: asset publicado foi alterado';
  end if;

  if coalesce(v_learning_experience, false) = false then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: treinamento não marcado como experiência de aprendizagem';
  end if;

  if v_module_count_meta <> 11
     or v_lesson_count_meta <> 58
     or v_duration_meta <> 580
     or v_content_model_version <> 'fase5e-v1'
     or v_source_primary_asset_id <> 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'
     or v_source_primary_sha256 <> 'D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84'
     or v_source_declared_lesson_count <> 55
     or v_source_structured_lesson_count <> 58
     or v_source_lesson_count_discrepancy <> true then
    raise exception 'TRAINING_LIBRARY_PHASE5E_POSTCONDITION_FAILED: metadados finais divergiram';
  end if;
end;
$postconditions$;
