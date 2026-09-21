-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5D
-- Escala da experiência de aprendizagem: Playbook do Supervisor RF Performance
--
-- Objetivos:
--   1. Estruturar o Playbook do Supervisor em 4 módulos e 8 aulas.
--   2. Preservar integralmente o PDF já publicado como material principal.
--   3. Organizar cadastro, vinculação, ativação, instalação PWA e checklist.
--   4. Reforçar preservação de histórico, segurança e escalonamento administrativo.
--   5. Não criar progresso artificial para nenhum usuário.
--   6. Falhar fechado se o estado remoto divergir do snapshot validado.
--
-- Fonte publicada validada:
--   asset_id: afdbd8d7-6d0e-4972-9136-3664b45c5344
--   arquivo: 01_playbook_supervisor_rf_performance.pdf
--   tamanho: 158105 bytes
--   sha256: 646D7B130709BB9911D293EEA208B57436EDA9A78BD2C0D8970082701F5BECB4
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
  where id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and sequence_no = 4
    and title = 'Playbook do Supervisor RF Performance'
    and description = 'Guia operacional para supervisores e líderes utilizarem os principais fluxos da RF Performance no acompanhamento da equipe.'
    and category = 'platform_guide'
    and to_jsonb(audience_roles) = '["director","supervisor"]'::jsonb
    and status = 'published'
    and is_featured = false
    and metadata = '{}'::jsonb;

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: item Playbook do Supervisor divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
  into v_asset_count
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  if v_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: esperado 1 asset; encontrado %',
      v_asset_count;
  end if;

  select count(*)
  into v_exact_asset_count
  from public.training_library_assets
  where id = 'afdbd8d7-6d0e-4972-9136-3664b45c5344'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and sequence_no = 1
    and asset_type = 'primary'
    and display_name = 'Playbook do Supervisor RF Performance'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/86c1cf11-1feb-498d-ac56-3b8ad6285eae/01_playbook_supervisor_rf_performance.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 158105
    and status = 'active';

  if v_exact_asset_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: PDF publicado divergiu do snapshot';
  end if;

  select count(*)
  into v_module_count
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  if v_module_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: treinamento já possui módulos; encontrado %',
      v_module_count;
  end if;

  select count(*)
  into v_lesson_count
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  if v_lesson_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: treinamento já possui aulas; encontrado %',
      v_lesson_count;
  end if;

  select count(*)
  into v_progress_count
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  if v_progress_count <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_PREFLIGHT_FAILED: treinamento possui progresso inesperado; encontrado %',
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
  '7ffb80fc-b0e2-5a14-a5b4-eec20e301375'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  1,
  'Governança do cadastro de vendedores',
  'Define responsabilidade do supervisor, pré-requisitos, vínculo obrigatório com a equipe e erros que devem ser evitados no ambiente operacional.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 18,
    'content_model_version', 'fase5d-v1'
  )
),
(
  '06f23089-4203-5121-ad4c-e432fd6831f0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  2,
  'Cadastro, vínculo e ativação',
  'Organiza o fluxo de convite, conferência da equipe, ativação pelo vendedor e tratamento inicial de problemas de acesso.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 22,
    'content_model_version', 'fase5d-v1'
  )
),
(
  '863d7f25-b2b0-5720-8e64-301810ca6c5d'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  3,
  'Instalação PWA e uso seguro',
  'Orienta instalação do RF Performance em dispositivos móveis e computadores, além de boas práticas de segurança e atualização.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 20,
    'content_model_version', 'fase5d-v1'
  )
),
(
  '0aa6678c-7459-540c-bfc6-2f3f17e87bfa'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  4,
  'Checklist do supervisor e escalonamento',
  'Consolida as verificações obrigatórias e define quando a administração deve ser acionada para preservar histórico e estrutura.',
  'published',
  jsonb_build_object(
    'estimated_duration_minutes', 15,
    'content_model_version', 'fase5d-v1'
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
-- Módulo 1 — Governança do cadastro de vendedores
-- --------------------------------------------------------------------------

(
  'f58e8507-1477-5f22-8add-0cf7a6e00eea'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '7ffb80fc-b0e2-5a14-a5b4-eec20e301375'::uuid,
  1,
  'Responsabilidade do supervisor e pré-requisitos',
  'Antes de cadastrar, confirme que o vendedor pertence à sua estrutura, que o supervisor está corretamente vinculado e que os dados básicos estão disponíveis.',
  'text',
  9,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(1, 2),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Confirmar responsabilidade, acesso, perfil, vínculo e dados mínimos antes de iniciar o cadastro.',
    'checklist', jsonb_build_array(
      'Acesso ao RF Performance ativo.',
      'Perfil Supervisor.',
      'Supervisor corretamente vinculado à equipe ou PDV.',
      'Nome completo do vendedor.',
      'E-mail válido acompanhado com frequência pelo vendedor.'
    ),
    'governance_rule',
      'O supervisor deve cadastrar apenas vendedores que pertençam à sua própria estrutura.'
  )
),
(
  '0f1f1f09-19b1-52d0-ae8c-8424d3d6392f'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '7ffb80fc-b0e2-5a14-a5b4-eec20e301375'::uuid,
  2,
  'Vínculo obrigatório e erros a evitar',
  'O vendedor precisa estar ligado à equipe correta desde o convite. Evite duplicidades, dados incorretos e cadastros fictícios no ambiente real.',
  'interactive',
  9,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(2),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Evitar erros de cadastro que prejudiquem vínculo, histórico, acesso ou integridade operacional.',
    'critical_rule',
      'Vendedor precisa de equipe: confira a equipe selecionada antes de enviar o convite.',
    'avoid', jsonb_build_array(
      'E-mail com erro de digitação.',
      'Criar segunda conta porque o vendedor mudou de equipe.',
      'Usar o e-mail de outra pessoa.',
      'Cadastrar vendedores fictícios no ambiente operacional real.',
      'Vincular o vendedor ao PDV ou equipe errados.'
    ),
    'scenario',
      'Se houver mudança de diretor, supervisor, PDV ou estrutura organizacional, encaminhe à administração da plataforma.'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 2 — Cadastro, vínculo e ativação
-- --------------------------------------------------------------------------

(
  'da1b9296-7eaa-5a0e-bca4-0edf91b5e0c1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '06f23089-4203-5121-ad4c-e432fd6831f0'::uuid,
  1,
  'Cadastro e vinculação do vendedor',
  'Siga o fluxo Administração → Usuários → Convidar usuário, informe os dados corretos, escolha o perfil Vendedor e selecione a equipe adequada.',
  'text',
  11,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(3),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Executar o convite com perfil e equipe corretos e conferir o resultado imediatamente após o envio.',
    'steps', jsonb_build_array(
      jsonb_build_object('sequence', 1, 'action', 'Acessar Administração > Usuários e clicar em + Convidar usuário.'),
      jsonb_build_object('sequence', 2, 'action', 'Informar o nome completo.'),
      jsonb_build_object('sequence', 3, 'action', 'Informar e conferir o e-mail.'),
      jsonb_build_object('sequence', 4, 'action', 'Selecionar o perfil Vendedor.'),
      jsonb_build_object('sequence', 5, 'action', 'Selecionar a equipe ou PDV correto.'),
      jsonb_build_object('sequence', 6, 'action', 'Enviar o convite.')
    ),
    'after_invite', jsonb_build_array(
      'Confirmar que o vendedor aparece na lista de Usuários.',
      'Conferir perfil Vendedor.',
      'Conferir status.',
      'Validar a equipe vinculada.'
    )
  )
),
(
  'a9c9c851-ec9a-5a84-8b31-bae92842e978'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '06f23089-4203-5121-ad4c-e432fd6831f0'::uuid,
  2,
  'Ativação do acesso e solução inicial de problemas',
  'Oriente o vendedor a localizar o convite, ativar o acesso, definir uma senha pessoal e concluir a entrada usando o e-mail cadastrado.',
  'interactive',
  11,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(4),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Orientar a ativação e diagnosticar problemas de recebimento sem criar contas duplicadas.',
    'activation_steps', jsonb_build_array(
      'Localizar o e-mail “Convite de acesso ao RF Performance”.',
      'Clicar em “Ativar meu acesso”.',
      'Definir uma senha pessoal.',
      'Concluir a ativação e acessar com o e-mail cadastrado.'
    ),
    'troubleshooting', jsonb_build_array(
      'Confirmar se o e-mail cadastrado está correto.',
      'Pesquisar por “RF Performance” na caixa de e-mail.',
      'Verificar Spam, Lixo eletrônico e Promoções.',
      'Se persistir, encaminhar o caso à administração.'
    ),
    'warning',
      'Não crie uma nova conta com outro e-mail sem orientação da administração.'
  )
),

-- --------------------------------------------------------------------------
-- Módulo 3 — Instalação PWA e uso seguro
-- --------------------------------------------------------------------------

(
  'cb72e321-b960-5076-b0d2-bfa6ca1d0a58'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '863d7f25-b2b0-5720-8e64-301810ca6c5d'::uuid,
  1,
  'Instalação no celular: Android, iPhone e iPad',
  'Instale o RF Performance diretamente pelo navegador usando sempre o domínio oficial performance.epsacore.com.br.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(5),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Orientar a instalação móvel do PWA a partir do domínio oficial.',
    'official_domain', 'https://performance.epsacore.com.br',
    'android', jsonb_build_array(
      'Abrir o RF Performance no Google Chrome.',
      'Confirmar que o endereço é performance.epsacore.com.br.',
      'Abrir o menu do Chrome.',
      'Escolher Instalar app, Instalar aplicativo ou Adicionar à tela inicial.',
      'Confirmar a instalação.'
    ),
    'ios', jsonb_build_array(
      'Abrir o RF Performance no Safari.',
      'Tocar em Compartilhar.',
      'Escolher Adicionar à Tela de Início.',
      'Confirmar o nome RF Performance e adicionar.'
    ),
    'note',
      'No iPhone, use o Safari para instalação conforme o playbook.'
  )
),
(
  '9a4a772c-7b13-5f9c-b25a-36f7c848aefc'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '863d7f25-b2b0-5720-8e64-301810ca6c5d'::uuid,
  2,
  'Instalação no computador, atualizações e segurança',
  'Use Chrome ou Edge para instalar o PWA no computador e adote práticas que protejam credenciais e sessões.',
  'text',
  10,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(6),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Instalar o PWA no desktop e aplicar boas práticas de segurança no uso diário.',
    'desktop_steps', jsonb_build_array(
      'Acessar o domínio oficial pelo Chrome ou Edge.',
      'Localizar a opção de instalação na barra de endereço ou menu.',
      'Confirmar a instalação para abrir o RF Performance em janela própria.'
    ),
    'updates',
      'O PWA é atualizado pela própria aplicação; não é necessário procurar nova versão em loja de aplicativos.',
    'security_practices', jsonb_build_array(
      'Não compartilhar senha.',
      'Usar sempre a própria conta.',
      'Encerrar a sessão em computadores compartilhados.',
      'Evitar deixar o aplicativo aberto em aparelhos sem bloqueio de tela.',
      'Ao trocar de celular, acessar novamente e reinstalar o PWA.'
    )
  )
),

-- --------------------------------------------------------------------------
-- Módulo 4 — Checklist do supervisor e escalonamento
-- --------------------------------------------------------------------------

(
  '52171db4-6580-5994-84c3-f998b694f42c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '0aa6678c-7459-540c-bfc6-2f3f17e87bfa'::uuid,
  1,
  'Checklist rápido do supervisor',
  'Valide os dez pontos do processo, do nome e e-mail até o vínculo final e a orientação de instalação do PWA.',
  'interactive',
  8,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(7),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Usar um checklist padrão para confirmar que cadastro, ativação, vínculo e orientação foram concluídos.',
    'checklist', jsonb_build_array(
      'Nome completo conferido.',
      'E-mail conferido.',
      'Perfil Vendedor selecionado.',
      'Equipe correta selecionada.',
      'Convite enviado.',
      'Vendedor orientado a ativar o acesso.',
      'Recebimento do convite confirmado.',
      'Ativação concluída.',
      'Vínculo com equipe conferido.',
      'Orientação de instalação PWA repassada.'
    )
  )
),
(
  '38fe15d4-df04-5b72-b52e-c13331876f19'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid,
  '0aa6678c-7459-540c-bfc6-2f3f17e87bfa'::uuid,
  2,
  'Quando acionar a administração e preservar o histórico',
  'Identifique situações que não devem ser resolvidas improvisando novos cadastros ou alterações fora do fluxo correto.',
  'text',
  7,
  true,
  'published',
  jsonb_build_object(
    'source_pdf_pages', jsonb_build_array(7),
    'source_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
    'learning_objective',
      'Escalonar corretamente exceções que envolvam identidade, vínculo, perfil ou continuidade histórica do usuário.',
    'escalate_when', jsonb_build_array(
      'Erro de e-mail.',
      'Conta duplicada.',
      'Mudança de equipe.',
      'Desligamento.',
      'Troca de perfil.',
      'Vendedor sem acesso.',
      'Convite que não pode ser concluído.',
      'Qualquer dúvida em que uma ação possa comprometer o histórico do usuário.'
    ),
    'summary_flow',
      'Nome correto → E-mail correto → Perfil Vendedor → Equipe correta → Convite → Ativação → Conferência → Instalação PWA'
  )
);


-- ============================================================================
-- 3. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata = metadata || jsonb_build_object(
  'learning_experience', true,
  'module_count', 4,
  'lesson_count', 8,
  'estimated_duration_minutes', 75,
  'content_model_version', 'fase5d-v1',
  'source_primary_asset_id', 'afdbd8d7-6d0e-4972-9136-3664b45c5344',
  'source_primary_sha256', '646D7B130709BB9911D293EEA208B57436EDA9A78BD2C0D8970082701F5BECB4'
)
where id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
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
  v_source_primary_asset_id text;
  v_source_primary_sha256 text;
begin
  select count(*)
  into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  select count(*)
  into v_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  select count(*)
  into v_required_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and is_required = true
    and status = 'published';

  select coalesce(sum(duration_minutes), 0)
  into v_total_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and status = 'published';

  select count(*)
  into v_progress
  from public.training_library_lesson_progress
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  select count(*)
  into v_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid;

  select count(*)
  into v_exact_asset
  from public.training_library_assets
  where id = 'afdbd8d7-6d0e-4972-9136-3664b45c5344'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and sequence_no = 1
    and asset_type = 'primary'
    and display_name = 'Playbook do Supervisor RF Performance'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/86c1cf11-1feb-498d-ac56-3b8ad6285eae/01_playbook_supervisor_rf_performance.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 158105
    and status = 'active';

  select
    coalesce((metadata ->> 'learning_experience')::boolean, false),
    coalesce((metadata ->> 'module_count')::integer, 0),
    coalesce((metadata ->> 'lesson_count')::integer, 0),
    coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0),
    metadata ->> 'content_model_version',
    metadata ->> 'source_primary_asset_id',
    metadata ->> 'source_primary_sha256'
  into
    v_learning_experience,
    v_module_count_meta,
    v_lesson_count_meta,
    v_duration_meta,
    v_content_model_version,
    v_source_primary_asset_id,
    v_source_primary_sha256
  from public.training_library_items
  where id = '86c1cf11-1feb-498d-ac56-3b8ad6285eae'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_modules <> 4 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: esperado 4 módulos; encontrado %',
      v_modules;
  end if;

  if v_lessons <> 8 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: esperado 8 aulas; encontrado %',
      v_lessons;
  end if;

  if v_required_lessons <> 8 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: esperado 8 aulas obrigatórias publicadas; encontrado %',
      v_required_lessons;
  end if;

  if v_total_duration <> 75 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: duração esperada 75 minutos; encontrado %',
      v_total_duration;
  end if;

  if v_progress <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: progresso artificial detectado; encontrado %',
      v_progress;
  end if;

  if v_assets <> 1 or v_exact_asset <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: asset publicado foi alterado';
  end if;

  if coalesce(v_learning_experience, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: treinamento não marcado como experiência de aprendizagem';
  end if;

  if v_module_count_meta <> 4
     or v_lesson_count_meta <> 8
     or v_duration_meta <> 75
     or v_content_model_version <> 'fase5d-v1'
     or v_source_primary_asset_id <> 'afdbd8d7-6d0e-4972-9136-3664b45c5344'
     or v_source_primary_sha256 <> '646D7B130709BB9911D293EEA208B57436EDA9A78BD2C0D8970082701F5BECB4' then
    raise exception
      'TRAINING_LIBRARY_PHASE5D_POSTCONDITION_FAILED: metadados finais divergiram';
  end if;
end;
$postconditions$;
