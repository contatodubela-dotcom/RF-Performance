-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5C
-- Escala da experiência de aprendizagem: Objeções e Fechamento
--
-- Objetivos:
--   1. Estruturar o treinamento existente em 5 módulos e 12 aulas.
--   2. Preservar integralmente o PDF e o PPTX já cadastrados como materiais.
--   3. Manter a experiência alinhada ao conteúdo efetivamente publicado.
--   4. Explicitar a diferença entre:
--      a) técnica de quebra da objeção em 3 passos; e
--      b) fluxo operacional completo em 5 passos.
--   5. Não criar progresso artificial para nenhum usuário.
--   6. Falhar fechado se o estado remoto divergir do snapshot validado.
--
-- Fontes publicadas validadas:
--   PDF
--     asset_id: f606df67-6a1f-4232-9dfd-c846e6b163e9
--     arquivo: 01_objecoes_e_fechamento.pdf
--     tamanho: 468367 bytes
--     sha256 externo validado:
--       D90B7C4B0EDC1154E1767E0E7E48C2395D0B1752C1A3D870F4A92F6D1BD15238
--
--   PPTX
--     asset_id: 7be304f7-9709-4a1d-a6c0-0b27040af36b
--     arquivo: 02_objecoes_e_fechamento.pptx
--     tamanho: 1769444 bytes
--     sha256 externo validado:
--       2088B0A7D81832705DC2EAFD687054B9E25A50361F8DDD9B6E970DEE1FE35E2E
-- ============================================================================


-- ============================================================================
-- 0. PREFLIGHT FAIL-CLOSED
-- ============================================================================

do $preflight$
declare
  v_item_count bigint;
  v_asset_count bigint;
  v_exact_workbook_count bigint;
  v_exact_slides_count bigint;
  v_module_count bigint;
  v_lesson_count bigint;
  v_progress_count bigint;
begin
  if not exists (
    select 1
    from public.organizations
    where id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and slug = 'rf-consorcios'
      and status = 'active'
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: RF Consórcios ativa não encontrada';
  end if;

  select count(*)
  into v_item_count
  from public.training_library_items
  where id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 3
    and title = 'Objeções e Fechamento'
    and description = 'Treinamento para compreender objeções, responder com método e reconhecer o momento adequado de conduzir o cliente ao fechamento.'
    and category = 'sales_method'
    and to_jsonb(audience_roles) = '["director","supervisor","salesperson"]'::jsonb
    and status = 'published'
    and is_featured = false
    and metadata = '{}'::jsonb;

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: item Objeções e Fechamento divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
  into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  if v_asset_count <> 2 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: esperado 2 assets; encontrado %',
      v_asset_count;
  end if;

  select count(*)
  into v_exact_workbook_count
  from public.training_library_assets
  where id = 'f606df67-6a1f-4232-9dfd-c846e6b163e9'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – Objeções e Fechamento'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/01_objecoes_e_fechamento.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 468367
    and status = 'active';

  if v_exact_workbook_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: PDF publicado divergiu do snapshot';
  end if;

  select count(*)
  into v_exact_slides_count
  from public.training_library_assets
  where id = '7be304f7-9709-4a1d-a6c0-0b27040af36b'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and sequence_no = 2
    and asset_type = 'slides'
    and display_name = 'Apresentação – Objeções e Fechamento'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/02_objecoes_e_fechamento.pptx'
    and mime_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    and file_size_bytes = 1769444
    and status = 'active';

  if v_exact_slides_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: PPTX publicado divergiu do snapshot';
  end if;

  select count(*)
  into v_module_count
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  if v_module_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: treinamento já possui módulos; encontrado %',
      v_module_count;
  end if;

  select count(*)
  into v_lesson_count
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  if v_lesson_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: treinamento já possui aulas; encontrado %',
      v_lesson_count;
  end if;

  select count(*)
  into v_progress_count
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  if v_progress_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_PREFLIGHT_FAILED: treinamento possui progresso inesperado; encontrado %',
      v_progress_count;
  end if;
end;
$preflight$;


-- ============================================================================
-- 1. MÓDULOS
-- ============================================================================

insert into public.training_library_modules (
  id,
  organization_id,
  training_id,
  sequence_no,
  title,
  description,
  status,
  metadata
)
values
(
  'b7e31c1e-8a41-5e87-8d90-db47da10c118'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  1,
  'Mentalidade e sinais de compra',
  'Reposiciona a objeção como informação a ser diagnosticada e desenvolve a leitura dos sinais de que o cliente já está próximo da decisão.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 26,
    'content_model_version', 'fase5c-v1'
  )
),
(
  '2287a71c-8d7a-5017-96b0-a1f406f0b555'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  2,
  'Método de tratamento da objeção',
  'Ensina a estrutura de quebra da objeção em três passos e o fluxo operacional ampliado para conduzir diagnóstico, realidade, fechamento e próximo passo.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 32,
    'content_model_version', 'fase5c-v1'
  )
),
(
  'a146a436-475e-57bd-8f0d-b17d135313d7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  3,
  'Diagnóstico e realidade',
  'Aplica o diagnóstico SRV, a técnica do “Por Não” e comparações reais para ajudar o cliente a enxergar limites, alternativas e distância até o objetivo.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 30,
    'content_model_version', 'fase5c-v1'
  )
),
(
  '98a9a0ce-9d46-570b-8dcd-fb75aa587957'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  4,
  'Scripts e fechamento responsável',
  'Transforma objeções recorrentes em perguntas de diagnóstico, organiza o atendimento e trabalha confronto respeitoso, urgência ética e condução ao fechamento.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 34,
    'content_model_version', 'fase5c-v1'
  )
),
(
  '218cc86e-fa3c-5504-a7b5-a3ff05cfd770'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  5,
  'Prática, retomada e execução',
  'Consolida o aprendizado em role-play, checklist de observação, retomada de leads e plano de ação de sete dias.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 28,
    'content_model_version', 'fase5c-v1'
  )
);


-- ============================================================================
-- 2. AULAS
-- ============================================================================

insert into public.training_library_lessons (
  id,
  organization_id,
  training_id,
  module_id,
  sequence_no,
  title,
  description,
  lesson_type,
  duration_minutes,
  is_required,
  status,
  metadata
)
values

-- --------------------------------------------------------------------------
-- Módulo 1 — Mentalidade e sinais de compra
-- --------------------------------------------------------------------------

(
  'c68a7a57-4f08-58b5-9557-67b51a5d9f06'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  'b7e31c1e-8a41-5e87-8d90-db47da10c118'::uuid,
  1,
  'Objeção não é rejeição',
  'Mude a leitura da objeção: em vez de responder automaticamente, identifique o ponto que o cliente ainda precisa esclarecer para decidir.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(1, 2, 3),
    'source_slides', jsonb_build_array(1, 2, 3, 4, 5),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Interpretar a objeção como informação de diagnóstico e abandonar o reflexo de responder antes de entender.',
    'key_points', jsonb_build_array(
      'Objeção não deve ser tratada automaticamente como rejeição.',
      'O cliente que continua dialogando está revelando o ponto que precisa ser esclarecido.',
      'A resposta produtiva começa por entender a mensagem por trás da objeção.',
      'Seja menos explicador e mais perguntador.'
    ),
    'examples', jsonb_build_array(
      jsonb_build_object('objection', 'Tenho pressa', 'behind', 'Quero resolver, mas ainda não encontrei um caminho viável.'),
      jsonb_build_object('objection', 'Vou pensar', 'behind', 'Ainda falta clareza ou segurança para decidir.'),
      jsonb_build_object('objection', 'Preciso falar com minha esposa ou marido', 'behind', 'Pode existir decisão compartilhada ou uma dúvida ainda não revelada.'),
      jsonb_build_object('objection', 'Já tive experiência ruim', 'behind', 'Quero segurança para não repetir a experiência anterior.')
    ),
    'callout',
      'Explique somente depois de descobrir o problema real.'
  )
),
(
  'e36d1e36-cd72-5efa-8831-a476002c4bda'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  'b7e31c1e-8a41-5e87-8d90-db47da10c118'::uuid,
  2,
  'Sinais de compra e hora de fechar',
  'Reconheça perguntas de execução, uso do crédito e estratégia futura como sinais de que o cliente pode estar mais perto da decisão do que aparenta.',
  'text',
  14,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(2, 3),
    'source_slides', jsonb_build_array(6, 7, 8),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Identificar sinais de compra e substituir explicações longas por perguntas que testem prontidão e conduzam o próximo passo.',
    'key_points', jsonb_build_array(
      'Perguntas sobre o futuro podem revelar projeção de posse e intenção de compra.',
      'O vendedor pode ficar atrasado no fechamento se continuar apenas explicando.',
      'Sinal de compra deve gerar condução, não uma nova aula técnica.',
      'Treino constante reduz o piloto automático de resposta.'
    ),
    'signals', jsonb_build_array(
      'Perguntas sobre aumentar lance no futuro.',
      'Perguntas sobre uso do crédito após contemplação.',
      'Perguntas sobre combinação de bens ou execução do projeto.',
      'Perguntas práticas sobre pagamento, documentação ou próximo passo.'
    )
  )
),

-- --------------------------------------------------------------------------
-- Módulo 2 — Método de tratamento da objeção
-- --------------------------------------------------------------------------

(
  '26b34449-b947-5b02-92c5-90f87a818691'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '2287a71c-8d7a-5017-96b0-a1f406f0b555'::uuid,
  1,
  'Técnica de 3 passos: Neutralizar, Entender e Resolver',
  'Use a estrutura central de quebra da objeção para reduzir resistência, descobrir o motivo real e apresentar a solução em forma de pergunta.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(3),
    'source_slides', jsonb_build_array(9, 10),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Aplicar a sequência Neutralizar → Entender → Resolver sem confrontar o cliente com argumentos antes do diagnóstico.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Neutralizar', 'focus', 'reduzir defesa e mostrar entendimento'),
      jsonb_build_object('sequence', 2, 'name', 'Entender', 'focus', 'investigar o problema real com perguntas'),
      jsonb_build_object('sequence', 3, 'name', 'Resolver', 'focus', 'oferecer solução em forma de pergunta de fechamento')
    ),
    'key_points', jsonb_build_array(
      'Concorde com o sentido da objeção antes de tentar corrigi-la.',
      'Nunca explique antes de entender.',
      'Use perguntas para revelar o que realmente está impedindo a decisão.',
      'Mantenha o cliente participando da solução.'
    )
  )
),
(
  '94da52fa-592a-5eee-9c03-0027daddb1d3'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '2287a71c-8d7a-5017-96b0-a1f406f0b555'::uuid,
  2,
  'Fluxo operacional: da objeção ao próximo passo',
  'Amplie a técnica central para um atendimento completo: neutralize, entenda, traga realidade, teste o fechamento e defina a ação.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(3),
    'source_slides', jsonb_build_array(9, 10),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Distinguir a técnica de quebra da objeção do fluxo operacional ampliado usado para conduzir o atendimento até uma ação clara.',
    'distinction',
      'Os 3 passos — Neutralizar, Entender e Resolver — formam o núcleo da quebra da objeção. O fluxo de 5 passos do PDF amplia essa lógica para Neutralizar, Entender, Realidade, Fechamento e Ação.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Neutralizar', 'focus', 'baixar defesa'),
      jsonb_build_object('sequence', 2, 'name', 'Entender', 'focus', 'descobrir o motivo real'),
      jsonb_build_object('sequence', 3, 'name', 'Realidade', 'focus', 'comparar objetivo, condição atual e alternativas reais'),
      jsonb_build_object('sequence', 4, 'name', 'Fechamento', 'focus', 'testar interesse antes de explicar demais'),
      jsonb_build_object('sequence', 5, 'name', 'Ação', 'focus', 'definir próximo passo claro')
    )
  )
),
(
  '3a797238-be2a-5be9-94d4-e2566082a076'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '2287a71c-8d7a-5017-96b0-a1f406f0b555'::uuid,
  3,
  'Menos explicador, mais perguntador',
  'Substitua respostas automáticas por perguntas que revelam condição, alternativa, prioridade e motivo real da objeção.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(3),
    'source_slides', jsonb_build_array(8, 9, 10),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Transformar a primeira reação à objeção em uma pergunta de diagnóstico em vez de uma defesa do produto.',
    'automatic_vs_professional', jsonb_build_array(
      jsonb_build_object(
        'automatic', 'Financiamento é ruim, você vai pagar muito juros.',
        'professional', 'Entendo. Quem tem pressa olha mesmo para financiamento. Você já aprovou? Qual ponto travou hoje?'
      ),
      jsonb_build_object(
        'automatic', 'Consórcio é melhor que comprar à vista.',
        'professional', 'Comprar à vista é excelente. Por que você ainda não comprou, mesmo tendo o recurso?'
      )
    ),
    'practice',
      'Em cada objeção apresentada no treino, formule pelo menos três perguntas antes de explicar a solução.'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 3 — Diagnóstico e realidade
-- --------------------------------------------------------------------------

(
  'eb829131-098e-591e-a75a-ff3cce1060b5'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  'a146a436-475e-57bd-8f0d-b17d135313d7'::uuid,
  1,
  'Diagnóstico SRV: crédito, realidade e velocidade',
  'Levante o tamanho real do objetivo, a parcela possível e o recurso disponível para construir uma estratégia coerente e evitar promessas sem base.',
  'text',
  14,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(3, 4),
    'source_slides', jsonb_build_array(11),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Usar o diagnóstico SRV para dimensionar objetivo, capacidade mensal e velocidade possível antes de oferecer uma solução.',
    'framework', jsonb_build_array(
      jsonb_build_object(
        'letter', 'S',
        'name', 'Sonho / Crédito',
        'question', 'Qual crédito você precisa para comprar o bem que deseja?',
        'use', 'dimensionar o tamanho real da conquista'
      ),
      jsonb_build_object(
        'letter', 'R',
        'name', 'Realidade / Parcela',
        'question', 'Qual parcela cabe com segurança no seu orçamento?',
        'use', 'comparar as alternativas que cabem de verdade'
      ),
      jsonb_build_object(
        'letter', 'V',
        'name', 'Velocidade / Entrada ou lance',
        'question', 'Quanto você tem hoje para entrada, lance ou recurso inicial?',
        'use', 'estimar velocidade possível sem prometer prazo'
      )
    ),
    'callout',
      'Sem crédito, parcela e recurso disponível, o vendedor tenta fazer mágica; com esses dados, conduz a realidade.'
  )
),
(
  'aee51e90-798b-5a69-af8f-eef48666fd32'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  'a146a436-475e-57bd-8f0d-b17d135313d7'::uuid,
  2,
  'Técnica do “Por Não” e fórmula da realidade',
  'Descubra por que a alternativa imediata não resolveu o problema e use contas simples para comparar a distância entre o objetivo e a condição atual.',
  'interactive',
  16,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(4),
    'source_slides', jsonb_build_array(11),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Investigar por que financiamento, compra imediata ou espera não resolveram e quantificar a distância atual sem criar falsa urgência.',
    'key_points', jsonb_build_array(
      'Pergunte por que a alternativa mais rápida ainda não resolveu a necessidade.',
      'Investigue entrada, parcela, juros, prazo e outras barreiras reais.',
      'Use cálculo apenas como ferramenta de clareza.',
      'Não transforme projeção em garantia e não omita variáveis relevantes.'
    ),
    'formula',
      'Crédito desejado - recurso disponível = distância atual; distância atual / valor mensal possível = tempo teórico para juntar sozinho.',
    'exercise',
      'Calcule a distância atual em um caso real e transforme o resultado em uma pergunta de reflexão, não em pressão.'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 4 — Scripts e fechamento responsável
-- --------------------------------------------------------------------------

(
  'f0480a51-7551-5eba-ac48-761611f8d554'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '98a9a0ce-9d46-570b-8dcd-fb75aa587957'::uuid,
  1,
  'Biblioteca de perguntas por objeção',
  'Use perguntas como estrutura de raciocínio para objeções recorrentes sem decorar respostas palavra por palavra.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(4, 5),
    'source_slides', jsonb_build_array(14, 15),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Selecionar perguntas de investigação adequadas para objeções frequentes e manter a ordem Neutralizar → Entender → Resolver.',
    'objections', jsonb_build_array(
      'Tenho pressa',
      'Vou pensar',
      'Preciso falar com minha esposa ou marido',
      'Prefiro financiamento',
      'Quero carta contemplada',
      'Já tive experiência ruim',
      'Não tenho entrada',
      'Só faço se garantir contemplação rápida',
      'Tenho dinheiro para comprar à vista'
    ),
    'rule',
      'Não decore os scripts palavra por palavra; domine a lógica e adapte a linguagem ao cliente.'
  )
),
(
  'a903950a-e571-5327-8246-3dd5f804dce6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '98a9a0ce-9d46-570b-8dcd-fb75aa587957'::uuid,
  2,
  'Script completo de atendimento e fechamento',
  'Organize abertura, diagnóstico, pressa, alternativas, confronto leve, fechamento e próximo passo em uma sequência adaptável.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(5),
    'source_slides', jsonb_build_array(14, 15),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Usar um trilho de atendimento sem transformar o script em leitura robótica.',
    'service_script', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'step', 'Abertura', 'focus', 'entender o que o cliente quer conquistar'),
      jsonb_build_object('sequence', 2, 'step', 'Crédito', 'focus', 'dimensionar o objetivo real'),
      jsonb_build_object('sequence', 3, 'step', 'Realidade', 'focus', 'identificar parcela confortável'),
      jsonb_build_object('sequence', 4, 'step', 'Velocidade', 'focus', 'mapear entrada, lance ou primeiro movimento'),
      jsonb_build_object('sequence', 5, 'step', 'Pressa', 'focus', 'entender prazo e impacto'),
      jsonb_build_object('sequence', 6, 'step', 'Alternativas', 'focus', 'entender o que travou nas demais opções'),
      jsonb_build_object('sequence', 7, 'step', 'Confronto leve', 'focus', 'mostrar incoerências com respeito'),
      jsonb_build_object('sequence', 8, 'step', 'Fechamento', 'focus', 'testar decisão com base no diagnóstico'),
      jsonb_build_object('sequence', 9, 'step', 'Próximo passo', 'focus', 'definir ação objetiva')
    ),
    'warning',
      'O script é um trilho de raciocínio e deve ser adaptado à linguagem do vendedor e do cliente.'
  )
),
(
  '22ccd295-ac0c-5d1e-b84f-43ef1ccc7899'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '98a9a0ce-9d46-570b-8dcd-fb75aa587957'::uuid,
  3,
  'Falar a verdade: confronto responsável e urgência ética',
  'Use perguntas diretas para ajudar o cliente a enxergar a própria situação sem constrangimento, manipulação ou promessa indevida.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(4, 5),
    'source_slides', jsonb_build_array(12, 13),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Diferenciar confronto respeitoso de pressão agressiva e aprofundar consequências somente quando forem reais e ligadas ao contexto do cliente.',
    'key_points', jsonb_build_array(
      'Confrontar com perguntas não significa ser agressivo.',
      'A intenção é gerar clareza, não constrangimento.',
      'Aprofunde consequências reais, não invente dor.',
      'Evite prometer prazo de contemplação, milagre ou condição impossível.',
      'Urgência deve nascer do contexto e da consequência reconhecida pelo cliente.'
    ),
    'practice_questions', jsonb_build_array(
      'O que está te impedindo de fazer isso agora?',
      'O que exatamente você precisa pensar para decidir com segurança?',
      'Se nada mudar, o que acontece com esse objetivo?',
      'Qual ponto precisa ficar claro para você avançar com segurança?'
    )
  )
),

-- --------------------------------------------------------------------------
-- Módulo 5 — Prática, retomada e execução
-- --------------------------------------------------------------------------

(
  'e0e5d347-16b4-5111-b4ec-af3e71c6fdd5'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '218cc86e-fa3c-5504-a7b5-a3ff05cfd770'::uuid,
  1,
  'Role-play, checklist do observador e avaliação',
  'Pratique cenários reais em trio e receba feedback sobre diagnóstico, perguntas, realidade, fechamento e definição do próximo passo.',
  'interactive',
  14,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(5, 6, 7),
    'source_slides', jsonb_build_array(16, 17),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Demonstrar a condução completa em situações de objeção e usar observação estruturada para transformar feedback em ação.',
    'exercise',
      'Em trios: vendedor, cliente e observador. Faça 5 minutos de atendimento e 3 minutos de feedback, trocando os papéis nas rodadas seguintes.',
    'practice_scenarios', jsonb_build_array(
      'Cliente com pressa e objeção “consórcio demora”.',
      'Cliente de imóvel que diz “vou pensar”.',
      'Cliente que só quer carta contemplada.',
      'Cliente com dinheiro aplicado que diz que pode comprar à vista.',
      'Cliente com experiência ruim que diz que não confia mais.'
    ),
    'observer_checklist', jsonb_build_array(
      'Neutralizou a objeção antes de argumentar.',
      'Fez pelo menos três perguntas antes de explicar.',
      'Levantou crédito, parcela e recurso disponível.',
      'Descobriu o motivo real que impede a compra.',
      'Trouxe comparação ou conta para a realidade quando pertinente.',
      'Pediu um fechamento claro.',
      'Definiu próximo passo com data, canal e responsabilidade.'
    )
  )
),
(
  'c3974563-483f-5874-b553-4e69b63eb47c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid,
  '218cc86e-fa3c-5504-a7b5-a3ff05cfd770'::uuid,
  2,
  'Plano de ação de 7 dias e retomada de leads',
  'Transforme o treinamento em execução imediata, retomando clientes antigos, classificando objeções e praticando as situações mais recorrentes.',
  'interactive',
  14,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(6, 7),
    'source_slides', jsonb_build_array(16, 17),
    'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
    'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
    'learning_objective',
      'Criar uma rotina curta de execução para aplicar SRV, perguntas de fechamento e retomada consultiva em leads que ainda não compraram.',
    'action_plan', jsonb_build_array(
      jsonb_build_object('day', 1, 'action', 'Listar 30 leads antigos que não fecharam e classificar por bem desejado.'),
      jsonb_build_object('day', 2, 'action', 'Enviar uma mensagem consultiva de retomada.'),
      jsonb_build_object('day', 3, 'action', 'Ligar para quem respondeu e descobrir o motivo real da não compra.'),
      jsonb_build_object('day', 4, 'action', 'Montar proposta com base em crédito, parcela e recurso disponível.'),
      jsonb_build_object('day', 5, 'action', 'Aplicar perguntas de fechamento e registrar objeções recorrentes.'),
      jsonb_build_object('day', 6, 'action', 'Fazer role-play com as três objeções mais frequentes.'),
      jsonb_build_object('day', 7, 'action', 'Revisar resultados, aprendizados e próximos leads.')
    ),
    'closing_message',
      'Objeção não é rejeição: escute o que está por trás, traga realidade com perguntas e conduza com clareza até o próximo passo.',
    'team_commitment',
      'Separar horário fixo semanal para treinar objeções e fechamento com a equipe.'
  )
);


-- ============================================================================
-- 3. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'module_count', 5,
  'lesson_count', 12,
  'estimated_duration_minutes', 150,
  'content_model_version', 'fase5c-v1',
  'source_workbook_asset_id', 'f606df67-6a1f-4232-9dfd-c846e6b163e9',
  'source_workbook_sha256', 'D90B7C4B0EDC1154E1767E0E7E48C2395D0B1752C1A3D870F4A92F6D1BD15238',
  'source_slides_asset_id', '7be304f7-9709-4a1d-a6c0-0b27040af36b',
  'source_slides_sha256', '2088B0A7D81832705DC2EAFD687054B9E25A50361F8DDD9B6E970DEE1FE35E2E'
)
where id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;


-- ============================================================================
-- 4. PÓS-CONDIÇÕES FAIL-CLOSED
-- ============================================================================

do $postconditions$
declare
  v_modules bigint;
  v_lessons bigint;
  v_required_lessons bigint;
  v_total_duration bigint;
  v_progress bigint;
  v_assets bigint;
  v_exact_workbook bigint;
  v_exact_slides bigint;
  v_learning_experience boolean;
  v_module_count_meta integer;
  v_lesson_count_meta integer;
  v_duration_meta integer;
  v_content_model_version text;
  v_source_workbook_asset_id text;
  v_source_workbook_sha256 text;
  v_source_slides_asset_id text;
  v_source_slides_sha256 text;
begin
  select count(*)
  into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  select count(*)
  into v_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  select count(*)
  into v_required_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and is_required = true
    and status = 'published';

  select coalesce(sum(duration_minutes), 0)
  into v_total_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and status = 'published';

  select count(*)
  into v_progress
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  select count(*)
  into v_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid;

  select count(*)
  into v_exact_workbook
  from public.training_library_assets
  where id = 'f606df67-6a1f-4232-9dfd-c846e6b163e9'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – Objeções e Fechamento'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/01_objecoes_e_fechamento.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 468367
    and status = 'active';

  select count(*)
  into v_exact_slides
  from public.training_library_assets
  where id = '7be304f7-9709-4a1d-a6c0-0b27040af36b'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and sequence_no = 2
    and asset_type = 'slides'
    and display_name = 'Apresentação – Objeções e Fechamento'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/ead6b5c7-1d8f-4c48-b597-91e665c526f8/02_objecoes_e_fechamento.pptx'
    and mime_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    and file_size_bytes = 1769444
    and status = 'active';

  select
    coalesce((metadata ->> 'learning_experience')::boolean, false),
    coalesce((metadata ->> 'module_count')::integer, 0),
    coalesce((metadata ->> 'lesson_count')::integer, 0),
    coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0),
    metadata ->> 'content_model_version',
    metadata ->> 'source_workbook_asset_id',
    metadata ->> 'source_workbook_sha256',
    metadata ->> 'source_slides_asset_id',
    metadata ->> 'source_slides_sha256'
  into
    v_learning_experience,
    v_module_count_meta,
    v_lesson_count_meta,
    v_duration_meta,
    v_content_model_version,
    v_source_workbook_asset_id,
    v_source_workbook_sha256,
    v_source_slides_asset_id,
    v_source_slides_sha256
  from public.training_library_items
  where id = 'ead6b5c7-1d8f-4c48-b597-91e665c526f8'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_modules <> 5 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: esperado 5 módulos; encontrado %',
      v_modules;
  end if;

  if v_lessons <> 12 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: esperado 12 aulas; encontrado %',
      v_lessons;
  end if;

  if v_required_lessons <> 12 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: esperado 12 aulas obrigatórias publicadas; encontrado %',
      v_required_lessons;
  end if;

  if v_total_duration <> 150 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: duração esperada 150 minutos; encontrado %',
      v_total_duration;
  end if;

  if v_progress <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: progresso artificial detectado; encontrado %',
      v_progress;
  end if;

  if v_assets <> 2 or v_exact_workbook <> 1 or v_exact_slides <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: assets publicados foram alterados';
  end if;

  if coalesce(v_learning_experience, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: treinamento não marcado como experiência de aprendizagem';
  end if;

  if v_module_count_meta <> 5
     or v_lesson_count_meta <> 12
     or v_duration_meta <> 150
     or v_content_model_version <> 'fase5c-v1'
     or v_source_workbook_asset_id <> 'f606df67-6a1f-4232-9dfd-c846e6b163e9'
     or v_source_workbook_sha256 <> 'D90B7C4B0EDC1154E1767E0E7E48C2395D0B1752C1A3D870F4A92F6D1BD15238'
     or v_source_slides_asset_id <> '7be304f7-9709-4a1d-a6c0-0b27040af36b'
     or v_source_slides_sha256 <> '2088B0A7D81832705DC2EAFD687054B9E25A50361F8DDD9B6E970DEE1FE35E2E' then
    raise exception
      'TRAINING_LIBRARY_PHASE5C_POSTCONDITION_FAILED: metadados finais divergiram';
  end if;
end;
$postconditions$;
