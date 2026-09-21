-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 5F-B
-- Enriquecimento pedagógico do Método VAP – Vendedor de Alta Performance
--
-- CORREÇÃO DE COMPATIBILIDADE
--   Esta revisão não usa tabelas temporárias. O SQL Editor do Supabase pode
--   executar lotes por conexões distintas, o que torna tabelas TEMP inadequadas
--   para um teste transacional colado no editor.
--
-- OBJETIVO
--   - enriquecer as 58 aulas do Método VAP com conteúdo pedagógico estruturado;
--   - usar metadata.content_sections, já suportado pelo player da Fase 5F-A;
--   - preservar IDs, módulos, títulos, descrições, duração, assets e progresso;
--   - manter a estrutura criada na Fase 5E.
--
-- FONTE PRIMÁRIA VALIDADA
--   asset_id: d51e0a0e-f39a-4de7-85e0-8cf8d8063530
--   arquivo: 01_metodo_vap.pdf
--   tamanho: 31058620 bytes
--   sha256: D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84
--
-- SEGURANÇA
--   - fail-closed antes e depois das atualizações;
--   - não altera training_library_lesson_progress;
--   - não altera RLS, grants, schema ou Storage;
--   - não recria aulas e não muda seus IDs.
-- ============================================================================

-- ============================================================================
-- 0. PREFLIGHT FAIL-CLOSED
-- ============================================================================

do $preflight$
declare
  v_item_count bigint;
  v_mapping_count bigint;
  v_existing_content bigint;
  v_exact_asset bigint;
  v_modules bigint;
  v_lessons bigint;
  v_duration bigint;
begin
  select count(*)
    into v_item_count
  from public.training_library_items
  where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and title = 'Método VAP – Vendedor de Alta Performance'
    and status = 'published'
    and coalesce((metadata ->> 'learning_experience')::boolean, false) = true
    and coalesce((metadata ->> 'module_count')::integer, 0) = 11
    and coalesce((metadata ->> 'lesson_count')::integer, 0) = 58
    and coalesce((metadata ->> 'estimated_duration_minutes')::integer, 0) = 580
    and metadata ->> 'content_model_version' = 'fase5e-v1'
    and not (metadata ? 'pedagogical_content_version');

  if v_item_count <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_PREFLIGHT_FAILED: treinamento VAP divergiu do snapshot; encontrado %',
      v_item_count;
  end if;

  select count(*)
    into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published';

  select count(*), coalesce(sum(duration_minutes), 0)
    into v_lessons, v_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published';

  if v_modules <> 11 or v_lessons <> 58 or v_duration <> 580 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_PREFLIGHT_FAILED: estrutura esperada 11/58/580; encontrada %/%/%',
      v_modules, v_lessons, v_duration;
  end if;

  select count(*)
    into v_mapping_count
  from (
    values
      (1, 1, 'e4183ed3-2d2d-5499-a294-63e48a48f67e'::uuid, 'Introdução ao Método VAP'),
      (1, 2, '73bd9c2d-794f-5ab5-9444-14a4b3bfc586'::uuid, 'Os Pilares do VAP'),
      (1, 3, 'd59f8992-1c9a-59cf-8065-d47fca7cb94a'::uuid, 'Como o VAP se Diferencia'),
      (1, 4, 'b60063e2-adb9-50d5-aec6-87320810ac7f'::uuid, 'Aplicação Prática do Método VAP'),
      (1, 5, '12a39e63-b2df-5d28-9ce7-acbe805d21c6'::uuid, 'Cases de Sucesso Usando o VAP'),
      (2, 1, '1c6f4600-f9ab-571b-b436-4eb08d2a35b8'::uuid, 'Como É a Mentalidade do VAP?'),
      (2, 2, '9da50584-f717-5b5c-bc27-6f6c946c3e21'::uuid, 'Características do Vendedor com Mentalidade Vencedora'),
      (2, 3, 'a5130e95-fea2-5884-966e-27c25c9301a4'::uuid, 'Crenças Limitantes x Crenças Fortalecedoras'),
      (2, 4, '9620f30a-0785-5582-aab7-8ac41bc9fba3'::uuid, 'Como Desenvolver uma Mentalidade Inabalável'),
      (2, 5, '448281e6-0909-5b0a-a689-269c0175f0bf'::uuid, 'Disciplina, Resiliência e Motivação no Processo de Vendas'),
      (3, 1, '20d8e991-d8b7-5d71-8f78-796a90ba8639'::uuid, 'Definição de Valor'),
      (3, 2, '535c2e8b-cf56-551e-8d2f-4ab8c50ed4f8'::uuid, 'Valor x Preço'),
      (3, 3, '8d06e7ee-fab8-547a-a095-9f6f98999d68'::uuid, 'Aumentar o Valor Percebido'),
      (3, 4, 'b8d608e1-daf9-56d7-9e59-b40456a1f21d'::uuid, 'Agregar Valor ao Produto/Serviço'),
      (3, 5, '25fcbc7f-2140-5388-bf87-06c6004f1805'::uuid, 'O VAP na Construção do Valor'),
      (4, 1, 'c5bacfee-513a-5cf2-b20e-7b6891b61173'::uuid, 'Autoconhecimento como Base da Liderança'),
      (4, 2, '4f214a8d-4404-5d13-b054-67c3b563a06c'::uuid, 'Características dos Grandes Líderes de Vendas'),
      (4, 3, 'f323a414-90e9-5d6c-a545-f562fae08ae1'::uuid, 'Estilos de Liderança'),
      (4, 4, '2a3d4e96-ae4c-5c9b-9988-0d030202a9d0'::uuid, 'Tomada de Decisão e Inteligência Emocional'),
      (4, 5, '0c4f7481-55a5-5962-bce4-6950b37f1f46'::uuid, 'Equipes de Alta Performance'),
      (5, 1, 'd007d897-23be-593b-8938-5facaa48442b'::uuid, 'Fundamentos DISC: a Origem da Metodologia'),
      (5, 2, '960fada6-2a28-53d9-a95a-c360af6f54bd'::uuid, 'Perfis D, I, S e C'),
      (5, 3, 'c6d3b804-bb2c-57ff-9b4c-6a23fe5f5185'::uuid, 'As 16 Competências Comportamentais'),
      (5, 4, '53fe8616-3069-51af-9afb-5529c7d2bcee'::uuid, 'Planos de Desenvolvimento por Perfil'),
      (5, 5, '82ab47dd-22df-5b5e-8ae2-e274dc719092'::uuid, 'Método Espelho Comportamental'),
      (6, 1, '0ecc9e72-fa09-58a5-a851-a981cbd653cc'::uuid, 'O que É Neurovendas'),
      (6, 2, '7f869447-c32b-5ac6-ab58-fb1ac5d510a0'::uuid, 'Os 3 Cérebros no Processo de Compra'),
      (6, 3, 'ebb3f44b-e355-53bc-a294-87fc6561e1d9'::uuid, 'Neurociência na Tomada de Decisão'),
      (6, 4, '6a9bb606-b693-5b94-a826-982a0b1bcfbf'::uuid, 'Modelo AIDA Neurológico'),
      (6, 5, '6ee2d4e2-4849-560c-86c0-52db0290eb4a'::uuid, 'Os 12 Gatilhos Mentais em Vendas'),
      (7, 1, '27bdfd9e-c811-5a6d-a0dc-97f9aae54a3c'::uuid, 'O Principal Objetivo do Copywriting'),
      (7, 2, '2515b682-9ff5-5c4e-8fcf-b4e7abab3203'::uuid, 'Estratégia de Copywriting VAP'),
      (7, 3, '506a2488-a392-5c65-b87f-31fc9faf7058'::uuid, 'Fórmulas de Copywriting'),
      (7, 4, '0ed2797e-4500-51d9-9aec-eaf666876075'::uuid, 'Copy para Redes Sociais e Anúncios'),
      (7, 5, '6388f495-2c6f-5189-b628-b41aae3d97b6'::uuid, 'Copywriting para Vendas de Alto Valor'),
      (8, 1, 'c4ed3f6e-1d9e-55e9-9ac2-ce71a1a6c904'::uuid, 'Prospecção Eficiente'),
      (8, 2, '5c5ac5ea-1278-5e81-97ee-0f7809f162cd'::uuid, 'Abordagem – Rapport e Comunicação'),
      (8, 3, '38dd8e28-c807-58da-a816-1f54cabf0e63'::uuid, 'SPIN Selling'),
      (8, 4, 'd60d7991-ebcb-514d-98e2-f0440ac542d1'::uuid, 'Argumentação CAB e Negociação'),
      (8, 5, '5c62b0ea-6c21-560e-8ca8-0b3ef0444ac4'::uuid, 'Fechamento e Pós-Venda'),
      (9, 1, '6e68a758-fb30-53e5-a883-c96b59d3206f'::uuid, 'O que São Objeções e Por que Ocorrem'),
      (9, 2, '78d7d4da-1900-5b62-b0e3-49b41518b94a'::uuid, 'As 6 Objeções Universais'),
      (9, 3, 'f3c67e45-0798-5641-aeac-273bdfc97b15'::uuid, 'Metodologia CALMA: C – Compreender'),
      (9, 4, '01212daa-542c-51c4-97c9-6086334e5bf7'::uuid, 'Metodologia CALMA: A – Acolher e L – Levantar'),
      (9, 5, '43d8d34c-4482-5767-9f38-0cc510cc2fb8'::uuid, 'Metodologia CALMA: M – Mostrar e A – Avançar'),
      (9, 6, '2f6882c7-994f-5a13-b920-ce38ca9a75d5'::uuid, 'Técnicas Práticas: Reenquadramento e Comparação de Valor'),
      (9, 7, '9c75272d-2b97-5fa1-83ac-ef081ad07395'::uuid, 'Objeções de Timing: Criando Urgência Sem Pressão'),
      (9, 8, '75d2c3cd-3f0c-5221-9ce5-974e39b12c8c'::uuid, 'Objeções de Autoridade: Navegando Múltiplos Tomadores de Decisão'),
      (9, 9, '23183b1d-ce03-5fa7-99a5-994f20331a5a'::uuid, 'Prática e Consolidação: Dominando o Contorno de Objeções'),
      (10, 1, '7240b0d2-7aac-5975-81d1-0ff7c1add1c0'::uuid, 'Como a IA Potencializa suas Vendas'),
      (10, 2, 'f773e896-59e2-5663-a5e3-35806304ca92'::uuid, 'Ferramentas de IA por Categoria'),
      (10, 3, '195841c0-c371-50f3-ac10-70813d31051a'::uuid, 'IA na Personalização'),
      (10, 4, 'ca422a7e-58ea-5377-b7b0-f364291044e0'::uuid, 'Chatbots e Assistentes Virtuais'),
      (10, 5, 'b3facd62-f746-5e42-9297-96aa212ab1b8'::uuid, 'Futuro das Vendas e Roadmap de Implementação'),
      (11, 1, '4ee41919-af82-5b48-9470-f04f170918fb'::uuid, 'Fundamentos da Persuasão Ética'),
      (11, 2, 'c1412f1c-6848-5488-828e-3cdcd68a07c5'::uuid, 'Comunicação Não-Verbal e Presença Persuasiva'),
      (11, 3, '8182ae96-312a-5026-8e8e-6e6ba083e9c7'::uuid, 'Storytelling Persuasivo'),
      (11, 4, 'e8a4ffb7-76c6-52b6-9d37-65f1949d238c'::uuid, 'Técnicas Avançadas de Fechamento')
  ) as expected(module_sequence, lesson_sequence, lesson_id, lesson_title)
  join public.training_library_lessons l
    on l.id = expected.lesson_id
   and l.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
   and l.training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
   and l.status = 'published'
   and l.title = expected.lesson_title
   and coalesce((l.metadata ->> 'source_module_sequence')::integer, 0) = expected.module_sequence
   and coalesce((l.metadata ->> 'source_lesson_sequence')::integer, 0) = expected.lesson_sequence
   and l.metadata ->> 'content_model_version' = 'fase5e-v1';

  if v_mapping_count <> 58 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_PREFLIGHT_FAILED: identidade das aulas divergiu; correspondências %',
      v_mapping_count;
  end if;

  select count(*)
    into v_existing_content
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published'
    and (
      metadata ? 'content_sections'
      or metadata ? 'pedagogical_content_version'
      or metadata ? 'learning_objective'
      or metadata ? 'summary'
      or metadata ? 'key_points'
    );

  if v_existing_content <> 0 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_PREFLIGHT_FAILED: conteúdo pedagógico já encontrado em % aulas; revisar antes de prosseguir',
      v_existing_content;
  end if;

  select count(*)
    into v_exact_asset
  from public.training_library_assets
  where id = 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and sequence_no = 1
    and asset_type = 'primary'
    and storage_bucket = 'training-materials'
    and storage_path = '414a2e84-bc62-4c64-99ee-76db1cbc4654/8cf3f39c-ee82-409d-b499-7cf321a54b04/01_metodo_vap.pdf'
    and mime_type = 'application/pdf'
    and file_size_bytes = 31058620
    and status = 'active';

  if v_exact_asset <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_PREFLIGHT_FAILED: PDF primário divergiu do snapshot';
  end if;
end;
$preflight$;

-- ============================================================================
-- 1. ENRIQUECIMENTO DAS 58 AULAS
-- ============================================================================

update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Compreender o Método VAP como um sistema replicável de vendas baseado em Valor, Abordagem e Performance.","summary":"O VAP foi apresentado no material como um sistema construído a partir de prática comercial, com foco em processo e não em talento isolado. Seu nome resume três pilares: construir valor, conduzir cada interação com método e medir a performance para melhorar continuamente.","key_points":["V significa Valor: construir e comunicar valor antes de vender.","A significa Abordagem: estruturar a interação do primeiro contato ao pós-venda.","P significa Performance: medir, analisar e melhorar resultados.","A proposta do método é tornar a execução replicável, não dependente de carisma."],"content_sections":[{"title":"O que muda com o VAP","body":"Em vez de confiar em improviso, talento ou carisma, o vendedor trabalha com um processo que pode ser aprendido, repetido e aperfeiçoado. O objetivo é transformar boas práticas em rotina comercial consistente.","variant":"default"},{"title":"V · A · P na rotina","items":["Valor: descubra o que importa para o cliente e traduza sua solução em benefício percebido.","Abordagem: siga uma sequência clara de contato, descoberta, apresentação, objeções, fechamento e pós-venda.","Performance: acompanhe os resultados e ajuste o processo com base em evidências."],"variant":"highlight"},{"title":"Exercício de abertura","body":"Escreva em uma frase qual é hoje o seu maior diferencial como vendedor. Guarde a resposta para compará-la com sua visão ao final do treinamento.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'e4183ed3-2d2d-5499-a294-63e48a48f67e'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Introdução ao Método VAP'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 1
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Identificar os cinco pilares interdependentes que sustentam a execução do Método VAP.","summary":"O método se apoia em Mentalidade, Conhecimento do Cliente, Processo Estruturado, Comunicação Persuasiva e Melhoria Contínua. A força do sistema vem da integração: técnica sem mentalidade, processo sem conhecimento do cliente ou comunicação sem medição enfraquecem o resultado.","key_points":["Mentalidade sustenta disciplina e resiliência.","Conhecimento do cliente orienta a adaptação da abordagem.","Processo estruturado reduz improviso entre as etapas da venda.","Comunicação persuasiva deve ser aplicada de forma ética.","Melhoria contínua transforma dados em ajustes de execução."],"content_sections":[{"title":"Os cinco pilares","items":["Mentalidade: crenças, disciplina e resiliência.","Conhecimento do Cliente: perfil, dores e motivadores antes da abordagem.","Processo Estruturado: prospecção, abordagem, descoberta, apresentação, objeções, fechamento e pós-venda.","Comunicação Persuasiva: copywriting, storytelling, linguagem corporal e gatilhos usados com ética.","Melhoria Contínua: medir, localizar gargalos e revisar o processo."],"variant":"default"},{"title":"Framework VAP – 5 passos","body":"O material resume a lógica como Valor · Abordagem · Processo · Persuasão · Feedback. Use essa sequência como mapa para avaliar onde sua venda perde força.","variant":"highlight"},{"title":"Aplicação prática","body":"Escolha uma venda recente que não avançou e identifique qual dos cinco pilares estava mais fraco. Registre uma ação concreta para corrigir esse ponto na próxima oportunidade.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '73bd9c2d-794f-5ab5-9444-14a4b3bfc586'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Os Pilares do VAP'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 1
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Distinguir o Método VAP de treinamentos baseados em técnicas isoladas e compreender por que processo, comportamento e medição precisam atuar juntos.","summary":"O material contrapõe métodos centrados em técnicas pontuais ao VAP, que cobre a jornada completa, incorpora leitura comportamental e trabalha com indicadores. A meta é reduzir dependência de talento individual e aumentar previsibilidade e replicabilidade.","key_points":["O VAP é sistêmico: cobre toda a venda, não apenas momentos de crise.","É comportamental: integra DISC, neurociência e comunicação não verbal.","É mensurável: cada etapa pode ser acompanhada por indicadores.","Processos replicáveis facilitam treinamento e escala de equipes."],"content_sections":[{"title":"Técnica isolada x sistema","body":"Saber responder uma objeção ou fazer um fechamento não garante consistência quando as etapas anteriores foram mal conduzidas. O VAP organiza as competências dentro de uma sequência de venda completa.","variant":"default"},{"title":"Três diferenciais","items":["Sistêmico: conecta todas as etapas da jornada comercial.","Comportamental: adapta a comunicação ao modo como o cliente percebe e decide.","Mensurável: usa dados para entender o que funciona e onde o processo trava."],"variant":"highlight"},{"title":"Pergunta de diagnóstico","body":"Quando seus resultados variam muito de uma semana para outra, pergunte: a equipe está seguindo um processo comum ou cada vendedor está dependendo do próprio estilo?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'd59f8992-1c9a-59cf-8065-d47fca7cb94a'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Como o VAP se Diferencia'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 1
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Transformar o Método VAP em rotina por meio de diagnóstico, implementação modular, medição e ajuste.","summary":"A aplicação proposta no material ocorre em quatro níveis. Primeiro, o vendedor identifica onde está; depois implementa um módulo por vez; mede os resultados após a prática e, por fim, ajusta o processo com base nos dados.","key_points":["Diagnosticar antes de mudar evita atacar o problema errado.","Implementar um módulo por vez facilita consolidação.","Medir semanalmente permite comparar execução e resultado.","Ajustar com base em dados mantém o método vivo."],"content_sections":[{"title":"Os quatro níveis de aplicação","items":["Diagnóstico: levante taxas de conversão, gargalos e perfis de cliente mais difíceis.","Implementação modular: pratique uma competência por vez até ganhar consistência.","Medição: registre resultados e revise o checklist semanal.","Ajuste: corrija o processo com base no que os dados mostram."],"variant":"default"},{"title":"Ritmo sugerido pelo material","body":"A fonte recomenda dedicar cerca de duas semanas de implementação por módulo antes de avançar. A intenção é evitar acúmulo de teoria sem prática.","variant":"highlight"},{"title":"Plano desta semana","body":"Escolha apenas um comportamento do VAP para implementar nos próximos sete dias, defina uma métrica simples e marque uma data para revisar o resultado.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'b60063e2-adb9-50d5-aec6-87320810ac7f'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Aplicação Prática do Método VAP'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 1
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Extrair dos cases apresentados os princípios de treinamento, replicabilidade e formação de líderes que sustentam a escala do método.","summary":"Os cases do material relacionam os resultados à formação estruturada de vendedores, à replicação do processo em novas operações e ao desenvolvimento de líderes que assumiram maior responsabilidade. A lição central é que disciplina de processo supera dependência de talento isolado.","key_points":["Treinamento antes da pressão por produção fortalece a base da equipe.","Um método documentado pode ser replicado em novas operações.","Formar líderes amplia a capacidade de escala.","O aprendizado de um case deve ser convertido em comportamento repetível."],"content_sections":[{"title":"O que os cases demonstram","body":"Os exemplos apresentados conectam crescimento a onboarding, formação de equipe e repetição do método em contextos diferentes. O foco não está em uma venda excepcional, mas na capacidade de repetir boas práticas.","variant":"default"},{"title":"Lição central","body":"Processo certo + disciplina de execução cria uma base mais sustentável do que depender de vendedores naturalmente talentosos.","variant":"highlight"},{"title":"Exercício final do módulo","body":"Escolha um case de sucesso da sua própria trajetória. Descreva o que você fez de diferente, quais etapas podem ser repetidas e quais comportamentos dependiam apenas de improviso.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '12a39e63-b2df-5d28-9ce7-acbe805d21c6'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Cases de Sucesso Usando o VAP'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 1
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer os sete pilares psicológicos que formam a mentalidade do Vendedor de Alta Performance.","summary":"A mentalidade VAP é apresentada como uma escolha consciente de como encarar o processo comercial. Ela combina responsabilidade, foco na execução, aprendizado, identidade profissional, tolerância à incerteza, visão de longo prazo e disciplina.","key_points":["Assumir responsabilidade evita terceirizar o resultado.","Foco em processo reduz ansiedade por resultado imediato.","Cada rejeição pode gerar informação útil.","Disciplina mantém a execução mesmo quando a motivação varia."],"content_sections":[{"title":"Os 7 pilares da mentalidade VAP","items":["Responsabilidade radical.","Foco em processo, não apenas em resultado.","Aprendizado contínuo.","Identidade de vendedor de alta performance.","Tolerância à incerteza e ao ''não''.","Visão de longo prazo em ciclos de evolução.","Disciplina não negociável nas atividades essenciais."],"variant":"default"},{"title":"Mudança de foco","body":"Resultado é consequência de atividades repetidas. Em vez de perguntar apenas ''quanto vendi?'', acompanhe também se prospectou, fez follow-up e revisou o pipeline conforme o combinado.","variant":"highlight"},{"title":"Autoavaliação","body":"Dê uma nota de 1 a 10 para cada um dos sete pilares e escolha o menor deles como prioridade de desenvolvimento desta semana.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '1c6f4600-f9ab-571b-b436-4eb08d2a35b8'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Como É a Mentalidade do VAP?'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 2
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Identificar comportamentos treináveis associados à mentalidade vencedora e avaliar quais precisam ser fortalecidos.","summary":"O material descreve o vendedor de alta performance como alguém construído por hábitos e escolhas: proatividade, curiosidade, resiliência, organização, empatia, consistência, orientação a dados, clareza na comunicação, compromisso com pós-venda, adaptabilidade, integridade e estudo contínuo.","key_points":["Mentalidade vencedora se manifesta em comportamentos observáveis.","Curiosidade e empatia melhoram a descoberta de necessidades.","Organização e dados aumentam controle do processo.","Integridade e pós-venda protegem reputação e relacionamento."],"content_sections":[{"title":"Comportamentos que podem ser desenvolvidos","items":["Ser proativo e buscar oportunidades.","Fazer perguntas antes de apresentar soluções.","Recuperar-se das rejeições e manter consistência.","Manter pipeline e agenda organizados.","Adaptar a comunicação ao perfil do cliente.","Estudar continuamente vendas, produto e mercado."],"variant":"default"},{"title":"Critério de alta performance","body":"A diferença não está em parecer motivado o tempo todo, mas em sustentar comportamentos úteis mesmo em dias de baixa energia ou após uma sequência de negativas.","variant":"highlight"},{"title":"Plano de desenvolvimento","body":"Escolha duas características que você já demonstra bem e uma que precisa fortalecer. Defina um comportamento observável para praticar nos próximos cinco dias.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '9da50584-f717-5b5c-bc27-6f6c946c3e21'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Características do Vendedor com Mentalidade Vencedora'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 2
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aprender a identificar crenças limitantes e substituí-las por interpretações mais úteis usando o método ABCDE.","summary":"Crenças influenciam ação. O material propõe reconhecer pensamentos aceitos como verdade, questionar os que bloqueiam a execução e substituí-los por crenças fortalecedoras. O ABCDE organiza esse processo a partir da adversidade, da crença e de suas consequências.","key_points":["Uma crença limitante reduz possibilidades antes da ação.","Crenças fortalecedoras não negam a realidade; ampliam alternativas de resposta.","O ABCDE separa evento, interpretação, consequência, disputa e nova energia.","Questionar crenças exige buscar fatos, utilidade e alternativas."],"content_sections":[{"title":"Método ABCDE","items":["A – Adversidade: o que aconteceu.","B – Belief/Crença: o que você pensou sobre o evento.","C – Consequência: como pensou, sentiu e agiu.","D – Disputa: a crença é factual e útil? Existem outras explicações?","E – Energização: escolha uma crença fortalecedora e um comportamento coerente com ela."],"variant":"default"},{"title":"Exemplo de reenquadramento","body":"Troque ''o cliente sempre acha caro'' por uma pergunta mais útil: ''eu consegui construir valor antes de falar de preço?''. O novo pensamento abre espaço para melhorar a execução.","variant":"highlight"},{"title":"Exercício","body":"Registre uma situação recente em que você travou, escreva o pensamento automático que surgiu e percorra as cinco etapas do ABCDE até chegar a uma nova ação prática.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'a5130e95-fea2-5884-966e-27c25c9301a4'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Crenças Limitantes x Crenças Fortalecedoras'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 2
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar práticas que aumentem estabilidade emocional e capacidade de manter desempenho diante de pressão.","summary":"A mentalidade inabalável não elimina dificuldade. O material orienta construir respostas mais consistentes por meio do controle do ambiente interno, aprendizado com a adversidade, rotina de estado e diário de vendas.","key_points":["Identificar gatilhos ajuda a preparar respostas antes da pressão.","Antifragilidade significa usar dificuldades como fonte de aprendizado.","Rituais curtos ajudam a regular o estado antes da venda.","Registrar vitórias, aprendizados e ajustes acelera evolução."],"content_sections":[{"title":"Quatro práticas","items":["Controle do ambiente interno: identifique gatilhos e defina respostas padrão.","Antifragilidade: transforme semanas difíceis em aprendizado aplicável.","Rotina de estado: reserve minutos antes do expediente para metas, respiração e propósito.","Diário de vendas: registre 1 vitória, 1 aprendizado e 1 ajuste por dia."],"variant":"default"},{"title":"O que significa ser inabalável","body":"Não é deixar de sentir frustração ou pressão. É reduzir o tempo que essas emoções controlam sua execução e voltar mais rápido ao comportamento necessário.","variant":"highlight"},{"title":"Prática de hoje","body":"Escolha um gatilho que costuma tirar você do eixo e escreva uma resposta padrão: o que você fará, pensará e registrará quando ele aparecer novamente.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '9620f30a-0785-5582-aab7-8ac41bc9fba3'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Como Desenvolver uma Mentalidade Inabalável'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 2
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Integrar disciplina, resiliência e motivação em um plano de evolução comercial de 90 dias.","summary":"A tríade do VAP distribui papéis diferentes: disciplina mantém a atividade quando a vontade diminui; resiliência acelera a recuperação após adversidades; motivação tende a crescer quando a ação começa a produzir evidências de progresso.","key_points":["Disciplina cria consistência por meio de atividades não negociáveis.","Resiliência reduz o tempo de recuperação depois de um revés.","Motivação não precisa vir antes da ação.","O plano de 90 dias organiza fundamentos, técnica e escala."],"content_sections":[{"title":"A tríade do desempenho","items":["Disciplina: execute prospecção, follow-up e revisão mesmo sem motivação.","Resiliência: coloque um ''não'' em perspectiva e retome o processo rapidamente.","Motivação: trate-a como consequência do movimento e dos primeiros resultados."],"variant":"default"},{"title":"Plano VAP de 90 dias","items":["Dias 1–30: diagnóstico e fundamentos.","Dias 31–60: técnica e execução, incluindo descoberta, objeções e fechamento.","Dias 61–90: escala e consistência, com IA, pós-venda e métricas."],"variant":"highlight"},{"title":"Compromisso","body":"Defina três atividades não negociáveis para os próximos 30 dias e registre quando e como serão acompanhadas.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '448281e6-0909-5b0a-a689-269c0175f0bf'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Disciplina, Resiliência e Motivação no Processo de Vendas'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 2
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Compreender valor percebido e mapear benefícios funcionais, emocionais e sociais antes de discutir preço.","summary":"Valor é aquilo que o cliente percebe que recebe em relação ao investimento. O material diferencia valor funcional, emocional e social e apresenta o modelo BRIDGE para conectar benefício, resultado, impacto, diferenciação, garantia e experiência.","key_points":["Valor percebido é construído na mente do cliente.","Benefícios funcionais explicam o que a solução faz.","Benefícios emocionais explicam como a solução faz o cliente se sentir.","Benefícios sociais envolvem identidade, status ou pertencimento.","O modelo BRIDGE ajuda a organizar a proposta de valor."],"content_sections":[{"title":"Três dimensões de valor","items":["Funcional: benefícios práticos e desempenho mensurável.","Emocional: segurança, confiança, satisfação ou alívio.","Social: pertencimento, identidade ou reconhecimento associado à escolha."],"variant":"default"},{"title":"Modelo BRIDGE","items":["Benefício: o que o cliente ganha.","Resultado: qual impacto mensurável aparece.","Impacto: como isso transforma o contexto.","Diferenciação: o que torna a solução distinta.","Garantia: como o risco é reduzido.","Experiência: como é a jornada completa."],"variant":"highlight"},{"title":"Exercício","body":"Escolha uma característica do seu produto e responda: para quem isso é um benefício? Qual resultado gera? Que impacto emocional ou social pode ter?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '20d8e991-d8b7-5d71-8f78-796a90ba8639'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Definição de Valor'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 3
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Diagnosticar o que existe por trás da frase ''está caro'' e responder construindo valor em vez de apenas defender preço.","summary":"A objeção de preço pode significar falta de valor percebido, comparação com alternativa, restrição orçamentária, baixa urgência, desconfiança, ausência de autoridade para decidir ou teste de negociação. A resposta eficaz depende de descobrir qual cenário está presente.","key_points":["Preço não deve ser tratado como objeção única.","Construir valor antes de apresentar preço reduz resistência.","Perguntas revelam se o problema é orçamento, confiança, urgência ou comparação.","Custo da inação ajuda o cliente a avaliar o impacto de permanecer como está."],"content_sections":[{"title":"Sete leituras possíveis para ''está caro''","items":["Valor insuficientemente construído.","Comparação com alternativa mais barata.","Restrição orçamentária real.","Falta de urgência percebida.","Desconfiança na promessa.","Ausência de autoridade para decidir.","Teste de negociação ou tentativa de desconto."],"variant":"default"},{"title":"Regra fundamental","body":"Não avance para defesa de preço sem antes estabelecer o que a solução resolve e o retorno esperado. Quanto mais claro o valor, mais o preço passa a ser analisado como investimento.","variant":"highlight"},{"title":"Perguntas úteis","items":["Qual é o custo de continuar com esse problema?","O que você está usando como referência para comparar este investimento?","A maior preocupação é caber no orçamento ou ter certeza do retorno?"],"variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '535c2e8b-cf56-551e-8d2f-4ab8c50ed4f8'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Valor x Preço'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 3
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Usar estratégias éticas de apresentação para aumentar a percepção de valor sem alterar artificialmente o produto.","summary":"O material apresenta seis formas de elevar valor percebido: ancoragem, prova social, especificidade, comparação objetiva, apresentação de ROI e embalagem de valor. A qualidade está em usar evidências reais e conectar cada estratégia ao contexto do cliente.","key_points":["Ancoragem cria referência para comparar opções.","Prova social precisa ser específica e verdadeira.","Dados concretos geram mais credibilidade do que generalidades.","ROI traduz benefício para linguagem financeira.","Embalagem de valor reúne suporte, garantias e adicionais relevantes."],"content_sections":[{"title":"Seis estratégias","items":["Ancoragem de preço ou opções.","Prova social com casos verificáveis.","Especificidade de números, prazos e métricas.","Comparação justa e objetiva.","Cálculo simples de retorno sobre investimento.","Embalagem com bônus, suporte ou garantias que realmente existam."],"variant":"default"},{"title":"Sequência de construção","body":"Apresente uma referência, sustente com prova concreta, diferencie sem atacar concorrentes, traduza impacto em números e mostre o pacote completo de valor.","variant":"highlight"},{"title":"Aplicação","body":"Pegue uma proposta atual e substitua três afirmações genéricas por dados específicos, exemplos verificáveis ou uma conta simples de impacto financeiro.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '8d06e7ee-fab8-547a-a095-9f6f98999d68'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Aumentar o Valor Percebido'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 3
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Identificar em qual nível da Pirâmide de Valor sua oferta está sendo percebida e planejar formas reais de elevá-la.","summary":"A fonte organiza valor em quatro níveis: produto básico, esperado, ampliado e potencial. Quanto mais a percepção fica restrita ao básico, maior a tendência de comparação por preço. A diferenciação aumenta quando a experiência inclui suporte, garantia, comunidade, treinamento ou propósito relevante.","key_points":["Produto básico entrega a função central.","Produto esperado corresponde ao padrão mínimo do mercado.","Produto ampliado adiciona experiência e serviços complementares.","Produto potencial conecta a oferta a uma visão ou transformação maior.","Agregar valor exige comunicar o que foi efetivamente entregue."],"content_sections":[{"title":"Pirâmide de Valor","items":["Básico: função central do produto.","Esperado: características que o mercado já considera padrão.","Ampliado: extras, suporte, treinamento, comunidade e garantias.","Potencial: propósito, visão e transformação que ultrapassam a função básica."],"variant":"default"},{"title":"Como subir de nível","items":["Documente onde sua oferta está hoje.","Identifique lacunas de experiência ou suporte.","Planeje adições reais de valor.","Implemente antes de prometer.","Comunique os diferenciais de forma clara."],"variant":"highlight"},{"title":"Exercício","body":"Liste o que seu cliente recebe hoje nos quatro níveis. Marque quais elementos são apenas discurso e quais já fazem parte da entrega real.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'b8d608e1-daf9-56d7-9e59-b40456a1f21d'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Agregar Valor ao Produto/Serviço'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 3
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Integrar a construção de valor em todas as etapas da venda e planejar 90 dias de fortalecimento de autoridade.","summary":"No VAP, valor não aparece apenas na apresentação. Ele começa na descoberta, orienta a argumentação, ajuda no tratamento de objeções, sustenta o fechamento e precisa ser confirmado no pós-venda. O material também propõe um plano de 90 dias para transformar valor entregue em autoridade percebida.","key_points":["Descoberta identifica valor funcional, emocional e social.","Apresentação usa dados, ROI e prova social relevantes.","Objeções exigem diagnóstico do motivo real da resistência.","Pós-venda confirma se o valor prometido foi entregue.","Autoridade é construída de forma consistente, não instantânea."],"content_sections":[{"title":"Valor ao longo da jornada","items":["Abordagem: mapear contexto e necessidades.","Apresentação: transformar necessidades em caso específico de valor.","Objeções: responder à causa real, não à frase superficial.","Fechamento: reforçar retorno, reduzir risco e esclarecer entrega.","Pós-venda: cumprir promessa, apoiar o cliente e gerar evidência para futuras vendas."],"variant":"default"},{"title":"Plano de 90 dias","items":["Dias 1–30: mapear proposta de valor e documentar casos.","Dias 31–60: ampliar presença, conteúdo, networking e depoimentos.","Dias 61–90: consolidar processo, casos e posicionamento como referência."],"variant":"highlight"},{"title":"Aplicação","body":"Escolha uma etapa da sua jornada comercial onde o cliente ainda recebe pouca evidência de valor e defina uma melhoria concreta para implementar nesta semana.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '25fcbc7f-2140-5388-bf87-06c6004f1805'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'O VAP na Construção do Valor'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 3
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Usar autoconhecimento e feedback para ampliar consciência sobre o próprio estilo de liderança.","summary":"O material coloca autoconhecimento como base da liderança sustentável e usa a Janela de Johari para diferenciar o que é conhecido por você e pelos outros. A proposta é reduzir pontos cegos por meio de feedback e autoavaliação.","key_points":["A liderança perde consistência quando o líder desconhece seus padrões.","A Janela de Johari ajuda a identificar áreas abertas, cegas, ocultas e desconhecidas.","Feedback confiável revela discrepâncias entre intenção e impacto.","Comunicação, decisão, empatia, organização e resiliência podem ser avaliadas."],"content_sections":[{"title":"Janela de Johari aplicada","items":["Aberto: você e os outros reconhecem.","Cego: os outros percebem, mas você não.","Oculto: você sabe, mas não mostra.","Desconhecido: ainda não foi percebido por ninguém."],"variant":"default"},{"title":"Cinco dimensões para observar","items":["Comunicação.","Tomada de decisão.","Empatia.","Organização.","Resiliência."],"variant":"highlight"},{"title":"Exercício","body":"Dê uma nota de 1 a 10 para cada dimensão e peça a três pessoas de confiança que façam o mesmo. Compare as maiores diferenças: elas indicam pontos cegos a investigar.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'c5bacfee-513a-5cf2-b20e-7b6891b61173'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Autoconhecimento como Base da Liderança'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 4
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer comportamentos de liderança que desenvolvem autonomia em vez de criar dependência.","summary":"O material diferencia chefia baseada em tarefas de liderança que desenvolve pessoas. Grandes líderes combinam visão, integridade, comunicação, empatia, decisão, desenvolvimento, adaptabilidade, accountability, reconhecimento e humildade para aprender.","key_points":["Liderança eficaz cria autonomia na equipe.","Coerência entre discurso e prática constrói confiança.","Expectativas claras precisam vir acompanhadas de desenvolvimento.","Reconhecimento e feedback reforçam comportamentos desejados.","Humildade mantém o líder aprendendo com a própria equipe."],"content_sections":[{"title":"10 características apresentadas","items":["Visão clara e inspiradora.","Integridade inabalável.","Comunicação transparente.","Empatia autêntica.","Decisão corajosa.","Desenvolvimento contínuo.","Adaptabilidade situacional.","Accountability firme.","Reconhecimento generoso.","Humildade para aprender."],"variant":"default"},{"title":"Regra do líder VAP","body":"Seja exemplo do comportamento esperado, mas construa processos e competências para que a equipe consiga prosperar mesmo sem sua presença constante.","variant":"highlight"},{"title":"Aplicação","body":"Escolha uma tarefa que hoje depende excessivamente de você. Defina como transformar orientação, critério e acompanhamento em autonomia para outra pessoa.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '4f214a8d-4404-5d13-b054-67c3b563a06c'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Características dos Grandes Líderes de Vendas'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 4
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Selecionar conscientemente o estilo de liderança mais adequado ao contexto, à equipe e ao objetivo.","summary":"O material apresenta seis estilos e reforça que nenhum deles é suficiente para todas as situações. A competência do líder está em diagnosticar o contexto e alternar a abordagem sem perder coerência.","key_points":["Visionário mobiliza em torno de uma direção.","Coaching desenvolve capacidades de longo prazo.","Afiliativo prioriza vínculo e recomposição de relações.","Democrático busca participação e compromisso coletivo.","Marcador de ritmo eleva padrão em situações específicas.","Coercitivo é reservado para crise e necessidade de direção imediata."],"content_sections":[{"title":"Os seis estilos","items":["Visionário: útil em transformação e necessidade de direção.","Coaching: útil para desenvolver pessoas.","Afiliativo: útil para reconstruir confiança e harmonia.","Democrático: útil quando múltiplas perspectivas agregam valor.","Marcador de ritmo: útil com equipe madura e urgência de desempenho.","Coercitivo: útil em crises ou emergências que exigem comando direto."],"variant":"default"},{"title":"Risco da liderança rígida","body":"Usar sempre o mesmo estilo transforma força em limitação. A mesma postura que funciona em uma crise pode sufocar uma equipe que precisa aprender e assumir responsabilidade.","variant":"warning"},{"title":"Diagnóstico","body":"Revise suas últimas dez decisões de liderança. Identifique qual estilo predominou e qual situação teria pedido uma abordagem diferente.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'f323a414-90e9-5d6c-a545-f562fae08ae1'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Estilos de Liderança'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 4
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Tomar decisões sob pressão usando o framework DECIDE+ e práticas de inteligência emocional.","summary":"O DECIDE+ organiza a decisão em seis movimentos: Definir, Explorar, Coletar, Identificar, Decidir e Executar. O material combina essa estrutura com a regra 10/10/10 e com a capacidade de reconhecer emoções antes de reagir.","key_points":["Defina o problema antes de buscar solução.","Separe fatos de opiniões durante a coleta.","Liste alternativas antes de decidir.","Decisão não exige 100% de certeza.","Inteligência emocional cria espaço entre impulso e resposta."],"content_sections":[{"title":"Framework DECIDE+","items":["Definir: esclarecer o problema real.","Explorar: investigar causas, perspectivas e implicações.","Coletar: reunir evidências e feedback relevantes.","Identificar: listar opções possíveis.","Decidir: escolher a melhor relação risco-retorno.","Executar: agir, monitorar e ajustar com feedback real."],"variant":"default"},{"title":"Regra 10/10/10","body":"Ao enfrentar uma decisão importante, pergunte como ela parecerá em 10 dias, 10 meses e 10 anos. A mudança de horizonte ajuda a separar urgência emocional de importância estratégica.","variant":"highlight"},{"title":"Sob pressão","body":"Nomeie o que está sentindo antes de responder. Respire, identifique o fato e só então escolha a ação. O objetivo não é eliminar emoção, mas impedir que ela decida sozinha.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '2a3d4e96-ae4c-5c9b-9988-0d030202a9d0'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Tomada de Decisão e Inteligência Emocional'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 4
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar o modelo 4P para construir equipes de alta performance com propósito, pessoas, processo e métricas.","summary":"O material apresenta alta performance como resultado de metodologia. O modelo 4P integra propósito, pessoas, processo e performance, acompanhado de onboarding estruturado e cultura de feedback, transparência, celebração e accountability.","key_points":["Propósito dá direção e significado.","Pessoas devem ser escolhidas também por valores, adaptabilidade e potencial.","Processos documentados aumentam replicabilidade.","Performance exige métricas conectadas ao esforço e ao resultado.","Onboarding reduz pressão prematura e acelera aprendizado consistente."],"content_sections":[{"title":"Modelo 4P","items":["Propósito: por que a equipe existe e qual impacto gera.","Pessoas: quem tem valores, potencial e adaptabilidade para o time.","Processo: rituais claros, documentação e tomada de decisão replicável.","Performance: métricas, revisão, celebração e ajustes rápidos."],"variant":"default"},{"title":"Onboarding de 90 dias apresentado","items":["Semanas 1–2: cultura e valores.","Semanas 3–4: processos e clientes.","Mês 2: observação ativa com profissionais experientes.","Mês 3: execução supervisionada com feedback constante."],"variant":"highlight"},{"title":"Cultura de alta performance","body":"Feedback frequente, transparência sobre resultados, celebração de pequenas vitórias e accountability sem culpa criam um ambiente em que a equipe aprende mais rápido.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '0c4f7481-55a5-5962-bce4-6950b37f1f46'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Equipes de Alta Performance'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 4
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Compreender o DISC como leitura de comportamento observável e usar seus sinais para adaptar a comunicação comercial.","summary":"O material apresenta o DISC a partir do trabalho de William Moulton Marston e reforça seu uso prático: observar ritmo, linguagem, postura e forma de decidir, sem tentar diagnosticar personalidade profunda.","key_points":["DISC trabalha com comportamento observável.","Quatro dimensões organizam padrões de interação.","O vendedor pode observar sinais sem aplicar um teste formal.","A adaptação deve melhorar clareza, não rotular pessoas."],"content_sections":[{"title":"Por que o DISC é útil em vendas","body":"O vendedor não precisa adivinhar a personalidade do cliente. Ele observa sinais de comunicação e ajusta ritmo, nível de detalhe e forma de apresentar valor conforme a interação acontece.","variant":"default"},{"title":"Quatro princípios de aplicação","items":["Observe comportamento, não faça julgamento de caráter.","Procure padrões de fala, postura e decisão.","Use o perfil como hipótese de comunicação, não como rótulo definitivo.","Ajuste continuamente conforme surgirem novos sinais."],"variant":"highlight"},{"title":"Exercício","body":"Em três conversas de hoje, anote apenas sinais observáveis: velocidade de fala, nível de detalhe, foco em pessoas ou resultados e tempo para decidir. Só depois formule uma hipótese de perfil.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'd007d897-23be-593b-8938-5facaa48442b'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Fundamentos DISC: a Origem da Metodologia'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 5
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer sinais dos perfis D, I, S e C e adaptar ritmo, linguagem e evidências à preferência de cada um.","summary":"Os quatro perfis são apresentados por características, modo de falar, postura, valores, medos e recomendações de abordagem. A adaptação não muda o conteúdo verdadeiro da oferta; muda a forma de comunicar para facilitar compreensão.","key_points":["D tende a valorizar velocidade, resultado e controle.","I tende a valorizar relacionamento, entusiasmo e reconhecimento.","S tende a valorizar estabilidade, harmonia e previsibilidade.","C tende a valorizar precisão, evidência e qualidade."],"content_sections":[{"title":"Perfil D – Dominante","items":["Seja direto e objetivo.","Mostre resultado, números e retorno.","Evite rodeios e excesso de detalhes irrelevantes."],"variant":"default"},{"title":"Perfil I – Influente","items":["Construa conexão e energia positiva.","Use histórias e impacto humano.","Evite comunicação fria e excessivamente técnica."],"variant":"default"},{"title":"Perfil S – Estável","items":["Dê tempo para processar.","Reforce segurança, previsibilidade e impacto nas pessoas.","Evite pressão e urgência artificial."],"variant":"default"},{"title":"Perfil C – Consciente","items":["Organize dados e documentação.","Seja preciso e responda com evidências.","Evite generalizações e pressão por decisão rápida."],"variant":"default"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '960fada6-2a28-53d9-a95a-c360af6f54bd'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Perfis D, I, S e C'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 5
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Usar as competências comportamentais como mapa de forças e pontos de desenvolvimento, sem tratar perfil como limitação.","summary":"O material amplia os quatro estilos para combinações comportamentais e mostra que cada uma traz forças e riscos. O objetivo é aumentar autoconhecimento e desenvolver comportamentos complementares quando o contexto exigir.","key_points":["Toda força pode criar um ponto cego quando usada em excesso.","Perfis dominantes podem precisar desenvolver paciência e escuta.","Perfis influentes podem precisar fortalecer atenção a detalhes.","Perfis estáveis podem precisar praticar decisão sob pressão.","Perfis conscientes podem precisar agir com informação incompleta."],"content_sections":[{"title":"Força e desafio andam juntos","items":["Dominância pode acelerar decisões, mas gerar impaciência.","Influência pode criar conexão, mas reduzir atenção técnica.","Estabilidade pode gerar confiança, mas aumentar resistência à mudança.","Conformidade pode elevar precisão, mas levar à paralisia por análise."],"variant":"default"},{"title":"Objetivo do desenvolvimento","body":"Não é apagar seu perfil natural. É ampliar repertório para que você consiga usar comportamentos complementares quando a situação comercial exigir.","variant":"highlight"},{"title":"Exercício","body":"Escolha uma força que costuma usar em excesso e escreva qual competência complementar ajudaria a equilibrá-la em situações de venda.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'c6d3b804-bb2c-57ff-9b4c-6a23fe5f5185'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'As 16 Competências Comportamentais'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 5
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Transformar o diagnóstico de perfil em um plano de desenvolvimento de 30 dias com prática, feedback e adaptação.","summary":"O material propõe ampliar pontos fortes, desenvolver pontos cegos e praticar em situações-chave. Cada perfil recebe sugestões de treino que estimulam comportamentos menos naturais, mas úteis para aumentar flexibilidade.","key_points":["Desenvolvimento comportamental precisa de prática observável.","Feedback específico acelera percepção de pontos cegos.","Planos curtos facilitam foco e acompanhamento.","Flexibilidade não significa mudar a essência; significa aumentar opções de resposta."],"content_sections":[{"title":"Três frentes do plano","items":["Ampliar 2–3 forças principais.","Escolher 1–2 pontos cegos para desenvolver.","Definir situações reais em que praticará o novo comportamento."],"variant":"default"},{"title":"Exemplos do material","items":["D: praticar escuta ativa e paciência.","I: preparar dados e perguntas analíticas.","S: treinar decisões mais rápidas e situações de urgência.","C: praticar ação com informação suficiente, sem esperar perfeição."],"variant":"highlight"},{"title":"Seu plano de 30 dias","body":"Escolha um comportamento-alvo, uma situação diária de prática e uma pessoa que possa fornecer feedback semanal. Defina como medirá evolução.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '53fe8616-3069-51af-9afb-5529c7d2bcee'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Planos de Desenvolvimento por Perfil'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 5
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar o Método Espelho Comportamental para adaptar comunicação ao perfil percebido sem perder autenticidade.","summary":"O método orienta observar nos primeiros minutos, fazer perguntas de diagnóstico, formar uma hipótese de perfil e então ajustar ritmo, linguagem e conteúdo. O objetivo é criar sintonia respeitando a forma como o cliente processa informações.","key_points":["Primeiro observe; depois pergunte; só então adapte.","Ritmo, linguagem e nível de detalhe mudam conforme o perfil.","Perfis combinados exigem equilíbrio entre dois estilos.","Espelhamento é adaptação consciente, não imitação artificial."],"content_sections":[{"title":"Primeiros cinco minutos","items":["0–2 min: observe postura, tom, velocidade e palavras.","2–4 min: faça perguntas sobre prioridade e forma de decidir.","Minuto 5: forme uma hipótese e ajuste a comunicação, mantendo abertura para corrigir."],"variant":"default"},{"title":"Adaptação rápida","items":["D: rápido, objetivo, números.","I: energia, relacionamento e histórias.","S: calma, segurança e tempo.","C: precisão, dados e documentação."],"variant":"highlight"},{"title":"Prática","body":"Escolha três clientes recentes, estime o perfil de cada um com base em sinais observáveis e escreva como você mudaria abertura, apresentação de benefícios e fechamento para cada caso.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '82ab47dd-22df-5b5e-8ae2-e274dc719092'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Método Espelho Comportamental'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 5
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Compreender a proposta de neurovendas e diferenciar aplicação ética de tentativa de manipulação.","summary":"O material define neurovendas como uso de princípios de neurociência para entender como informações, emoções e hábitos influenciam decisões. A aplicação ética busca reduzir incerteza e facilitar uma decisão genuína, sem enganar ou forçar o cliente.","key_points":["A decisão envolve processos conscientes e automáticos.","Emoção e memória influenciam a percepção de valor e risco.","Ética exige preservar autonomia e interesse do cliente.","Conhecimento sobre decisão deve melhorar contexto e clareza, não manipular."],"content_sections":[{"title":"Neurovendas x manipulação","body":"Neurovendas usa conhecimento sobre atenção, memória, emoção e risco para tornar a comunicação mais clara e relevante. Manipulação esconde informação ou pressiona o cliente contra seus próprios interesses.","variant":"warning"},{"title":"Três níveis de processamento apresentados","items":["Consciente: análise, lógica e justificativa.","Pré-consciente: associações, memórias e padrões reconhecidos.","Inconsciente: hábitos, emoções e respostas automáticas."],"variant":"default"},{"title":"Aplicação ética","body":"Revise sua abordagem e pergunte: estou ajudando o cliente a compreender e decidir ou tentando criar pressão que ele não escolheria se tivesse todas as informações?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '0ecc9e72-fa09-58a5-a851-a981cbd653cc'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'O que É Neurovendas'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 6
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Relacionar os três sistemas cerebrais apresentados no material às necessidades de segurança, emoção e justificativa racional.","summary":"O modelo didático da fonte divide a decisão entre cérebro reptiliano, sistema límbico e neocórtex. Na venda, isso é usado para lembrar que segurança, vínculo emocional e argumentos racionais precisam estar presentes de forma coerente.","key_points":["Segurança percebida reduz resistência.","Emoções e memórias influenciam desejo e confiança.","Dados e lógica ajudam a justificar a decisão.","Uma boa venda não depende de apenas um tipo de argumento."],"content_sections":[{"title":"Cérebro reptiliano","body":"No modelo apresentado, responde especialmente a segurança, previsibilidade, risco e familiaridade. Mensagens claras, garantias verdadeiras e processos transparentes ajudam a reduzir ameaça percebida.","variant":"default"},{"title":"Sistema límbico","body":"Relaciona-se a emoções, memórias e vínculo. Histórias, identificação e visão de transformação ajudam o cliente a imaginar o benefício.","variant":"default"},{"title":"Neocórtex","body":"Organiza análise e justificativa. Dados, comparações, custos e benefícios permitem validar racionalmente uma decisão.","variant":"default"},{"title":"Aplicação","body":"Pegue seu pitch atual e identifique: onde você transmite segurança? Onde cria conexão? Onde oferece dados suficientes para uma decisão racional?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '7f869447-c32b-5ac6-ab58-fb1ac5d510a0'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Os 3 Cérebros no Processo de Compra'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 6
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Entender como estados emocionais descritos no material podem influenciar confiança, antecipação, status e estresse durante a venda.","summary":"A fonte usa dopamina, oxitocina, serotonina e cortisol como mapa didático para pensar em expectativa de recompensa, confiança, reconhecimento e estresse. A aplicação comercial recomendada é criar contexto de clareza e confiança, não tentar ''controlar'' a química do cliente.","key_points":["Antecipação de benefício ajuda o cliente a visualizar resultado.","Conexão genuína fortalece confiança.","Autoridade precisa ser sustentada por expertise real.","Estresse elevado pode bloquear a decisão; clareza e transparência ajudam a reduzi-lo."],"content_sections":[{"title":"Quatro estados descritos","items":["Dopamina: associada à antecipação de recompensa.","Oxitocina: associada a conexão e confiança.","Serotonina: relacionada no material a status e reconhecimento.","Cortisol: relacionado a estresse, medo e incerteza."],"variant":"default"},{"title":"O papel do vendedor","body":"Crie segurança por meio de processo transparente, benefícios concretos, escuta e evidências. Evite usar linguagem científica como promessa de controle sobre a decisão do cliente.","variant":"warning"},{"title":"Exercício","body":"Revise uma etapa em que clientes costumam ficar tensos ou indecisos. Liste quais incertezas podem ser removidas com informação, garantia verdadeira ou melhor explicação do processo.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'ebb3f44b-e355-53bc-a294-87fc6561e1d9'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Neurociência na Tomada de Decisão'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 6
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar o modelo AIDA de forma conectada ao processo de atenção, interesse, desejo e ação apresentado no módulo.","summary":"O material reinterpreta AIDA pela lente de neurovendas: primeiro capturar atenção com relevância, depois construir interesse com conexão, desenvolver desejo com benefício e confiança e, por fim, facilitar a ação com clareza e justificativa.","key_points":["Atenção exige relevância imediata.","Interesse cresce quando o cliente se reconhece no problema e na história.","Desejo depende de benefício percebido e confiança.","Ação é facilitada quando preço, prazo e próximo passo estão claros."],"content_sections":[{"title":"A – Atenção","body":"Comece pelo que é relevante para o problema do cliente. Evite aberturas genéricas e excesso de contexto antes de mostrar por que a conversa importa.","variant":"default"},{"title":"I e D – Interesse e Desejo","body":"Use perguntas, histórias e benefícios para ajudar o cliente a visualizar a transformação. Reforce prova social e garantias reais para reduzir incerteza.","variant":"default"},{"title":"A – Ação","body":"Simplifique a decisão: deixe claros investimento, prazo, condições e próximo passo. A ação não deve depender de confusão ou pressão.","variant":"highlight"},{"title":"Prática","body":"Reescreva uma abordagem sua em quatro blocos AIDA e verifique se cada etapa tem uma função distinta.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '6a9bb606-b693-5b94-a826-982a0b1bcfbf'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Modelo AIDA Neurológico'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 6
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer os 12 gatilhos apresentados e aplicá-los apenas quando forem verdadeiros e relevantes.","summary":"O material apresenta reciprocidade, compromisso, prova social, autoridade, afeição, escassez, urgência, novidade, pertencimento, antecipação, simplicidade e storytelling. O princípio comum é uso ético: o gatilho deve apoiar clareza e decisão, nunca fabricar uma realidade falsa.","key_points":["Prova social e autoridade precisam ser verificáveis.","Escassez e urgência só podem ser usadas quando existirem de fato.","Simplicidade melhora compreensão sem omitir informação importante.","Storytelling deve ilustrar possibilidades reais.","Reciprocidade e afeição precisam ser genuínas."],"content_sections":[{"title":"Os 12 gatilhos","items":["Reciprocidade.","Compromisso.","Prova social.","Autoridade.","Afeição.","Escassez real.","Urgência real.","Novidade.","Pertencimento.","Antecipação.","Simplicidade.","Storytelling."],"variant":"default"},{"title":"Regra ética inegociável","body":"Nunca invente escassez, prazo, depoimento, credencial ou resultado. Um gatilho falso pode gerar conversão de curto prazo, mas destrói confiança e reputação.","variant":"warning"},{"title":"Exercício","body":"Escolha três gatilhos que realmente existam na sua oferta. Para cada um, escreva a evidência que prova que é verdadeiro e como será comunicado sem exagero.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '6ee2d4e2-4849-560c-86c0-52db0290eb4a'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Os 12 Gatilhos Mentais em Vendas'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 6
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Compreender copywriting como comunicação orientada a uma ação comercial específica.","summary":"O material diferencia copy de conteúdo puramente informativo. Copywriting combina empatia, estratégia e clareza para capturar atenção, criar conexão e orientar um próximo passo, seja agendar, responder, baixar um material ou avançar na compra.","key_points":["Copy tem uma ação desejada claramente definida.","A mensagem precisa falar com um problema ou desejo real.","Conexão é tão importante quanto atenção.","CTA deixa explícito o próximo passo."],"content_sections":[{"title":"Copy x conteúdo","body":"Conteúdo pode ensinar e construir autoridade sem pedir uma ação imediata. Copy é escrito ou falado para conduzir uma ação específica dentro da jornada comercial.","variant":"default"},{"title":"Três objetivos de qualquer copy","items":["Atenção: interromper o ruído e ganhar foco.","Conexão: mostrar que você entende o contexto do cliente.","Ação: deixar claro o que deve acontecer em seguida."],"variant":"highlight"},{"title":"Aplicação","body":"Pegue sua última mensagem de prospecção e responda: qual ação eu queria gerar? O cliente entenderia isso sem precisar adivinhar?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '27bdfd9e-c811-5a6d-a0dc-97f9aae54a3c'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'O Principal Objetivo do Copywriting'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 7
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Construir mensagens coerentes com a voz da marca e com a linguagem real do cliente ideal.","summary":"A estratégia de copy do VAP parte de voz, ICP, especificidade e pesquisa de linguagem. A mensagem fica mais forte quando usa palavras do próprio mercado, exemplos concretos e um tom consistente entre canais.","key_points":["Voz consistente aumenta reconhecimento.","ICP define dores, ambições e vocabulário prioritários.","Especificidade gera mais credibilidade que generalidades.","Pesquisa de linguagem aproxima a mensagem da forma como o cliente pensa e fala."],"content_sections":[{"title":"Quatro fundamentos","items":["Voz e personalidade: defina tom, nível de formalidade e postura.","ICP: escreva para um cliente ideal concreto.","Especificidade: use números, situações e exemplos verdadeiros.","Pesquisa de linguagem: colete palavras de conversas, depoimentos e reviews."],"variant":"default"},{"title":"Evite mensagem genérica","body":"Troque frases como ''solução completa para sua empresa'' por uma promessa específica ligada ao problema que aquele perfil realmente reconhece.","variant":"highlight"},{"title":"Exercício","body":"Separe cinco frases reais de clientes sobre dores ou objetivos. Reescreva sua mensagem usando essas palavras sem distorcer o sentido original.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '2515b682-9ff5-5c4e-8fcf-b4e7abab3203'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Estratégia de Copywriting VAP'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 7
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Escolher e adaptar fórmulas de copywriting conforme o objetivo e o estágio da conversa.","summary":"O material apresenta AIDA, PAS, BAB e 4Ps como estruturas para organizar raciocínio, não como textos para copiar mecanicamente. Cada fórmula funciona melhor em determinados contextos e deve ser adaptada ao cliente.","key_points":["AIDA organiza atenção, interesse, desejo e ação.","PAS trabalha problema, agitação e solução.","BAB contrasta antes, depois e a ponte para a transformação.","4Ps combina promessa, prova, proposta e impulso para ação."],"content_sections":[{"title":"AIDA","items":["Atenção: headline ou abertura relevante.","Interesse: desenvolva curiosidade e contexto.","Desejo: mostre benefício e transformação.","Ação: CTA claro."],"variant":"default"},{"title":"PAS, BAB e 4Ps","items":["PAS: Problema → Agitação → Solução.","BAB: Before → After → Bridge.","4Ps: Promessa → Prova → Proposta → Push."],"variant":"default"},{"title":"Quando usar","body":"AIDA funciona bem em mensagens e anúncios; PAS em vendas consultivas; BAB em ofertas de transformação; 4Ps em follow-ups e ofertas com prova forte.","variant":"highlight"},{"title":"Prática","body":"Escolha uma oferta e escreva uma versão curta usando AIDA e outra usando PAS. Compare qual estrutura combina melhor com a maturidade do cliente.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '506a2488-a392-5c65-b87f-31fc9faf7058'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Fórmulas de Copywriting'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 7
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Adaptar copy a redes sociais e anúncios com abertura forte, benefício claro, prova e CTA.","summary":"O material destaca que os primeiros segundos são decisivos. Uma peça comercial eficaz combina hook, contexto, benefício, prova e ação, respeitando linguagem e formato de cada canal.","key_points":["Headline precisa ser específica e relevante.","Benefícios emocionais tendem a ser mais úteis do que lista de features.","Prova social aumenta credibilidade quando é verdadeira.","CTA vago reduz conversão.","A mesma mensagem precisa ser adaptada a cada canal."],"content_sections":[{"title":"Estrutura de post de vendas","items":["Hook que interrompe o scroll.","Contexto curto.","Benefício específico.","Prova social ou autoridade.","CTA claro."],"variant":"default"},{"title":"Erros comuns","items":["Copiar o mesmo texto em todos os canais.","Falar apenas de características técnicas.","Não apresentar prova.","Usar CTA vago ou inexistente.","Tentar vender agressivamente para quem ainda está no topo do funil."],"variant":"warning"},{"title":"Exercício","body":"Pegue um anúncio ou post seu. Reescreva a primeira linha, troque uma feature por benefício e deixe o CTA explícito em uma única frase.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '0ed2797e-4500-51d9-9aec-eaf666876075'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Copy para Redes Sociais e Anúncios'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 7
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar copywriting consultivo a vendas de maior valor, priorizando ROI, risco, prova e construção progressiva de confiança.","summary":"Vendas de alto valor pedem mensagens mais profundas e ciclos mais longos. O material orienta usar dados específicos, casos detalhados, mitigação de risco e uma sequência de contatos em que cada mensagem adiciona valor.","key_points":["Ticket alto exige prova mais robusta.","ROI ajuda diferentes decisores a justificar investimento.","Cada mensagem deve avançar confiança, não apenas repetir a oferta.","Urgência precisa ser legítima.","Conteúdo adicional pode reabrir conversas sem pressionar."],"content_sections":[{"title":"Sequência sugerida","items":["E-mail 1 – Abertura: pesquisa personalizada, conexão e valor.","E-mail 2 – Prova: case relevante e ROI.","E-mail 3 – Urgência legítima: consequência real de não agir.","E-mail 4 – Valor adicional: insight novo para reabrir diálogo."],"variant":"default"},{"title":"Regra de confiança progressiva","body":"Em decisões maiores, o cliente raramente avança por uma única mensagem. Cada contato precisa reduzir uma incerteza ou acrescentar evidência relevante.","variant":"highlight"},{"title":"Aplicação","body":"Revise sua cadência de follow-up e marque quais mensagens realmente trazem informação nova. Reescreva as que apenas dizem ''passando para saber se viu''.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '6388f495-2c6f-5189-b628-b41aae3d97b6'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Copywriting para Vendas de Alto Valor'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 7
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Definir um ICP e usar critérios de qualificação para concentrar a prospecção em oportunidades com maior aderência.","summary":"A prospecção eficiente começa pelo Perfil do Cliente Ideal. O material combina fatores demográficos, comportamentais e psicográficos com frameworks como BANT e MEDDIC e recomenda cadências multicanal.","key_points":["ICP reduz desperdício de tempo com prospects pouco aderentes.","BANT considera orçamento, autoridade, necessidade e prazo.","MEDDIC amplia análise de métricas, decisores, critérios, processo, dor e campeão interno.","Cadência exige múltiplos contatos e canais."],"content_sections":[{"title":"Construindo o ICP","items":["Demografia: setor, porte e localização.","Comportamento: histórico de compra e tecnologia usada.","Psicografia: valores, cultura e objetivos estratégicos."],"variant":"default"},{"title":"Critérios de qualificação","items":["BANT: Budget, Authority, Need, Timeline.","MEDDIC: Metrics, Economic Buyer, Decision Criteria, Decision Process, Identify Pain, Champion."],"variant":"highlight"},{"title":"Aplicação","body":"Escolha dez leads do pipeline e compare com seu ICP. Marque quais realmente atendem aos critérios e quais estão consumindo esforço sem evidência de aderência.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'c4ed3f6e-1d9e-55e9-9ac2-ce71a1a6c904'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Prospecção Eficiente'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 8
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Conduzir os primeiros minutos da abordagem com rapport, credencial, agenda e contrato de conversa.","summary":"O material reforça a importância da primeira impressão e da comunicação não verbal, além de apresentar uma abertura em quatro etapas. O objetivo é criar conexão e clareza antes de entrar na apresentação comercial.","key_points":["Rapport começa por interesse genuíno, não por frase decorada.","Credencial deve ser breve e relevante.","Agenda explica o propósito da conversa.","Contrato alinha tempo e próximos passos.","Sinais de receptividade ou resistência ajudam a calibrar ritmo."],"content_sections":[{"title":"Fórmula de abertura em 4 etapas","items":["Quebra-gelo: conexão relevante e específica.","Credencial: por que você pode ajudar naquele contexto.","Agenda: o que será discutido e qual valor a conversa pode gerar.","Contrato: alinhar tempo disponível e próximo passo esperado."],"variant":"default"},{"title":"Observe a resposta","body":"Postura aberta, perguntas e participação podem indicar receptividade; respostas curtas, distração e fechamento corporal sugerem que você precisa ajustar o ritmo ou voltar à conexão.","variant":"highlight"},{"title":"Prática","body":"Escreva uma abertura de 60 segundos usando as quatro etapas e grave em áudio. Verifique se soa natural e se fala mais do contexto do cliente do que de você.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '5c5ac5ea-1278-5e81-97ee-0f7809f162cd'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Abordagem – Rapport e Comunicação'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 8
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar SPIN Selling para descobrir contexto, problema, impacto e necessidade de solução antes de apresentar.","summary":"O SPIN organiza perguntas em Situação, Problema, Implicação e Need-Payoff. A lógica é fazer o cliente pensar sobre o próprio contexto e verbalizar o valor da mudança, enquanto o vendedor prioriza escuta.","key_points":["Situação esclarece fatos relevantes.","Problema identifica dificuldade concreta.","Implicação explora consequências de não resolver.","Need-Payoff faz o cliente verbalizar o benefício da solução.","A regra 70/30 reforça mais escuta e menos exposição."],"content_sections":[{"title":"Sequência SPIN","items":["Situação: como funciona hoje?","Problema: onde existe dificuldade, desperdício ou frustração?","Implicação: o que acontece se isso continuar?","Need-Payoff: que diferença faria resolver esse ponto?"],"variant":"default"},{"title":"Regra 70/30","body":"O material recomenda que o vendedor ouça a maior parte do tempo. A qualidade da pergunta e da escuta define a qualidade da argumentação que virá depois.","variant":"highlight"},{"title":"Exercício","body":"Crie cinco perguntas de cada categoria para seu produto. Depois elimine as que podem ser respondidas facilmente com pesquisa prévia e mantenha as que realmente ajudam o cliente a refletir.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '38dd8e28-c807-58da-a816-1f54cabf0e63'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'SPIN Selling'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 8
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Converter características em benefícios relevantes e negociar preservando valor por meio de CAB, ROI, ancoragem e BATNA.","summary":"A metodologia CAB transforma features em significado para o cliente. O material também inclui cálculo de ROI, ancoragem e BATNA para apoiar negociações sem depender automaticamente de desconto.","key_points":["Característica descreve o recurso.","Vantagem mostra por que ele se diferencia.","Benefício conecta a solução à dor ou resultado desejado.","ROI traduz valor em impacto financeiro.","BATNA aumenta clareza sobre limites e alternativas."],"content_sections":[{"title":"CAB","items":["Característica: o que a solução possui ou faz.","Vantagem: como isso se diferencia de alternativas.","Benefício: qual resultado específico isso gera para aquele cliente."],"variant":"default"},{"title":"Negociação orientada a valor","items":["Use dados do cliente para calcular ROI.","Conheça sua BATNA antes de negociar.","Explore também a alternativa do cliente.","Antes de dar desconto, considere prazo, escopo, serviços ou condições que preservem valor."],"variant":"highlight"},{"title":"Exercício","body":"Escolha três características do seu produto e escreva CAB completo para cada uma. Se o benefício servir para qualquer cliente, ainda está genérico demais.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'd60d7991-ebcb-514d-98e2-f0440ac542d1'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Argumentação CAB e Negociação'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 8
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer sinais de compra, usar técnicas de fechamento adequadas e estruturar o pós-venda para fidelização.","summary":"O fechamento deve acontecer quando o cliente já construiu valor e demonstra prontidão. O material apresenta técnicas como alternativa, resumo, teste e silêncio, e reforça que o relacionamento continua após a venda por meio de onboarding e acompanhamento.","key_points":["Sinais de compra indicam prontidão para discutir decisão.","Fechamento deve facilitar, não forçar.","Pós-venda confirma expectativas e reduz arrependimento.","Fidelização pode evoluir de satisfação para recorrência e promoção."],"content_sections":[{"title":"Técnicas de fechamento apresentadas","items":["Alternativa: escolher entre opções válidas.","Urgência: apenas quando a condição for real.","Resumo: revisar benefícios acordados.","Teste: verificar se uma questão resolvida libera o avanço.","Silêncio: perguntar e permitir que o cliente responda.","Boomerang: perguntar o que falta para decidir."],"variant":"default"},{"title":"Pós-venda estruturado","items":["24 horas: boas-vindas e próximo passo.","1ª semana: onboarding e validação de expectativas.","1º mês: check-in e ajustes.","90 dias: avaliar resultado, expansão e possibilidade de depoimento."],"variant":"highlight"},{"title":"Aplicação","body":"Mapeie os três sinais de compra mais comuns no seu processo e escolha a técnica de fechamento mais natural para cada um.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '5c62b0ea-6c21-560e-8ca8-0b3ef0444ac4'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Fechamento e Pós-Venda'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 8
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Interpretar objeção como informação a ser investigada e diferenciar objeção real, de processo e de fuga.","summary":"O material reforça que objeção não é automaticamente rejeição. Ela pode revelar uma preocupação legítima, uma etapa normal da decisão ou uma tentativa de encerrar a conversa. Responder bem começa por diagnosticar o tipo antes de argumentar.","key_points":["Objeção real precisa ser resolvida para a venda avançar.","Objeção de processo exige facilitar a jornada de decisão.","Objeção de fuga pede abordagem leve e manutenção do relacionamento.","Responder antes de compreender aumenta resistência."],"content_sections":[{"title":"Três tipos apresentados","items":["Real: existe um obstáculo concreto.","De processo: a hesitação faz parte do caminho de decisão.","De fuga: a frase busca encerrar ou adiar sem revelar a causa real."],"variant":"default"},{"title":"Erro mais comum","body":"Rebater imediatamente transforma a conversa em disputa. Escutar e aprofundar primeiro gera informação para responder à causa, não apenas à frase superficial.","variant":"warning"},{"title":"Pergunta de prática","body":"Na próxima objeção, antes de responder, pergunte algo que ajude a distinguir: é falta de informação, etapa do processo ou ausência real de interesse?","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '6e68a758-fb30-53e5-a883-c96b59d3206f'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'O que São Objeções e Por que Ocorrem'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer objeções recorrentes e interpretar o significado provável por trás de cada frase.","summary":"O material trabalha objeções como preço, necessidade de pensar, timing, consulta a outro decisor, solução já existente e falta de confiança na empresa. Para cada uma, a resposta profissional começa por validar e investigar antes de apresentar evidência.","key_points":["''Está caro'' pode indicar valor insuficiente ou comparação inadequada.","''Preciso pensar'' pode esconder uma dúvida não verbalizada.","''Não é o momento'' pode significar baixa urgência.","''Preciso consultar'' exige estruturar o próximo passo com os decisores.","''Já tenho solução'' pede diferenciação sem atacar o fornecedor atual.","''Não conheço sua empresa'' é principalmente uma questão de risco e credibilidade."],"content_sections":[{"title":"Seis famílias de objeção","items":["Preço.","Reflexão: ''preciso pensar''.","Timing: ''não é o momento''.","Autoridade: ''preciso consultar''.","Concorrência ou solução atual.","Confiança e credibilidade."],"variant":"default"},{"title":"Responda à causa, não à frase","body":"A mesma frase pode esconder motivos diferentes. Em vez de decorar uma resposta, descubra qual risco, dúvida ou prioridade está por trás daquela objeção.","variant":"highlight"},{"title":"Exercício","body":"Escolha as três objeções que mais aparecem no seu dia a dia e escreva duas perguntas de aprofundamento para cada uma antes de pensar na resposta.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '78d7d4da-1900-5b62-b0e3-49b41518b94a'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'As 6 Objeções Universais'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Aplicar a primeira etapa do CALMA: compreender completamente a objeção antes de responder.","summary":"O CALMA estrutura o tratamento de objeções em Compreender, Acolher, Levantar, Mostrar e Avançar. A primeira etapa exige escuta ativa, observação e disciplina para não construir a resposta enquanto o cliente ainda está falando.","key_points":["Deixe o cliente terminar sem interromper.","Observe palavras-chave e sinais não verbais.","Não assuma a causa da objeção.","Use uma pergunta específica para preparar o aprofundamento."],"content_sections":[{"title":"CALMA em cinco movimentos","items":["C – Compreender.","A – Acolher.","L – Levantar.","M – Mostrar.","A – Avançar."],"variant":"highlight"},{"title":"C – Compreender","body":"Escute a objeção até o fim. Procure distinguir o que foi dito, o que parece preocupar mais e que informação ainda falta para entender a raiz.","variant":"default"},{"title":"Prática","body":"Treine responder à primeira objeção apenas com uma frase de confirmação e uma pergunta de aprofundamento. Proíba-se de defender a oferta antes de entender.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'f3c67e45-0798-5641-aeac-273bdfc97b15'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Metodologia CALMA: C – Compreender'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Validar a preocupação do cliente sem abandonar sua posição e usar perguntas específicas para revelar a raiz da objeção.","summary":"Acolher não significa concordar que sua solução está errada; significa reconhecer que a preocupação faz sentido no contexto do cliente. Levantar transforma a objeção genérica em diagnóstico por meio de uma pergunta ligada ao que foi dito.","key_points":["Validação reduz sensação de confronto.","Acolher a preocupação é diferente de aceitar a conclusão.","Perguntas genéricas produzem respostas genéricas.","O aprofundamento deve separar causas possíveis."],"content_sections":[{"title":"A – Acolher","body":"Demonstre que entendeu a preocupação. Exemplo de lógica: ''faz sentido querer clareza antes de comprometer o orçamento''. Isso valida a necessidade de segurança sem admitir que o preço é inadequado.","variant":"default"},{"title":"L – Levantar","body":"Faça uma pergunta binária ou específica que ajude a localizar a causa: orçamento aprovado, percepção de retorno, prazo, confiança, autoridade ou outra barreira.","variant":"highlight"},{"title":"Exercício","body":"Transforme três respostas defensivas suas em validação + pergunta. O objetivo é sair da discussão e voltar ao diagnóstico.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '01212daa-542c-51c4-97c9-6086334e5bf7'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Metodologia CALMA: A – Acolher e L – Levantar'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Apresentar uma resposta sob medida e conduzir a conversa para um próximo passo concreto.","summary":"Depois de compreender, acolher e levantar a causa, o vendedor passa a Mostrar uma solução ligada exatamente à dor revelada e a Avançar para uma ação clara. Respostas genéricas enfraquecem a credibilidade; próximo passo vago interrompe a cadência.","key_points":["Mostrar exige conectar resposta à causa identificada.","A evidência deve ser relevante para aquela preocupação específica.","Avançar significa propor uma ação pequena, clara e mensurável.","Perguntas abertas demais podem devolver a conversa à hesitação."],"content_sections":[{"title":"M – Mostrar","body":"Se a raiz é ROI, use evidência de retorno. Se é prazo, mostre processo de implementação. Se é risco, apresente garantia, credencial ou caso relevante. A resposta deve parecer consequência lógica do diagnóstico.","variant":"default"},{"title":"A – Avançar","body":"Proponha um próximo passo objetivo: enviar proposta revisada, envolver outro decisor, agendar demonstração ou validar uma condição. Evite encerrar com ''o que você acha?'' sem direção.","variant":"highlight"},{"title":"Prática","body":"Pegue uma objeção recorrente e escreva três versões do ''Mostrar'', cada uma para uma causa diferente. Depois defina o próximo passo correspondente.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '43d8d34c-4482-5767-9f38-0cc510cc2fb8'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Metodologia CALMA: M – Mostrar e A – Avançar'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Usar reenquadramento e comparação de valor para mudar a perspectiva da objeção sem negar a preocupação do cliente.","summary":"O reenquadramento apresenta a mesma situação por uma lente mais produtiva. A comparação de valor quantifica ganhos, economia ou custo da inação para avaliar o investimento com contexto, e não apenas pelo preço nominal.","key_points":["Reenquadrar não é invalidar a objeção.","A nova perspectiva deve ser coerente com os fatos.","Comparação de valor usa dados do cenário do cliente.","Antes e depois ajudam a tornar impacto mensurável."],"content_sections":[{"title":"Reenquadramento","body":"Valide o ponto e ofereça outra forma de interpretar. Por exemplo, um investimento inicial pode ser comparado ao custo de manter ineficiência, desde que os números usados sejam verdadeiros.","variant":"default"},{"title":"Comparação de valor","body":"Colete tempo, custo, erros ou receita do cenário atual e estime o impacto possível da solução. Deixe claras as premissas para que o cliente possa questionar e validar a conta.","variant":"highlight"},{"title":"Exercício","body":"Escolha uma objeção de preço e construa uma comparação usando dados reais do cliente. Se precisar inventar número para a conta funcionar, não use a comparação.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '2f6882c7-994f-5a13-b920-ce38ca9a75d5'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Técnicas Práticas: Reenquadramento e Comparação de Valor'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 6
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Tratar objeções de timing criando urgência genuína por meio de prazo real, escassez real e custo de oportunidade.","summary":"Quando o cliente diz ''não agora'', o material orienta investigar se existe falta de prioridade, dúvida ou custo percebido baixo. A urgência deve vir da realidade: prazo, capacidade limitada verdadeira ou perda concreta provocada pelo adiamento.","key_points":["Adiar não é neutro quando existe custo de oportunidade.","Escassez só deve ser usada quando a limitação é real.","Prazos precisam estar vinculados a benefício ou consequência concreta.","Urgência falsa destrói confiança."],"content_sections":[{"title":"Três fontes legítimas de urgência","items":["Escassez real de capacidade, vaga ou recurso.","Prazo real ligado a implementação, ciclo ou condição.","Custo de oportunidade mensurável da inação."],"variant":"default"},{"title":"O que evitar","body":"Não invente prazo, número de vagas ou condição que será prorrogada depois. Se a urgência não existe de verdade, volte ao diagnóstico da prioridade em vez de fabricar pressão.","variant":"warning"},{"title":"Pergunta de prática","body":"O que o cliente perde, em termos concretos, ao adiar 30, 60 ou 90 dias? Se não há perda relevante, talvez ainda não seja o momento de fechar.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '9c75272d-2b97-5fa1-83ac-ef081ad07395'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Objeções de Timing: Criando Urgência Sem Pressão'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 7
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Mapear stakeholders, processo de aprovação e critérios de decisão quando a compra envolve múltiplos tomadores de decisão.","summary":"A objeção de autoridade aparece quando o contato precisa consultar outras pessoas ou não controla a decisão final. O material orienta descobrir quem participa, como a aprovação acontece e quais recursos ajudarão o contato a defender a solução internamente.","key_points":["Decisor, influenciador e usuário podem ter prioridades diferentes.","Conhecer o processo de aprovação evita surpresas no final.","O contato pode atuar como campeão interno.","Materiais de ROI, cases e apresentações podem apoiar consenso."],"content_sections":[{"title":"Mapeie o processo","items":["Quem mais precisa participar?","Quais critérios cada área usa?","Existe comitê, aprovação em etapas ou procedimento formal?","Quem é o decisor econômico?","Quem pode defender a solução internamente?"],"variant":"default"},{"title":"Capacite o campeão interno","body":"Entregue ao contato informações que facilitem a conversa interna: resumo do problema, impacto, caso relevante, ROI e materiais adaptados às preocupações de cada stakeholder.","variant":"highlight"},{"title":"Aplicação","body":"Escolha uma oportunidade travada e desenhe um mapa simples com nomes, papéis, interesses e próxima ação para cada stakeholder.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '75d2c3cd-3f0c-5221-9ce5-974e39b12c8c'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Objeções de Autoridade: Navegando Múltiplos Tomadores de Decisão'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 8
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Consolidar o CALMA e praticar respostas a objeções por meio de role-play e checklist.","summary":"A aula final transforma o conteúdo do módulo em habilidade. O material revisa o framework, propõe cenários de preço, timing e múltiplos decisores e fornece um checklist para preparar, ouvir, validar, perguntar, responder, confirmar e avançar.","key_points":["Domínio de objeções exige repetição prática.","Role-play permite errar sem risco comercial.","Checklist ajuda a manter sequência sob pressão.","Toda resposta deve terminar com verificação ou próximo passo."],"content_sections":[{"title":"Checklist de contorno","items":["Prepare objeções prováveis.","Ouça sem interromper.","Valide a perspectiva.","Faça perguntas de aprofundamento.","Conecte a resposta ao objetivo do cliente.","Confirme se a dúvida foi resolvida.","Proponha o próximo passo."],"variant":"default"},{"title":"Cenários de role-play","items":["Preço: concorrente mais barato.","Timing: cliente quer adiar.","Autoridade: vários decisores precisam aprovar."],"variant":"highlight"},{"title":"Prática de consolidação","body":"Faça três rodadas de role-play com observador. Em cada uma, peça feedback apenas sobre a sequência CALMA e sobre a qualidade das perguntas, não sobre ''falar bonito''.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '23183b1d-ce03-5fa7-99a5-994f20331a5a'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Prática e Consolidação: Dominando o Contorno de Objeções'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 9
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 9
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Diferenciar tarefas que podem ser potencializadas por IA das atividades comerciais que continuam exigindo julgamento e relacionamento humano.","summary":"O material apresenta IA como amplificadora de um processo comercial já existente. Ela se destaca em pesquisa, personalização, automação e análise, enquanto relacionamento, empatia, negociação complexa e leitura contextual continuam dependentes do vendedor.","key_points":["IA acelera pesquisa e organização de informação.","Personalização pode ganhar escala com automação.","Tarefas repetitivas são candidatas naturais à automação.","Relacionamento e negociação exigem responsabilidade humana.","IA sem processo apenas automatiza desorganização."],"content_sections":[{"title":"Quatro áreas de potencial","items":["Pesquisa e inteligência comercial.","Personalização em escala.","Automação de tarefas repetitivas.","Análise de dados e priorização."],"variant":"default"},{"title":"O que não deve ser terceirizado cegamente","items":["Empatia e relacionamento genuíno.","Negociação complexa.","Leitura de sinais emocionais e contexto.","Responsabilidade pela decisão e pela informação enviada ao cliente."],"variant":"warning"},{"title":"Exercício","body":"Liste dez tarefas da sua semana. Marque quais são repetitivas e baseadas em regras e quais exigem relacionamento, julgamento ou responsabilidade comercial. Comece pelas primeiras.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '7240b0d2-7aac-5975-81d1-0ff7c1add1c0'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Como a IA Potencializa suas Vendas'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 10
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Organizar ferramentas de IA por função comercial e escolher um stack compatível com porte, maturidade e orçamento.","summary":"A fonte agrupa ferramentas em CRM inteligente, prospecção, análise de chamadas, geração de conteúdo, automação e atendimento. O ponto não é usar todas, mas escolher as que resolvem os principais gargalos da operação.","key_points":["Stack deve partir do problema, não da novidade.","Ferramentas diferentes atendem etapas diferentes do funil.","Integração entre sistemas reduz retrabalho.","Porte e maturidade influenciam a complexidade necessária."],"content_sections":[{"title":"Categorias apresentadas","items":["CRM com recursos de IA.","Prospecção e pesquisa.","Análise de chamadas e reuniões.","Geração e revisão de conteúdo.","Automação entre sistemas.","Chatbots e atendimento inicial."],"variant":"default"},{"title":"Critério de escolha","body":"Antes de contratar uma ferramenta, defina o gargalo, a métrica que deve melhorar, quem será responsável e como o dado entrará no processo atual.","variant":"highlight"},{"title":"Prática","body":"Escolha uma única categoria prioritária e compare até três ferramentas usando os mesmos critérios: problema resolvido, integração, custo, segurança, curva de aprendizagem e métrica de sucesso.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'f773e896-59e2-5663-a5e3-35806304ca92'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Ferramentas de IA por Categoria'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 10
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Usar IA para aumentar relevância das mensagens sem perder revisão humana e contexto real.","summary":"O material organiza personalização em quatro níveis: segmento, empresa, cargo e indivíduo. A IA pode acelerar pesquisa e gerar variações, mas o vendedor continua responsável por verificar fatos e fazer o ajuste final antes do envio.","key_points":["Segmento adapta a mensagem a indústria, porte ou região.","Empresa incorpora contexto da organização.","Cargo considera responsabilidades e prioridades da função.","Indivíduo usa contexto específico e deve ser revisado com cuidado.","Personalização real depende de informação correta."],"content_sections":[{"title":"Quatro níveis de personalização","items":["Segmento.","Empresa.","Cargo.","Indivíduo."],"variant":"default"},{"title":"Fluxo sugerido","items":["Identifique o prospect e a empresa.","Pesquise contexto público relevante.","Mapeie dores prováveis do cargo sem tratá-las como fatos confirmados.","Gere variações de mensagem.","Revise manualmente, remova suposições e personalize o toque final."],"variant":"highlight"},{"title":"Regra de qualidade","body":"Nunca envie automaticamente uma afirmação sobre o cliente que você não verificou. IA pode sugerir contexto; responsabilidade pelo conteúdo continua sendo sua.","variant":"warning"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '195841c0-c371-50f3-ac10-70813d31051a'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'IA na Personalização'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 10
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Definir onde chatbots e assistentes virtuais agregam eficiência e onde deve ocorrer transferência para atendimento humano.","summary":"O material descreve chatbots para FAQ, qualificação, agendamento e nurturing. A regra central é automatizar tarefas processáveis e transferir para pessoas quando a conversa exige emoção, negociação ou análise complexa.","key_points":["FAQ reduz repetição de perguntas simples.","Qualificação coleta contexto e prioridade.","Agendamento elimina idas e vindas operacionais.","Nurturing mantém contato com leads ainda não prontos.","Transição para humano deve preservar contexto no CRM."],"content_sections":[{"title":"Quatro usos apresentados","items":["FAQ.","Qualificação.","Agendamento.","Nurturing."],"variant":"default"},{"title":"Framework ENGAGE","items":["Explore: pergunte sobre contexto.","Navigate: identifique dor e necessidade.","Guide: indique caminho compatível com a necessidade.","Act: ofereça próximo passo claro."],"variant":"highlight"},{"title":"Quando transferir para humano","body":"Objeções profundas, negociação, decisões sensíveis e relacionamento estratégico pedem atuação humana. O bot deve facilitar o processo, não esconder que é automação.","variant":"warning"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'ca422a7e-58ea-5377-b7b0-f364291044e0'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Chatbots e Assistentes Virtuais'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 10
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Construir um roadmap gradual de adoção de IA, com métricas, testes e expansão baseada em evidência.","summary":"O material propõe adoção em fases: fundação, expansão, otimização e maturidade. O vendedor continua focado em perguntas, escuta e relacionamento, enquanto a IA absorve parte crescente do trabalho operacional.","key_points":["Começar pequeno reduz risco e acelera aprendizado.","Cada ferramenta precisa de uma métrica de sucesso.","Teste com poucos casos antes de expandir.","Automação deve ser revisada com feedback real.","Maturidade significa integrar ferramentas ao processo, não apenas acumular assinaturas."],"content_sections":[{"title":"Roadmap de implementação","items":["30 dias – Fundação: escolha uma ferramenta e defina métricas.","60 dias – Expansão: automatize poucos fluxos prioritários.","90 dias – Otimização: integre ferramentas e relatórios.","180 dias – Maturidade: amplie automação operacional com governança."],"variant":"default"},{"title":"Plano de 30 dias","items":["Escolher a ferramenta.","Configurar conta, usuários e permissões.","Mapear 2–3 workflows.","Treinar a equipe.","Testar com poucos prospects.","Expandir apenas após validar resultado."],"variant":"highlight"},{"title":"Exercício","body":"Liste tarefas automatizáveis e classifique cada uma por impacto e dificuldade. Priorize alto impacto com baixa dificuldade e defina uma métrica para comparar antes e depois.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'b3facd62-f746-5e42-9297-96aa212ab1b8'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Futuro das Vendas e Roadmap de Implementação'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 10
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 5
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Diferenciar persuasão ética de manipulação e aplicar princípios de influência com transparência.","summary":"O material usa seis princípios de Cialdini como base: reciprocidade, compromisso, prova social, autoridade, afeição e escassez. O limite ético é claro: beneficiar ambas as partes, usar evidências verdadeiras e nunca fabricar condição para pressionar.","key_points":["Reciprocidade deve começar por valor genuíno.","Compromisso não autoriza induzir acordos que o cliente não compreendeu.","Prova social e autoridade exigem evidência real.","Afeição deve nascer de conexão autêntica.","Escassez precisa ser verdadeira."],"content_sections":[{"title":"Os seis princípios","items":["Reciprocidade.","Compromisso.","Prova social.","Autoridade.","Afeição.","Escassez genuína."],"variant":"default"},{"title":"Linha ética","body":"Persuasão ajuda o cliente a decidir com clareza. Manipulação depende de omissão, falsidade ou pressão contrária ao interesse dele. Se a técnica exige esconder informação para funcionar, ela não é compatível com o método.","variant":"warning"},{"title":"Exercício","body":"Revise uma oferta atual e identifique quais princípios aparecem. Para cada um, escreva a evidência que demonstra que sua comunicação é verdadeira.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '4ee41919-af82-5b48-9470-f04f170918fb'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Fundamentos da Persuasão Ética'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 11
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 1
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Melhorar presença comercial observando postura, gestos, contato visual e voz, com adaptação ao contexto e ao perfil do interlocutor.","summary":"O material ressalta que comunicação não verbal influencia a percepção de atitudes e emoções e organiza presença persuasiva em quatro pilares. A meta é congruência: corpo, voz e palavras precisam transmitir a mesma mensagem.","key_points":["Postura comunica abertura e confiança.","Gestos devem apoiar, não distrair.","Contato visual precisa ser natural, não agressivo.","Tom, ritmo e volume influenciam a percepção da mensagem.","Adaptação ao perfil DISC ajuda a calibrar energia e nível de formalidade."],"content_sections":[{"title":"Quatro pilares da presença","items":["Postura.","Gestos.","Contato visual.","Voz."],"variant":"default"},{"title":"Congruência","body":"Credibilidade cai quando palavras e comportamento não combinam. A presença persuasiva não significa atuar; significa alinhar forma e conteúdo com segurança e autenticidade.","variant":"highlight"},{"title":"Autoavaliação","body":"Grave uma simulação de venda. Avalie postura, gestos, contato visual e voz em escala de 1 a 5. Escolha apenas duas áreas para trabalhar durante 30 dias.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'c1412f1c-6848-5488-828e-3cdcd68a07c5'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Comunicação Não-Verbal e Presença Persuasiva'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 11
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 2
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Construir histórias comerciais em quatro etapas, mantendo o cliente como protagonista da transformação.","summary":"O storytelling apresentado organiza a narrativa em Contexto, Conflito, Virada e Resolução. A história deve tornar benefícios mais concretos e memoráveis sem inventar casos ou exagerar resultados.","key_points":["Contexto situa personagem e cenário.","Conflito apresenta dor ou aspiração.","Virada mostra a intervenção da solução.","Resolução demonstra o novo estado com evidência.","Histórias reais ganham credibilidade com detalhes verificáveis."],"content_sections":[{"title":"Estrutura em 4 etapas","items":["Contexto: quem, onde e situação inicial.","Conflito: problema, frustração ou objetivo.","Virada: como ocorreu a intervenção.","Resolução: qual resultado e transformação apareceram."],"variant":"default"},{"title":"Três tipos de história","items":["História do cliente.","História do produto ou solução.","História do vendedor e do aprendizado relevante."],"variant":"highlight"},{"title":"Exercício","body":"Construa três histórias reais de até 90 segundos usando a estrutura. Grave em vídeo, elimine jargões e mantenha apenas detalhes que ajudem o cliente a se reconhecer na situação.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = '8182ae96-312a-5026-8e8e-6e6ba083e9c7'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Storytelling Persuasivo'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 11
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 3
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );
update public.training_library_lessons
set metadata = metadata || '{"learning_objective":"Reconhecer sinais de prontidão, escolher técnicas de fechamento adequadas e manter follow-up sem pressionar o cliente.","summary":"O material apresenta sinais verbais, não verbais e comportamentais de prontidão, seis técnicas de fechamento e orientações para recuperar vendas, fazer follow-up e saber quando encerrar a cadência preservando relacionamento.","key_points":["Perguntas sobre preço, prazo e implementação podem indicar prontidão.","Fechamento deve facilitar uma decisão já amadurecida.","Escassez só funciona eticamente quando é verdadeira.","Follow-up precisa trazer valor novo.","Persistência tem limite: rejeições claras exigem respeito."],"content_sections":[{"title":"Seis técnicas apresentadas","items":["Pergunta direta.","Alternativas.","Presunção.","Benefício recente.","Escassez genuína.","Perda de oportunidade quantificada."],"variant":"default"},{"title":"Follow-up de valor","body":"Cada contato deve acrescentar algo: case, insight, informação, ajuste ou resposta. Repetir apenas ''estou acompanhando'' aumenta pressão sem aumentar clareza.","variant":"highlight"},{"title":"Quando parar","body":"O material sugere encerrar com respeito após ausência prolongada de resposta, rejeições claras ou mudança de prioridade. Preservar a relação é mais valioso do que perseguir uma venda sem aderência.","variant":"warning"},{"title":"Exercício","body":"Mapeie os sinais de prontidão mais comuns em suas vendas e associe uma técnica de fechamento natural a cada um. Defina também seu critério de encerramento de follow-up.","variant":"practice"}],"pedagogical_content_version":"fase5f-b-v1","pedagogical_content_model":"content_sections-v1","pedagogical_source_asset_id":"d51e0a0e-f39a-4de7-85e0-8cf8d8063530","pedagogical_source_sha256":"D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84"}'::jsonb,
    updated_at = now()
where id = 'e8a4ffb7-76c6-52b6-9d37-65f1949d238c'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and status = 'published'
  and title = 'Técnicas Avançadas de Fechamento'
  and coalesce((metadata ->> 'source_module_sequence')::integer, 0) = 11
  and coalesce((metadata ->> 'source_lesson_sequence')::integer, 0) = 4
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (
    metadata ? 'content_sections'
    or metadata ? 'pedagogical_content_version'
    or metadata ? 'learning_objective'
    or metadata ? 'summary'
    or metadata ? 'key_points'
  );

-- ============================================================================
-- 2. METADADOS DO TREINAMENTO
-- ============================================================================

update public.training_library_items
set metadata =
      metadata
      || jsonb_build_object(
        'pedagogical_content_version', 'fase5f-b-v1',
        'pedagogical_content_model', 'content_sections-v1',
        'pedagogical_lesson_count', 58,
        'pedagogical_source_asset_id', 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530',
        'pedagogical_source_sha256', 'D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84',
        'pedagogical_enrichment_scope', 'all_lessons'
      ),
    updated_at = now()
where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and status = 'published'
  and metadata ->> 'content_model_version' = 'fase5e-v1'
  and not (metadata ? 'pedagogical_content_version');

-- ============================================================================
-- 3. PÓS-CONDIÇÕES FAIL-CLOSED
-- ============================================================================

do $postconditions$
declare
  v_rich_lessons bigint;
  v_modules bigint;
  v_lessons bigint;
  v_duration bigint;
  v_active_assets bigint;
  v_training_ok bigint;
begin
  select count(*)
    into v_rich_lessons
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published'
    and metadata ->> 'pedagogical_content_version' = 'fase5f-b-v1'
    and nullif(trim(metadata ->> 'learning_objective'), '') is not null
    and nullif(trim(metadata ->> 'summary'), '') is not null
    and jsonb_typeof(metadata -> 'key_points') = 'array'
    and jsonb_array_length(metadata -> 'key_points') >= 3
    and jsonb_typeof(metadata -> 'content_sections') = 'array'
    and jsonb_array_length(metadata -> 'content_sections') >= 3;

  if v_rich_lessons <> 58 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_POSTCONDITION_FAILED: esperado conteúdo rico em 58 aulas; encontrado %',
      v_rich_lessons;
  end if;

  select count(*)
    into v_modules
  from public.training_library_modules
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published';

  select count(*), coalesce(sum(duration_minutes), 0)
    into v_lessons, v_duration
  from public.training_library_lessons
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'published';

  select count(*)
    into v_active_assets
  from public.training_library_assets
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and training_id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and status = 'active';

  if v_modules <> 11
     or v_lessons <> 58
     or v_duration <> 580
     or v_active_assets <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_POSTCONDITION_FAILED: estrutura mudou (mod %, aulas %, duração %, assets %)',
      v_modules, v_lessons, v_duration, v_active_assets;
  end if;

  select count(*)
    into v_training_ok
  from public.training_library_items
  where id = '8cf3f39c-ee82-409d-b499-7cf321a54b04'::uuid
    and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and status = 'published'
    and metadata ->> 'content_model_version' = 'fase5e-v1'
    and metadata ->> 'pedagogical_content_version' = 'fase5f-b-v1'
    and metadata ->> 'pedagogical_content_model' = 'content_sections-v1'
    and coalesce((metadata ->> 'pedagogical_lesson_count')::integer, 0) = 58
    and metadata ->> 'pedagogical_source_asset_id' = 'd51e0a0e-f39a-4de7-85e0-8cf8d8063530'
    and metadata ->> 'pedagogical_source_sha256' = 'D28448B0B2E377AF5233B939543BAFB165D75D865547EF1627335F5A8B912B84';

  if v_training_ok <> 1 then
    raise exception
      'TRAINING_LIBRARY_PHASE5F_B_POSTCONDITION_FAILED: metadados do treinamento divergiram';
  end if;
end;
$postconditions$;
