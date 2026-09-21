-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5A
-- Escala da experiência de aprendizagem:
-- Formação Comercial – Consórcio de Automóveis
--
-- Objetivos:
--   1. Estruturar o treinamento existente em 5 módulos e 15 aulas.
--   2. Preservar integralmente o item e os 2 assets já publicados.
--   3. Reutilizar o player e o modelo de progresso validados na Fase 4.
--   4. Não criar progresso artificial para nenhum usuário.
--   5. Falhar de forma fechada se o estado remoto divergir do preflight.
-- ============================================================================

do $preflight$
declare
  v_item_count bigint;
  v_asset_count bigint;
  v_workbook_count bigint;
  v_slides_count bigint;
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
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: RF Consórcios ativa não encontrada';
  end if;

  select count(*)
  into v_item_count
  from public.training_library_items
  where id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 1
    and title = 'Formação Comercial – Consórcio de Automóveis'
    and description = 'Treinamento comercial sobre produto, sondagem, argumentação, objeções e fechamento aplicado à venda de consórcio de automóveis.'
    and category = 'commercial_training'
    and to_jsonb(audience_roles) = '["director","supervisor","salesperson"]'::jsonb
    and status = 'published'
    and is_featured = false
    and metadata = '{}'::jsonb;

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: item Formação Comercial divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
  into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_asset_count <> 2 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: esperado exatamente 2 assets; encontrado %',
      v_asset_count;
  end if;

  select count(*)
  into v_workbook_count
  from public.training_library_assets
  where id = '2870bf53-aa3e-4f16-a0a2-9ab89da5b494'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – Formação Comercial'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/01_formacao_comercial_consorcio_automoveis.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 454601
    and status = 'active';

  if v_workbook_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: asset workbook divergiu do snapshot';
  end if;

  select count(*)
  into v_slides_count
  from public.training_library_assets
  where id = '223f1eca-fcf7-4e73-9f73-f247720aeb6f'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and sequence_no = 2
    and asset_type = 'slides'
    and display_name = 'Apresentação – Formação Comercial'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/02_formacao_comercial_consorcio_automoveis.pptx'
    and mime_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    and file_size_bytes = 12069364
    and status = 'active';

  if v_slides_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: asset slides divergiu do snapshot';
  end if;

  select count(*)
  into v_module_count
  from public.training_library_modules
  where training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_module_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: treinamento já possui % módulo(s)',
      v_module_count;
  end if;

  select count(*)
  into v_lesson_count
  from public.training_library_lessons
  where training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_lesson_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: treinamento já possui % aula(s)',
      v_lesson_count;
  end if;

  select count(*)
  into v_progress_count
  from public.training_library_lesson_progress
  where training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_progress_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_PREFLIGHT_FAILED: treinamento já possui % progresso(s)',
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
  '375afc72-8010-553f-ba38-37f100331e00'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  1,
  'Fundamentos do consórcio',
  'Constrói domínio técnico básico para explicar produto, parcela, contemplação, lances, planos e reajustes com linguagem simples e transparência.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 32,
    'scale_phase', 'fase5a'
  )
),
(
  '055b178d-7250-5813-9751-449c3d762458'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  2,
  'Processo comercial e diagnóstico',
  'Transforma as etapas da venda consultiva em comportamento observável, da preparação à sondagem estruturada com SPIN.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 38,
    'scale_phase', 'fase5a'
  )
),
(
  '903cfd30-30ee-56aa-a3e8-12fb3a232954'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  3,
  'Argumentação e valor',
  'Ensina a relacionar características do produto ao que o cliente revelou e a comparar alternativas com equilíbrio e clareza.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 24,
    'scale_phase', 'fase5a'
  )
),
(
  '9e827c53-1c35-5152-9cba-6775e58e41e8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  4,
  'Objeções, negociação e fechamento',
  'Estrutura o tratamento de objeções, a negociação responsável e a condução do fechamento sem pressão indevida nem promessa de contemplação.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 30,
    'scale_phase', 'fase5a'
  )
),
(
  '1cd18568-b10d-5fab-8d08-cf1d68846e8b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  5,
  'Pós-venda e aplicação prática',
  'Consolida acompanhamento, role-play, coaching e compromisso de aplicação para transformar conhecimento em rotina comercial.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 26,
    'scale_phase', 'fase5a'
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

-- Módulo 1 / Aula 1
(
  '9b1625c9-135b-5f22-9c3b-f4ce8c416b0d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '375afc72-8010-553f-ba38-37f100331e00'::uuid,
  1,
  'Princípios da formação comercial',
  'Entenda o objetivo da formação e a lógica produto, cliente, proposta, decisão e relacionamento.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(1, 2, 3),
    'learning_objective',
      'Compreender a mudança esperada: sair da fala improvisada para uma venda consultiva, transparente e replicável.',
    'summary',
      'A formação organiza o atendimento em cinco perspectivas: produto, cliente, proposta, decisão e relacionamento.',
    'key_points', jsonb_build_array(
      'Entender objetivo, prazo, orçamento e preocupação do cliente.',
      'Explicar produto, parcela, contemplação, lance e reajuste sem promessa.',
      'Conduzir decisão, próximo passo e pós-venda com confiança.',
      'A proposta deve surgir depois do entendimento do cliente.'
    )
  )
),

-- Módulo 1 / Aula 2
(
  '51a986e9-2537-54da-b253-e52f182c9b2e'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '375afc72-8010-553f-ba38-37f100331e00'::uuid,
  2,
  'Consórcio em linguagem simples',
  'Aprenda a explicar os fundamentos do consórcio sem excesso de termos técnicos.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(4, 5),
    'learning_objective',
      'Explicar em linguagem simples o que é consórcio e os papéis de grupo, fundo comum, prazo e crédito.',
    'key_points', jsonb_build_array(
      'Consórcio é uma forma de aquisição em grupo, com prazo definido e autofinanciamento.',
      'O cliente participa das assembleias e pode ser contemplado por sorteio ou lance.',
      'Crédito e parcela precisam fazer sentido para o objetivo do cliente.',
      'Contemplação não deve ser apresentada como promessa.'
    ),
    'recommended_phrase',
      'O consórcio é uma forma de planejar a compra do carro em grupo, escolhendo crédito e parcela compatíveis com seu objetivo, sem tratar contemplação como promessa.',
    'exercise',
      'Explique consórcio em até 30 segundos sem usar termos técnicos desnecessários.'
  )
),

-- Módulo 1 / Aula 3
(
  'efd2b3fc-647c-5229-8ab4-cf0da3938406'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '375afc72-8010-553f-ba38-37f100331e00'::uuid,
  3,
  'Parcela, contemplação e lances',
  'Entenda como explicar composição da parcela, contemplação e modalidades de lance com responsabilidade.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(6, 7, 8),
    'learning_objective',
      'Apresentar custos, formas de contemplação e estratégia de lance sem gerar expectativa de garantia.',
    'key_points', jsonb_build_array(
      'A parcela pode incluir taxa de administração e outros componentes previstos no contrato.',
      'Contemplação ocorre conforme regras do grupo, por sorteio ou lance.',
      'Lance livre, lance fixo e crédito embutido devem ser explicados conforme o plano vigente.',
      'O lance aumenta participação na disputa, mas não garante contemplação.'
    ),
    'practice_questions', jsonb_build_array(
      'Você precisa estar com o carro em uma data específica ou consegue trabalhar com uma compra planejada?',
      'Você possui algum recurso disponível para lance hoje?',
      'Esse recurso compromete sua reserva ou caixa?',
      'Sua prioridade é chance de contemplação ou preservar crédito?'
    ),
    'callout',
      'Explique possibilidades, regras e cenários; nunca transforme possibilidade em garantia.'
  )
),

-- Módulo 1 / Aula 4
(
  'f7fbba20-6854-5c47-8fc9-311b078a1617'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '375afc72-8010-553f-ba38-37f100331e00'::uuid,
  4,
  'Planos, reajustes e transparência',
  'Use transparência comercial para alinhar expectativa antes do fechamento e reduzir objeções futuras.',
  'text',
  6,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(9),
    'learning_objective',
      'Identificar os pontos que precisam estar claros antes da contratação.',
    'practice_checklist', jsonb_build_array(
      'Prazo do plano disponível',
      'Parcela e estratégia oficial',
      'Reajuste de crédito e mensalidade',
      'Regras de lance e documentação',
      'Taxas e componentes do plano',
      'Ausência de promessa de data de contemplação'
    ),
    'callout',
      'Uma dúvida esclarecida no início é mais simples de tratar do que uma expectativa errada depois da compra.'
  )
),

-- Módulo 2 / Aula 1
(
  '1f151a1e-13d6-569b-8bae-30d1e5e5675c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '055b178d-7250-5813-9751-449c3d762458'::uuid,
  1,
  'As 8 etapas da venda consultiva',
  'Conheça a jornada completa do atendimento e entenda por que pular etapas cria objeções.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(10, 11),
    'learning_objective',
      'Reconhecer a função de cada etapa da venda consultiva e sua relação com a qualidade da decisão do cliente.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Preparação'),
      jsonb_build_object('sequence', 2, 'name', 'Pré-abordagem'),
      jsonb_build_object('sequence', 3, 'name', 'Abordagem'),
      jsonb_build_object('sequence', 4, 'name', 'Sondagem'),
      jsonb_build_object('sequence', 5, 'name', 'Argumentação'),
      jsonb_build_object('sequence', 6, 'name', 'Negociação'),
      jsonb_build_object('sequence', 7, 'name', 'Fechamento'),
      jsonb_build_object('sequence', 8, 'name', 'Pós-venda')
    ),
    'key_points', jsonb_build_array(
      'Pular sondagem gera proposta genérica e objeções.',
      'Pular confirmação gera expectativa errada e arrependimento.',
      'Pular pós-venda destrói confiança e indicação.'
    )
  )
),

-- Módulo 2 / Aula 2
(
  '14ab833f-728c-573c-871e-4a03036b71dd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '055b178d-7250-5813-9751-449c3d762458'::uuid,
  2,
  'Preparação para o atendimento',
  'Organize produto, ferramentas e mentalidade antes de iniciar a conversa com o cliente.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(12),
    'learning_objective',
      'Preparar o atendimento para reduzir improviso, ansiedade e atropelo comercial.',
    'practice_checklist', jsonb_build_array(
      'Planos e simulações do dia',
      'Taxas, prazo, lance e reajuste',
      'Informações que podem ser afirmadas e pontos que precisam ser confirmados',
      'Materiais, links, celular ou tablet e simulador',
      'Objetivo de entender e conduzir o próximo passo'
    ),
    'recommended_phrase',
      'Meu objetivo não é forçar venda. É entender o cliente, explicar com clareza e conduzir o próximo passo com segurança.'
  )
),

-- Módulo 2 / Aula 3
(
  'adcd13b0-342e-56ec-8a76-bf9332e055c7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '055b178d-7250-5813-9751-449c3d762458'::uuid,
  3,
  'Pré-abordagem e abordagem',
  'Observe o contexto, obtenha permissão para conversar e gere o primeiro dado concreto para a sondagem.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(13),
    'learning_objective',
      'Abrir o atendimento de forma personalizada, sem falsa urgência nem proposta prematura.',
    'key_points', jsonb_build_array(
      'Observe sinais antes de falar.',
      'A abordagem deve gerar permissão e personalização.',
      'Busque um primeiro dado concreto antes de apresentar tabela ou simulação.',
      'Evite promessa de contemplação rápida e frases genéricas de pressão.'
    ),
    'practice_questions', jsonb_build_array(
      'Posso te fazer duas perguntas rápidas para entender se o consórcio faz sentido para o que você está buscando?',
      'Qual carro ou faixa de crédito você está planejando?'
    )
  )
),

-- Módulo 2 / Aula 4
(
  '21f62a49-a983-5b1e-bb3a-df733d5dc463'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '055b178d-7250-5813-9751-449c3d762458'::uuid,
  4,
  'Sondagem e SPIN',
  'Descubra objetivo, momento, capacidade financeira, critério de decisão e participantes antes de ofertar.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(14, 15),
    'learning_objective',
      'Construir um diagnóstico resumido do cliente antes de apresentar qualquer proposta.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Situação', 'focus', 'Entender o cenário atual'),
      jsonb_build_object('sequence', 2, 'name', 'Problema', 'focus', 'Identificar incômodo ou necessidade'),
      jsonb_build_object('sequence', 3, 'name', 'Implicação', 'focus', 'Dimensionar o impacto de não resolver'),
      jsonb_build_object('sequence', 4, 'name', 'Necessidade', 'focus', 'Fazer o cliente visualizar valor')
    ),
    'practice_questions', jsonb_build_array(
      'Qual carro você usa hoje e há quanto tempo está com ele?',
      'O que está te fazendo pensar em trocar agora?',
      'Se você adiar essa troca por mais um ano, que custo ou dificuldade isso pode gerar?',
      'Se um plano coubesse no orçamento, isso resolveria o que mais te preocupa?'
    ),
    'recommended_phrase',
      'Você quer X, até Y, com parcela próxima de Z e sua principal preocupação é W.',
    'callout',
      'Depois de uma pergunta importante, espere. Escuta ativa faz parte da sondagem.'
  )
),

-- Módulo 3 / Aula 1
(
  '56cfa5c6-f461-5c3a-a7fc-ebd8caebd8ee'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '903cfd30-30ee-56aa-a3e8-12fb3a232954'::uuid,
  1,
  'Característica que vira benefício',
  'Conecte produto e necessidade para construir uma argumentação personalizada.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(16, 17),
    'learning_objective',
      'Transformar características do plano em benefícios relevantes para aquilo que o cliente revelou.',
    'framework', jsonb_build_array(
      jsonb_build_object('feature', 'Prazo de pagamento', 'possible_benefit', 'Preservar caixa ao longo do tempo'),
      jsonb_build_object('feature', 'Possibilidade de lance', 'possible_benefit', 'Criar estratégia dentro das regras'),
      jsonb_build_object('feature', 'Crédito reajustável', 'possible_benefit', 'Manter referência do poder de compra'),
      jsonb_build_object('feature', 'Estrutura sem juros de financiamento', 'possible_benefit', 'Comparar custo e fluxo de caixa'),
      jsonb_build_object('feature', 'Flexibilidade de escolha', 'possible_benefit', 'Planejar por faixa de crédito')
    ),
    'recommended_phrase',
      'Você me disse que [necessidade]. Por isso, o ponto deste plano que mais conversa com você é [característica], porque [benefício].'
  )
),

-- Módulo 3 / Aula 2
(
  '6d4187fa-1d61-512a-bd2c-ef62d7cfb80c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '903cfd30-30ee-56aa-a3e8-12fb3a232954'::uuid,
  2,
  'Comparação consultiva e transparência',
  'Ajude o cliente a comparar alternativas pelo critério correto, sem atacar outras formas de compra.',
  'text',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(18),
    'learning_objective',
      'Responder comparações sobre financiamento, juros e lance de forma equilibrada e transparente.',
    'key_points', jsonb_build_array(
      'A melhor alternativa depende do prazo e da necessidade de uso imediato.',
      'Consórcio não tem juros de financiamento, mas possui componentes previstos no plano.',
      'Lance deve ser avaliado conforme recurso, crédito que se deseja preservar e regras do grupo.',
      'Reconhecer quando o consórcio não atende uma urgência aumenta confiança.'
    ),
    'practice_questions', jsonb_build_array(
      'Você precisa usar o carro imediatamente?',
      'O que pesa mais na sua decisão: prazo, custo ou fluxo de caixa?',
      'Quanto de crédito você pretende preservar se optar por lance?'
    )
  )
),

-- Módulo 4 / Aula 1
(
  '5c50346d-3b5f-5ae9-b266-b170c81b5815'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '9e827c53-1c35-5152-9cba-6775e58e41e8'::uuid,
  1,
  'Método A-I-R-C para objeções',
  'Use objeções como informação: acolha, investigue, responda e confirme.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(19, 20),
    'learning_objective',
      'Tratar objeções sem confronto e descobrir o que realmente impede o avanço.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Acolher', 'focus', 'Não rebater imediatamente'),
      jsonb_build_object('sequence', 2, 'name', 'Investigar', 'focus', 'Descobrir a objeção real'),
      jsonb_build_object('sequence', 3, 'name', 'Responder', 'focus', 'Usar fatos e o diagnóstico'),
      jsonb_build_object('sequence', 4, 'name', 'Confirmar', 'focus', 'Verificar se a dúvida foi resolvida')
    ),
    'practice_questions', jsonb_build_array(
      'Quando você diz que vai demorar, qual seria um prazo aceitável?',
      'Só entraria se pudesse ofertar lance?',
      'O que mais preocupa no reajuste: aumento ou previsibilidade?',
      'O que exatamente você quer avaliar antes de decidir?'
    ),
    'callout',
      'Objeção não é briga. Objeção é informação.'
  )
),

-- Módulo 4 / Aula 2
(
  '3800794c-a683-5a12-b08b-e342e1610dc9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '9e827c53-1c35-5152-9cba-6775e58e41e8'::uuid,
  2,
  'Negociação sem perder valor',
  'Ajuste variáveis legítimas da proposta sem ajustar a verdade.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(21),
    'learning_objective',
      'Negociar crédito, prazo, parcela e momento de entrada sem omitir regras nem criar urgência falsa.',
    'key_points', jsonb_build_array(
      'Pode ajustar faixa de crédito, prazo disponível, estratégia de parcela e momento de entrada.',
      'Pode discutir estratégia de lance dentro das regras.',
      'Não pode prometer contemplação.',
      'Não pode omitir taxa, reajuste ou regra.',
      'Não pode inventar condição fora do contrato nem pressionar com falsa urgência.'
    ),
    'recommended_phrase',
      'Qual ajuste faria esta proposta ficar mais confortável: crédito, parcela, prazo ou momento de entrada?'
  )
),

-- Módulo 4 / Aula 3
(
  '6a4b085d-a98b-56fe-b282-0a35893a474e'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '9e827c53-1c35-5152-9cba-6775e58e41e8'::uuid,
  3,
  'Fechamento consultivo',
  'Recapitule o diagnóstico, feche lacunas e conduza o cliente para uma decisão ou próximo passo claro.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(22),
    'learning_objective',
      'Transformar entendimento em compromisso sem usar fechamento agressivo.',
    'key_points', jsonb_build_array(
      'Observe sinais de compra como dúvidas sobre documentação, parcela e acompanhamento.',
      'Confirme produto, parcela, contemplação, reajuste, lance e próximos passos.',
      'Use fechamento por resumo, escolha ou próximo passo.'
    ),
    'closing_questions', jsonb_build_array(
      'Podemos seguir com o cadastro?',
      'Qual conversa mais com seu planejamento: parcela menor ou crédito maior?',
      'Se os pontos estão claros, vamos revisar os dados e formalizar?'
    )
  )
),

-- Módulo 5 / Aula 1
(
  'bb54c819-f583-516d-9eec-d1b5364ef206'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '1cd18568-b10d-5fab-8d08-cf1d68846e8b'::uuid,
  1,
  'Pós-venda e relacionamento',
  'Proteja a confiança criada na venda com acompanhamento consistente depois da assinatura.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(23),
    'learning_objective',
      'Aplicar uma cadência de acompanhamento que reduza ruído, preserve expectativa e abra espaço para indicação.',
    'service_script', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'step', 'Após contratação', 'focus', 'Confirmar proposta, pagamento e canais'),
      jsonb_build_object('sequence', 2, 'step', 'Primeiros dias', 'focus', 'Checar acesso e entendimento do grupo'),
      jsonb_build_object('sequence', 3, 'step', 'Antes das assembleias', 'focus', 'Orientar canais e estratégia dentro das regras'),
      jsonb_build_object('sequence', 4, 'step', 'Após eventos', 'focus', 'Explicar resultado e próximo passo'),
      jsonb_build_object('sequence', 5, 'step', 'Ao longo do plano', 'focus', 'Manter relacionamento e trabalhar indicações')
    ),
    'callout',
      'Consórcio não termina na assinatura. O pós-venda protege a confiança criada na venda.'
  )
),

-- Módulo 5 / Aula 2
(
  '80512a44-4a76-5968-86e7-82a10caadd29'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid,
  '1cd18568-b10d-5fab-8d08-cf1d68846e8b'::uuid,
  2,
  'Prática, coaching e compromisso',
  'Pratique situações reais, receba feedback observável e defina uma mudança imediata de comportamento.',
  'interactive',
  16,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(24, 25, 26),
    'learning_objective',
      'Demonstrar o processo comercial em role-play e transformar feedback em uma ação prática para o próximo atendimento.',
    'exercise',
      'Em duplas, alterne os papéis de vendedor e cliente. Faça 7 minutos de simulação e 3 minutos de feedback por rodada.',
    'practice_checklist', jsonb_build_array(
      'Cliente planejador: trocar carro em 12 a 18 meses, parcela até R$ 1.500 e possível reserva para lance.',
      'Cliente com urgência: precisa do carro em 30 dias e acredita que lance garante contemplação.',
      'Cliente comparador: quer saber apenas qual é mais barato, consórcio ou financiamento.'
    ),
    'leader_evaluation', jsonb_build_array(
      'Domínio do produto',
      'Qualidade da abordagem',
      'Profundidade da sondagem',
      'Escuta ativa',
      'Argumentação personalizada',
      'Tratamento de objeções',
      'Transparência',
      'Fechamento e próximo passo',
      'Postura e comunicação'
    ),
    'closing_message',
      'Venda profissional é venda consciente: cliente bem informado, expectativa alinhada e relação preservada depois da assinatura.',
    'team_commitment',
      'Definir uma mudança imediata na forma de atender e uma habilidade para treinar nas próximas duas semanas.'
  )
);


-- ============================================================================
-- 3. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'pilot', false,
  'module_count', 5,
  'lesson_count', 15,
  'estimated_duration_minutes', 150,
  'content_model_version', 'fase5a-v1',
  'source_workbook_asset_id', '2870bf53-aa3e-4f16-a0a2-9ab89da5b494',
  'source_slides_asset_id', '223f1eca-fcf7-4e73-9f73-f247720aeb6f'
)
where id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;


-- ============================================================================
-- 4. PÓS-CONDIÇÕES
-- ============================================================================

do $postconditions$
declare
  v_modules bigint;
  v_lessons bigint;
  v_required_lessons bigint;
  v_progress bigint;
  v_duration bigint;
  v_module_duration bigint;
  v_assets bigint;
  v_workbook_exact bigint;
  v_slides_exact bigint;
  v_learning_experience boolean;
  v_module_count_meta integer;
  v_lesson_count_meta integer;
  v_duration_meta integer;
  v_content_model_version text;
begin
  select count(*)
  into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and status = 'published';

  if v_modules <> 5 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: esperado 5 módulos publicados, encontrado %',
      v_modules;
  end if;

  select count(*)
  into v_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and status = 'published';

  if v_lessons <> 15 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: esperado 15 aulas publicadas, encontrado %',
      v_lessons;
  end if;

  select count(*)
  into v_required_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and is_required = true
    and status = 'published';

  if v_required_lessons <> 15 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: esperado 15 aulas obrigatórias publicadas, encontrado %',
      v_required_lessons;
  end if;

  select coalesce(sum(duration_minutes), 0)
  into v_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and status = 'published';

  if v_duration <> 150 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: duração total esperada 150 min, encontrada %',
      v_duration;
  end if;

  select coalesce(sum((metadata ->> 'estimated_duration_minutes')::integer), 0)
  into v_module_duration
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and status = 'published';

  if v_module_duration <> 150 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: duração dos módulos esperada 150 min, encontrada %',
      v_module_duration;
  end if;

  if (
    select count(*)
    from public.training_library_lessons
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
      and module_id = '375afc72-8010-553f-ba38-37f100331e00'::uuid
  ) <> 4 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: módulo 1 deveria possuir 4 aulas';
  end if;

  if (
    select count(*)
    from public.training_library_lessons
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
      and module_id = '055b178d-7250-5813-9751-449c3d762458'::uuid
  ) <> 4 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: módulo 2 deveria possuir 4 aulas';
  end if;

  if (
    select count(*)
    from public.training_library_lessons
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
      and module_id = '903cfd30-30ee-56aa-a3e8-12fb3a232954'::uuid
  ) <> 2 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: módulo 3 deveria possuir 2 aulas';
  end if;

  if (
    select count(*)
    from public.training_library_lessons
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
      and module_id = '9e827c53-1c35-5152-9cba-6775e58e41e8'::uuid
  ) <> 3 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: módulo 4 deveria possuir 3 aulas';
  end if;

  if (
    select count(*)
    from public.training_library_lessons
    where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
      and module_id = '1cd18568-b10d-5fab-8d08-cf1d68846e8b'::uuid
  ) <> 2 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: módulo 5 deveria possuir 2 aulas';
  end if;

  select count(*)
  into v_progress
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_progress <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: progresso artificial detectado; encontrado %',
      v_progress;
  end if;

  select count(*)
  into v_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid;

  if v_assets <> 2 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: quantidade de assets foi alterada; encontrado %',
      v_assets;
  end if;

  select count(*)
  into v_workbook_exact
  from public.training_library_assets
  where id = '2870bf53-aa3e-4f16-a0a2-9ab89da5b494'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – Formação Comercial'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/01_formacao_comercial_consorcio_automoveis.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 454601
    and status = 'active';

  if v_workbook_exact <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: workbook foi alterado';
  end if;

  select count(*)
  into v_slides_exact
  from public.training_library_assets
  where id = '223f1eca-fcf7-4e73-9f73-f247720aeb6f'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and sequence_no = 2
    and asset_type = 'slides'
    and display_name = 'Apresentação – Formação Comercial'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/0e7bed92-4f58-4f45-b7df-72f0fed53765/02_formacao_comercial_consorcio_automoveis.pptx'
    and mime_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    and file_size_bytes = 12069364
    and status = 'active';

  if v_slides_exact <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: slides foram alterados';
  end if;

  select
    coalesce((metadata ->> 'learning_experience')::boolean, false),
    coalesce((metadata ->> 'module_count')::integer, 0),
    coalesce((metadata ->> 'lesson_count')::integer, 0),
    coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0),
    metadata ->> 'content_model_version'
  into
    v_learning_experience,
    v_module_count_meta,
    v_lesson_count_meta,
    v_duration_meta,
    v_content_model_version
  from public.training_library_items
  where id = '0e7bed92-4f58-4f45-b7df-72f0fed53765'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 1
    and title = 'Formação Comercial – Consórcio de Automóveis'
    and description = 'Treinamento comercial sobre produto, sondagem, argumentação, objeções e fechamento aplicado à venda de consórcio de automóveis.'
    and category = 'commercial_training'
    and to_jsonb(audience_roles) = '["director","supervisor","salesperson"]'::jsonb
    and status = 'published'
    and is_featured = false;

  if coalesce(v_learning_experience, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: treinamento não marcado para experiência de aprendizagem';
  end if;

  if v_module_count_meta <> 5
     or v_lesson_count_meta <> 15
     or v_duration_meta <> 150
     or v_content_model_version <> 'fase5a-v1' then
    raise exception
      'TRAINING_LIBRARY_PHASE5A_POSTCONDITION_FAILED: metadados finais divergiram';
  end if;
end;
$postconditions$;
