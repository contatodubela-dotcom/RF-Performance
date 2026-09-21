-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5B
-- Escala da experiência de aprendizagem: SPIN Selling aplicado ao Consórcio
--
-- Objetivos:
--   1. Estruturar o treinamento existente em 4 módulos e 10 aulas.
--   2. Preservar integralmente o PDF já cadastrado como material de apoio.
--   3. Manter a experiência alinhada ao conteúdo efetivamente publicado.
--   4. Não criar progresso artificial para nenhum usuário.
--   5. Falhar fechado se o estado remoto divergir do snapshot validado.
--
-- Fonte publicada validada:
--   asset_id: 4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc
--   arquivo: 01_spin_selling_aplicado_ao_consorcio.pdf
--   tamanho: 555727 bytes
--   sha256 externo validado: 580157A72D0F2F4675238B12D59272670E960C05BFAB4BFAE355D91353776F94
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
  if not exists (
    select 1
    from public.organizations
    where id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and slug = 'rf-consorcios'
      and status = 'active'
  ) then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: RF Consórcios ativa não encontrada';
  end if;

  select count(*)
  into v_item_count
  from public.training_library_items
  where id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 2
    and title = 'SPIN Selling aplicado ao Consórcio'
    and description = 'Aplicação prática do método SPIN para conduzir a sondagem e desenvolver uma venda consultiva de consórcio.'
    and category = 'sales_method'
    and to_jsonb(audience_roles) = '["director","supervisor","salesperson"]'::jsonb
    and status = 'published'
    and is_featured = false
    and metadata = '{}'::jsonb;

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: item SPIN Selling divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
  into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  if v_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: esperado 1 asset; encontrado %',
      v_asset_count;
  end if;

  select count(*)
  into v_exact_asset_count
  from public.training_library_assets
  where id = '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – SPIN Selling aplicado ao Consórcio'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/3e16b785-48d8-4b78-b21a-d6fe289c00b3/01_spin_selling_aplicado_ao_consorcio.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 555727
    and status = 'active';

  if v_exact_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: PDF publicado divergiu do snapshot';
  end if;

  select count(*)
  into v_module_count
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  if v_module_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: treinamento já possui módulos; encontrado %',
      v_module_count;
  end if;

  select count(*)
  into v_lesson_count
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  if v_lesson_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: treinamento já possui aulas; encontrado %',
      v_lesson_count;
  end if;

  select count(*)
  into v_progress_count
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  if v_progress_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_PREFLIGHT_FAILED: treinamento possui progresso inesperado; encontrado %',
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
  'a7932ba8-c416-59db-8561-57cdaee0be4d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  1,
  'Fundamentos da sondagem SPIN',
  'Apresenta a lógica do SPIN e desenvolve as etapas de Situação e Problema para entender o cenário antes de apresentar a solução.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 24,
    'content_model_version', 'fase5b-v1'
  )
),
(
  '2843c6b9-f3a2-5df8-9357-3b5b791100ba'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  2,
  'Aprofundamento da necessidade',
  'Desenvolve Implicação e Necessidade de Solução, preservando a condução ética e usando a resposta do cliente para escolher a próxima pergunta.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 28,
    'content_model_version', 'fase5b-v1'
  )
),
(
  'f997cdaa-b600-5d31-b51d-a0656b51f45d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  3,
  'Da pergunta à apresentação',
  'Transforma o SPIN em uma conversa natural, resume o diagnóstico e prepara a transição para uma apresentação coerente com o que o cliente revelou.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 18,
    'content_model_version', 'fase5b-v1'
  )
),
(
  'f373dfcd-f53e-5d37-b32c-c3e488634bc3'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  4,
  'Aplicação prática',
  'Consolida a ficha de sondagem, a escolha da próxima pergunta, o checklist antes da apresentação e o compromisso de aplicar o método com disciplina comercial.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 20,
    'content_model_version', 'fase5b-v1'
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
-- Módulo 1 — Fundamentos da sondagem SPIN
-- --------------------------------------------------------------------------

(
  '8cadc6d5-5fb6-5caa-a867-794970c22ac1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'a7932ba8-c416-59db-8561-57cdaee0be4d'::uuid,
  1,
  'Por que usar SPIN e o mapa da conversa',
  'Entenda o SPIN como sequência de raciocínio e reconheça o objetivo comercial de cada etapa antes de apresentar o consórcio.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(1, 2),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Compreender que SPIN organiza a descoberta do cliente e orienta a conversa de Situação até Necessidade de Solução.',
    'summary',
      'SPIN não é um questionário. É uma sequência de raciocínio para entender cenário, descobrir problemas, dimensionar consequências e fazer o cliente verbalizar o valor de uma solução.',
    'key_points', jsonb_build_array(
      'Pergunte antes de apresentar.',
      'Aprofunde antes de argumentar.',
      'Entenda antes de oferecer.',
      'Use a resposta do cliente para decidir a próxima pergunta.'
    ),
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Situação', 'focus', 'Onde o cliente está hoje?'),
      jsonb_build_object('sequence', 2, 'name', 'Problema', 'focus', 'O que está impedindo ou incomodando?'),
      jsonb_build_object('sequence', 3, 'name', 'Implicação', 'focus', 'O que acontece se isso continuar?'),
      jsonb_build_object('sequence', 4, 'name', 'Necessidade', 'focus', 'O que uma boa solução precisa proporcionar?')
    )
  )
),
(
  'cfa816db-f355-5c65-8eac-d07311dbd450'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'a7932ba8-c416-59db-8561-57cdaee0be4d'::uuid,
  2,
  'S — Situação: entender o cenário atual',
  'Descubra projeto, bem desejado, prazo, alternativas pesquisadas, faixa de investimento e recursos disponíveis sem transformar sondagem em cadastro.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(2),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Selecionar perguntas de Situação suficientes para entender o cenário atual sem fazer uma sequência mecânica.',
    'key_points', jsonb_build_array(
      'Entenda o que o cliente pretende comprar ou conquistar.',
      'Descubra prazo, valor aproximado e faixa mensal confortável.',
      'Verifique alternativas já pesquisadas e experiências anteriores.',
      'Pergunte sobre recurso para lance quando isso for relevante.',
      'Selecione apenas as perguntas necessárias; sondagem não pode parecer cadastro.'
    ),
    'practice_questions', jsonb_build_array(
      'O que você pretende comprar ou conquistar neste momento?',
      'Quando gostaria de realizar essa compra?',
      'Quanto você considera confortável investir mensalmente nesse projeto?',
      'Você possui algum recurso reservado que poderia utilizar como lance?'
    )
  )
),
(
  'b48118d9-643b-57b5-bbaf-fb37b7ff2b9a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'a7932ba8-c416-59db-8561-57cdaee0be4d'::uuid,
  3,
  'P — Problema: descobrir o que realmente incomoda',
  'Ajude o cliente a explicar com as próprias palavras a dificuldade, preocupação ou obstáculo que está impedindo o projeto.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(2, 3),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Identificar problemas relevantes sem dizer ao cliente qual deveria ser o problema.',
    'key_points', jsonb_build_array(
      'Problema é o que incomoda, preocupa ou impede o projeto.',
      'Não presuma a dor do cliente.',
      'Use perguntas para que o cliente descreva o problema com as próprias palavras.',
      'Preocupação financeira, experiência ruim e limitações das alternativas pesquisadas podem orientar o aprofundamento.'
    ),
    'practice_questions', jsonb_build_array(
      'O que está impedindo você de fazer essa compra hoje?',
      'O que mais incomoda na situação em que você está atualmente?',
      'O que encontrou nas outras opções de compra que não lhe agradou?',
      'Qual é sua maior dúvida ou receio em relação ao consórcio?'
    )
  )
),

-- --------------------------------------------------------------------------
-- Módulo 2 — Aprofundamento da necessidade
-- --------------------------------------------------------------------------

(
  '4ec95fe5-a131-5a29-b3a3-bb7a3e93abc9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  '2843c6b9-f3a2-5df8-9357-3b5b791100ba'::uuid,
  1,
  'I — Implicação: dimensionar consequências reais',
  'Aprofunde o impacto do problema já reconhecido pelo cliente sem inventar risco, medo ou pressão.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(3),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Usar perguntas de Implicação para tornar claras consequências reais do problema identificado pelo próprio cliente.',
    'key_points', jsonb_build_array(
      'Implicação aprofunda um problema que o cliente já reconheceu.',
      'Explore impactos financeiros, pessoais, familiares ou profissionais quando forem reais.',
      'Não crie medo e não invente problemas para pressionar a decisão.',
      'A consequência precisa nascer do contexto revelado pelo cliente.'
    ),
    'practice_questions', jsonb_build_array(
      'Se você continuar nessa situação por mais um ano, o que acontece?',
      'Além do dinheiro, como essa situação afeta sua rotina?',
      'Se nada mudar nos próximos 12 meses, você estará mais perto ou mais longe do seu objetivo?',
      'Qual seria a consequência de continuar exatamente como está?'
    ),
    'callout',
      'Implicação não é criar medo. É aprofundar consequências reais ligadas ao que o cliente já revelou.'
  )
),
(
  'cf22bf9c-e9d3-5385-99c9-006aa6add78e'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  '2843c6b9-f3a2-5df8-9357-3b5b791100ba'::uuid,
  2,
  'N — Necessidade de Solução: fazer o cliente verbalizar valor',
  'Ajude o cliente a descrever o que uma boa solução precisa proporcionar antes de apresentar uma opção.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(3, 4),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Conduzir perguntas de Necessidade para que o cliente verbalize os critérios e benefícios que uma solução adequada precisa entregar.',
    'key_points', jsonb_build_array(
      'A necessidade deve ser verbalizada pelo cliente.',
      'Conecte a solução desejada ao orçamento, prazo e prioridades já revelados.',
      'Descubra o que pesa mais entre parcela, prazo, crédito e estratégia de lance.',
      'Não tente encaixar o cliente no produto.'
    ),
    'practice_questions', jsonb_build_array(
      'O que uma boa solução precisaria ter para funcionar para você?',
      'Se pudéssemos realizar esse projeto mantendo sua organização financeira, qual seria o benefício?',
      'Entre parcela, prazo, valor do crédito e estratégia de lance, o que seria mais importante na solução?',
      'Antes de eu apresentar uma opção, existe mais alguma coisa que essa solução precisa atender?'
    )
  )
),
(
  '7de8578a-7ebc-5102-9026-18bc1e1c5244'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  '2843c6b9-f3a2-5df8-9357-3b5b791100ba'::uuid,
  3,
  'Condução ética e escolha da próxima pergunta',
  'Use o estágio atual da conversa e a resposta do cliente para decidir como avançar, evitando interrogatório e pressão artificial.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(2, 3, 4, 5),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Aplicar o SPIN como raciocínio adaptativo, escolhendo perguntas conforme a resposta do cliente.',
    'key_points', jsonb_build_array(
      'Você não precisa fazer todas as perguntas.',
      'Reconheça em qual etapa da conversa você está.',
      'Use a resposta para decidir a próxima pergunta.',
      'Aprofunde somente consequências reais.',
      'Avalie qual solução é coerente com o projeto e a realidade financeira do cliente.'
    ),
    'recommended_phrase',
      'Antes de eu lhe apresentar uma opção, existe mais alguma coisa que essa solução precisa atender?'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 3 — Da pergunta à apresentação
-- --------------------------------------------------------------------------

(
  'ab90201b-ac42-587e-bee5-ed141cdd0345'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'f997cdaa-b600-5d31-b51d-a0656b51f45d'::uuid,
  1,
  'Transformar perguntas em uma conversa',
  'Pratique uma sequência natural em que cada resposta abre caminho para a próxima pergunta, sem transformar SPIN em roteiro engessado.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(5),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Conduzir uma conversa SPIN fluida a partir das respostas do cliente.',
    'summary',
      'O segredo não é fazer cinquenta perguntas. É reconhecer em qual etapa você está e usar a resposta para decidir a próxima pergunta.',
    'service_script', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'step', 'Situação', 'focus', 'entender o cenário atual'),
      jsonb_build_object('sequence', 2, 'step', 'Problema', 'focus', 'descobrir o que incomoda'),
      jsonb_build_object('sequence', 3, 'step', 'Implicação', 'focus', 'aprofundar consequência real'),
      jsonb_build_object('sequence', 4, 'step', 'Necessidade', 'focus', 'fazer o cliente verbalizar o que espera da solução')
    ),
    'key_points', jsonb_build_array(
      'Escute a resposta antes de formular a próxima pergunta.',
      'Não avance de etapa apenas para seguir uma sequência decorada.',
      'Use as palavras do cliente durante a conversa.',
      'A conversa precisa produzir um diagnóstico claro.'
    )
  )
),
(
  'e427a3cb-2fc3-5cd4-8582-d4a418ff5dba'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'f997cdaa-b600-5d31-b51d-a0656b51f45d'::uuid,
  2,
  'Resumir o diagnóstico e fazer a transição',
  'Antes da apresentação, devolva ao cliente o que entendeu, confirme o diagnóstico e só então mostre uma possibilidade coerente.',
  'text',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(5),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Construir um resumo do diagnóstico e obter confirmação antes de apresentar o plano.',
    'key_points', jsonb_build_array(
      'Faça um resumo antes de apresentar o plano.',
      'O resumo demonstra escuta e permite correção do diagnóstico.',
      'Inclua motivo, impacto, faixa de crédito ou objetivo, parcela confortável e critério principal.',
      'Depois da confirmação, apresente a solução com base exatamente nesses pontos.'
    ),
    'recommended_phrase',
      'Então deixa eu lhe mostrar uma possibilidade considerando exatamente esses pontos.'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 4 — Aplicação prática
-- --------------------------------------------------------------------------

(
  '849cd1d5-7579-5d36-be30-306727ddee05'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'f373dfcd-f53e-5d37-b32c-c3e488634bc3'::uuid,
  1,
  'Ficha de Sondagem SPIN',
  'Organize a descoberta em Situação, Problema, Implicação, Necessidade, diagnóstico, frase-chave e próximo passo.',
  'interactive',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(6),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Registrar os elementos essenciais da sondagem para transformar a conversa em diagnóstico e próximo passo.',
    'framework', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'name', 'Situação', 'focus', 'bem desejado, valor, cenário atual, prazo e capacidade financeira'),
      jsonb_build_object('sequence', 2, 'name', 'Problema', 'focus', 'dor, dificuldade, insatisfação, obstáculo e preocupação'),
      jsonb_build_object('sequence', 3, 'name', 'Implicação', 'focus', 'consequências financeiras, pessoais, familiares ou profissionais'),
      jsonb_build_object('sequence', 4, 'name', 'Necessidade', 'focus', 'o que uma boa solução precisa proporcionar'),
      jsonb_build_object('sequence', 5, 'name', 'Diagnóstico', 'focus', 'motivação principal e critério de decisão'),
      jsonb_build_object('sequence', 6, 'name', 'Frase-chave', 'focus', 'registrar a motivação ou problema com as palavras do cliente'),
      jsonb_build_object('sequence', 7, 'name', 'Próximo passo', 'focus', 'ação combinada, responsável e data')
    ),
    'exercise',
      'Use a ficha durante uma simulação ou atendimento e registre a frase-chave do cliente sem reescrevê-la com linguagem do vendedor.'
  )
),
(
  'fdf5c203-ddd9-568e-a6c6-855042644cb5'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid,
  'f373dfcd-f53e-5d37-b32c-c3e488634bc3'::uuid,
  2,
  'Exercício, checklist e compromisso de aplicação',
  'Treine a escolha da próxima pergunta, valide o diagnóstico antes da apresentação e assuma o compromisso de aplicar SPIN com disciplina comercial.',
  'interactive',
  12,
  true,
  'published',
  jsonb_build_object(
    'source_pages', jsonb_build_array(7, 8),
    'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
    'learning_objective',
      'Aplicar o raciocínio SPIN em respostas reais e verificar se há informação suficiente antes de apresentar o consórcio.',
    'exercise',
      'Em duplas, uma pessoa atua como cliente e outra como vendedor. Comece por Situação e avance apenas quando a resposta justificar a próxima etapa.',
    'practice_checklist', jsonb_build_array(
      'Entendi o projeto e a situação atual.',
      'Descobri um problema real ou uma necessidade relevante.',
      'Aprofundei consequências sem criar medo ou pressão.',
      'O cliente verbalizou o que espera de uma boa solução.',
      'Conheço a faixa de investimento confortável.',
      'Entendi o prazo desejado sem prometer contemplação.',
      'Consigo resumir o diagnóstico usando as palavras do cliente.',
      'Sei qual próximo passo faz sentido.'
    ),
    'closing_message',
      'Pergunte antes de apresentar. Aprofunde antes de argumentar. Entenda antes de oferecer. Apresente a solução a partir do que o cliente revelou.',
    'team_commitment',
      'Usar o SPIN como sequência de raciocínio, e não como questionário, em toda sondagem relevante.'
  )
);


-- ============================================================================
-- 3. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'module_count', 4,
  'lesson_count', 10,
  'estimated_duration_minutes', 90,
  'content_model_version', 'fase5b-v1',
  'source_asset_id', '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc',
  'source_asset_sha256', '580157A72D0F2F4675238B12D59272670E960C05BFAB4BFAE355D91353776F94'
)
where id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
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
  v_exact_asset bigint;
  v_learning_experience boolean;
  v_module_count_meta integer;
  v_lesson_count_meta integer;
  v_duration_meta integer;
  v_content_model_version text;
  v_source_asset_id text;
  v_source_asset_sha256 text;
begin
  select count(*)
  into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  select count(*)
  into v_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  select count(*)
  into v_required_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and is_required = true
    and status = 'published';

  select coalesce(sum(duration_minutes), 0)
  into v_total_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and status = 'published';

  select count(*)
  into v_progress
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  select count(*)
  into v_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid;

  select count(*)
  into v_exact_asset
  from public.training_library_assets
  where id = '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and sequence_no = 1
    and asset_type = 'workbook'
    and display_name = 'Apostila – SPIN Selling aplicado ao Consórcio'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/3e16b785-48d8-4b78-b21a-d6fe289c00b3/01_spin_selling_aplicado_ao_consorcio.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 555727
    and status = 'active';

  select
    coalesce((metadata ->> 'learning_experience')::boolean, false),
    coalesce((metadata ->> 'module_count')::integer, 0),
    coalesce((metadata ->> 'lesson_count')::integer, 0),
    coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0),
    metadata ->> 'content_model_version',
    metadata ->> 'source_asset_id',
    metadata ->> 'source_asset_sha256'
  into
    v_learning_experience,
    v_module_count_meta,
    v_lesson_count_meta,
    v_duration_meta,
    v_content_model_version,
    v_source_asset_id,
    v_source_asset_sha256
  from public.training_library_items
  where id = '3e16b785-48d8-4b78-b21a-d6fe289c00b3'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_modules <> 4 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: esperado 4 módulos; encontrado %',
      v_modules;
  end if;

  if v_lessons <> 10 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: esperado 10 aulas; encontrado %',
      v_lessons;
  end if;

  if v_required_lessons <> 10 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: esperado 10 aulas obrigatórias publicadas; encontrado %',
      v_required_lessons;
  end if;

  if v_total_duration <> 90 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: duração esperada 90 minutos; encontrado %',
      v_total_duration;
  end if;

  if v_progress <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: progresso artificial detectado; encontrado %',
      v_progress;
  end if;

  if v_assets <> 1 or v_exact_asset <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: asset publicado foi alterado';
  end if;

  if coalesce(v_learning_experience, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: treinamento não marcado como experiência de aprendizagem';
  end if;

  if v_module_count_meta <> 4
     or v_lesson_count_meta <> 10
     or v_duration_meta <> 90
     or v_content_model_version <> 'fase5b-v1'
     or v_source_asset_id <> '4f4e3e6d-d5ac-40ee-887f-1ab8067d0edc'
     or v_source_asset_sha256 <> '580157A72D0F2F4675238B12D59272670E960C05BFAB4BFAE355D91353776F94' then
    raise exception
      'TRAINING_LIBRARY_PHASE5B_POSTCONDITION_FAILED: metadados finais divergiram';
  end if;
end;
$postconditions$;
