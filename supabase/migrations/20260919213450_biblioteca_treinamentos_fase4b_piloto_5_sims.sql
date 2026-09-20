-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 4B
-- Piloto estruturado: Os 5 Sims da Venda de Consórcio
--
-- Objetivos:
--   1. Estruturar o treinamento existente em 3 módulos e 8 aulas.
--   2. Preservar o treinamento e o asset PPTX já cadastrados.
--   3. Preparar conteúdo para o futuro player de aprendizagem.
--   4. Não criar progresso artificial para nenhum usuário.
-- ============================================================================

do $preflight$
begin
  if not exists (
    select 1
    from public.organizations
    where id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and slug = 'rf-consorcios'
      and status = 'active'
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_PREFLIGHT_FAILED: RF Consórcios ativa não encontrada';
  end if;

  if not exists (
    select 1
    from public.training_library_items
    where id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
      and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and title = 'Os 5 Sims da Venda de Consórcio'
      and status = 'published'
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_PREFLIGHT_FAILED: treinamento Os 5 Sims publicado não encontrado';
  end if;

  if exists (
    select 1
    from public.training_library_modules
    where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_PREFLIGHT_FAILED: treinamento já possui módulos';
  end if;

  if exists (
    select 1
    from public.training_library_lessons
    where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_PREFLIGHT_FAILED: treinamento já possui aulas';
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
  '96a102b1-03db-5fb2-9e1e-c5bb85c45405'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  1,
  'Fundamentos e entendimento',
  'Apresenta a lógica dos cinco sims internos e inicia a condução pela compreensão real da necessidade do cliente.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 18,
    'pilot', true
  )
),
(
  '313310f7-712d-5101-bea5-3c1979d5ec97'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  2,
  'Construção da decisão',
  'Desenvolve confiança, solução, valor e urgência responsável para ajudar o cliente a avançar na decisão.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 32,
    'pilot', true
  )
),
(
  '01a68afa-aa96-5257-af2d-8bd4a348cd4b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  3,
  'Fechamento e aplicação prática',
  'Transforma os cinco sims em roteiro de atendimento, fechamento e prática observada em equipe.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 22,
    'pilot', true
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

-- Aula 1
(
  '04812150-ff59-5bee-89b5-2f61696a7358'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '96a102b1-03db-5fb2-9e1e-c5bb85c45405'::uuid,
  1,
  'Fundamentos dos 5 Sims',
  'Entenda por que a decisão comercial começa antes da assinatura e conheça o mapa dos cinco sims internos.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(1, 2, 3),
    'learning_objective',
      'Compreender que o vendedor deve conduzir o raciocínio do cliente antes de apresentar a proposta.',
    'summary',
      'Antes do sim verbal, o cliente passa por cinco decisões internas: entendimento, confiança, solução, valor e agora.',
    'key_points', jsonb_build_array(
      'A venda acontece antes da assinatura.',
      'Quando um dos cinco sims falha, a conversa tende a travar.',
      'A missão do vendedor é conduzir o raciocínio do cliente.',
      'A proposta deve aparecer depois de compreender a necessidade, construir confiança e traduzir a solução.'
    ),
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Entendimento', 'customer_question', 'Ele me entende?'),
      jsonb_build_object('sequence', 2, 'name', 'Confiança', 'customer_question', 'Dá para confiar?'),
      jsonb_build_object('sequence', 3, 'name', 'Solução', 'customer_question', 'Resolve meu problema?'),
      jsonb_build_object('sequence', 4, 'name', 'Valor', 'customer_question', 'Vale o preço?'),
      jsonb_build_object('sequence', 5, 'name', 'Agora', 'customer_question', 'Por que decidir hoje?')
    )
  )
),

-- Aula 2
(
  'f1b9e9a3-ecae-58c0-aba9-af8d6c7e5878'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '96a102b1-03db-5fb2-9e1e-c5bb85c45405'::uuid,
  2,
  'Sim 1 — Entendimento',
  'Comece pela situação do cliente, pergunte antes de apresentar e devolva a necessidade com as palavras dele.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(4),
    'learning_objective',
      'Demonstrar entendimento real antes de falar de carta, taxa, parcela ou administradora.',
    'customer_question',
      'Esse vendedor entende o que eu preciso?',
    'key_points', jsonb_build_array(
      'Comece pela situação do cliente.',
      'Pergunte antes de apresentar produto.',
      'Repita a necessidade usando as palavras do próprio cliente.'
    ),
    'practice_questions', jsonb_build_array(
      'O que você quer conquistar?',
      'O que te trouxe até aqui?',
      'O que já tentou que não resolveu?',
      'O que é inegociável para você?'
    ),
    'recommended_phrase',
      'Então o mais importante para você é...'
  )
),

-- Aula 3
(
  '9003d273-0056-597d-9a7f-ed0f48eb3b32'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '313310f7-712d-5101-bea5-3c1979d5ec97'::uuid,
  1,
  'Sim 2 — Confiança',
  'Construa confiança por meio de clareza, limite e segurança, sem prometer prazo de contemplação.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(5),
    'learning_objective',
      'Fortalecer confiança com comunicação clara, responsável e sem promessas indevidas.',
    'customer_question',
      'Dá para confiar nessa pessoa?',
    'key_points', jsonb_build_array(
      'Confiança não nasce de promessa perfeita.',
      'Explique possibilidades, estratégia de lance e regras do grupo.',
      'Nunca prometa mês ou prazo de contemplação.',
      'Sinceridade reduz defesa e aumenta confiança.'
    ),
    'recommended_phrase',
      'Eu não prometo mês de contemplação. Eu monto estratégia.',
    'callout',
      'Não venda milagre. Venda planejamento.'
  )
),

-- Aula 4
(
  '5dd72fc3-d208-532a-b3f1-6e6ad91b9b3d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '313310f7-712d-5101-bea5-3c1979d5ec97'::uuid,
  2,
  'Sim 3 — Solução',
  'Traduza características da proposta em consequências práticas para a vida real do cliente.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(6),
    'learning_objective',
      'Transformar características em benefícios compreensíveis e relacionados ao objetivo do cliente.',
    'customer_question',
      'Isso resolve o meu problema?',
    'key_points', jsonb_build_array(
      'Característica não vende sozinha.',
      'O vendedor precisa traduzir cada característica em consequência prática.',
      'Use a ponte verbal: isso significa que...'
    ),
    'example',
      'Essa carta é de R$ 120 mil. Isso significa que você pode buscar um veículo dentro desse valor sem assumir os juros longos de um financiamento tradicional.'
  )
),

-- Aula 5
(
  'f638b8b1-993b-528b-83b4-21765ad2845b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '313310f7-712d-5101-bea5-3c1979d5ec97'::uuid,
  3,
  'Sim 4 — Valor',
  'Ajude o cliente a perceber o custo de continuar parado antes de discutir apenas preço ou parcela.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(7),
    'learning_objective',
      'Conectar valor ao impacto real de não resolver o objetivo do cliente.',
    'customer_question',
      'Vale o que está custando?',
    'key_points', jsonb_build_array(
      'O preço só parece justo depois que o cliente entende o custo de continuar parado.',
      'Explore consequências reais de não agir.',
      'A parcela pode ser apresentada como instrumento de disciplina para o objetivo.'
    ),
    'cost_of_inaction_examples', jsonb_build_array(
      'aluguel que continua',
      'carro antigo dando manutenção',
      'oportunidade perdida',
      'dinheiro sem disciplina',
      'sonho sempre adiado'
    ),
    'practice_question',
      'Quanto isso já te custou até hoje?'
  )
),

-- Aula 6
(
  '91e8926a-77be-567c-9f66-0395bc05aaee'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '313310f7-712d-5101-bea5-3c1979d5ec97'::uuid,
  4,
  'Sim 5 — Agora',
  'Crie urgência responsável mostrando o custo real de adiar, sem usar pressão falsa.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(8),
    'learning_objective',
      'Conduzir o cliente à reflexão sobre o impacto de adiar uma decisão que ele próprio afirmou querer tomar.',
    'customer_question',
      'Por que eu devo fazer agora e não depois?',
    'key_points', jsonb_build_array(
      'Urgência responsável não é pressão falsa.',
      'Mostre o custo real de adiar.',
      'A decisão de hoje pode ser apresentada como primeiro passo do objetivo declarado pelo cliente.'
    ),
    'practice_questions', jsonb_build_array(
      'O que acontece se você deixar para depois?',
      'O bem tende a ficar mais barato ou mais caro?',
      'Se nada mudar, o resultado muda?',
      'Faz sentido continuar apenas pensando?'
    )
  )
),

-- Aula 7
(
  'c341fdb2-b5c7-575c-93d4-c6586ae78937'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '01a68afa-aa96-5257-af2d-8bd4a348cd4b'::uuid,
  1,
  'Fechamento e roteiro de atendimento',
  'Depois dos cinco sims, faça uma pergunta de decisão e use um roteiro simples para conduzir o atendimento.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(9, 10),
    'learning_objective',
      'Transformar os cinco sims em uma sequência prática de atendimento e fechamento.',
    'key_points', jsonb_build_array(
      'Não encerre com uma pergunta vaga.',
      'Faça uma pergunta de decisão.',
      'Depois de perguntar, dê espaço para o cliente responder.',
      'O roteiro passa por diagnóstico, realidade, tradução, valor e fechamento.'
    ),
    'closing_questions', jsonb_build_array(
      'Faz mais sentido fechar hoje com o melhor preço ou correr o risco de voltar amanhã e pagar mais caro?',
      'A primeira parcela fica melhor no Pix ou no boleto?',
      'O que falta para resolvermos isso agora?'
    ),
    'service_script', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'step', 'Diagnóstico', 'focus', 'crédito, parcela, lance, urgência'),
      jsonb_build_object('sequence', 2, 'step', 'Realidade', 'focus', 'financiamento, entrada, juros, prazo'),
      jsonb_build_object('sequence', 3, 'step', 'Tradução', 'focus', 'isso significa que...'),
      jsonb_build_object('sequence', 4, 'step', 'Valor', 'focus', 'custo de continuar parado'),
      jsonb_build_object('sequence', 5, 'step', 'Fechamento', 'focus', 'pergunta de decisão')
    )
  )
),

-- Aula 8
(
  '88f78b76-95f9-5e18-9c2a-7f81c6695242'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid,
  '01a68afa-aa96-5257-af2d-8bd4a348cd4b'::uuid,
  2,
  'Treino prático e compromisso',
  'Pratique a condução pelos cinco sims em dupla e finalize com um compromisso de aplicação em toda negociação.',
  'interactive',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_slides', jsonb_build_array(11, 12),
    'learning_objective',
      'Aplicar os cinco sims em uma simulação de venda e receber observação do líder.',
    'exercise',
      'Em duplas: um vendedor e um cliente. O cliente escolhe uma objeção e o vendedor conduz pelos cinco sims.',
    'practice_checklist', jsonb_build_array(
      'Perguntar antes de explicar',
      'Repetir com as palavras do cliente',
      'Admitir limite real',
      'Traduzir com isso significa que',
      'Mostrar custo de adiar',
      'Fazer pergunta de fechamento'
    ),
    'leader_evaluation', jsonb_build_array(
      'clareza',
      'escuta',
      'ética',
      'condução',
      'fechamento'
    ),
    'closing_message',
      'Vender consórcio é conduzir uma decisão. Quem conduz com perguntas, clareza e responsabilidade deixa de depender da sorte.',
    'team_commitment',
      'Aplicar os 5 sims em toda negociação.'
  )
);


-- ============================================================================
-- 3. METADADOS DO TREINAMENTO PILOTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'pilot', true,
  'module_count', 3,
  'lesson_count', 8,
  'estimated_duration_minutes', 72,
  'content_model_version', 'fase4b-v1'
)
where id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
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
  v_learning_experience boolean;
begin
  select count(*)
  into v_modules
  from public.training_library_modules
  where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid;

  select count(*)
  into v_lessons
  from public.training_library_lessons
  where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid;

  select count(*)
  into v_required_lessons
  from public.training_library_lessons
  where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
    and is_required = true
    and status = 'published';

  select count(*)
  into v_progress
  from public.training_library_lesson_progress
  where training_id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid;

  select coalesce((metadata ->> 'learning_experience')::boolean, false)
  into v_learning_experience
  from public.training_library_items
  where id = '923f6553-9091-44cc-b8f9-9f7b7f855942'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_modules <> 3 then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_POSTCONDITION_FAILED: esperado 3 módulos, encontrado %',
      v_modules;
  end if;

  if v_lessons <> 8 then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_POSTCONDITION_FAILED: esperado 8 aulas, encontrado %',
      v_lessons;
  end if;

  if v_required_lessons <> 8 then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_POSTCONDITION_FAILED: esperado 8 aulas obrigatórias publicadas, encontrado %',
      v_required_lessons;
  end if;

  if v_progress <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_POSTCONDITION_FAILED: progresso artificial detectado';
  end if;

  if coalesce(v_learning_experience, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE4B_POSTCONDITION_FAILED: treinamento não marcado para experiência de aprendizagem';
  end if;
end;
$postconditions$;