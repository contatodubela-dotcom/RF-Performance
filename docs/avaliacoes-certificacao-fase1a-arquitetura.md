# Avaliações e Certificação Comercial — Fase 1A

## Objetivo

Criar a fundação multiempresa para cinco quizzes de certificação comercial, sem expor gabaritos ao navegador e sem importar as 150 questões nesta fase.

## Decisão de segurança

A arquitetura separa conteúdo aplicável e conteúdo sensível:

- `public.assessment_questions`: enunciado, competência e dificuldade.
- `public.assessment_question_options`: alternativas sem indicador de correção.
- `private.assessment_question_keys`: alternativa correta, justificativa, fonte e erro crítico.
- `private.assessment_attempt_grades`: resultado de cada questão após a entrega.

Nenhuma tabela nova concede acesso direto a `anon` ou `authenticated`. A aplicação usará RPCs `SECURITY DEFINER` específicas na Fase 1B.

## Tabelas de configuração

- `certification_levels`
- `competency_domains`
- `assessment_tests`
- `assessment_test_versions`
- `assessment_questions`
- `assessment_question_options`
- `assessment_version_questions`

## Tabelas de aplicação e progresso

- `assessment_attempts`
- `assessment_attempt_items`
- `assessment_attempt_answers`
- `assessment_competency_scores`
- `practical_assessments`
- `member_certifications`

## Tabelas privadas

- `private.assessment_question_keys`
- `private.assessment_attempt_grades`

## Imutabilidade histórica

`assessment_attempt_items` guarda o snapshot do enunciado e das alternativas apresentados ao vendedor. Uma revisão futura do banco de questões não altera provas já iniciadas ou concluídas.

## Perfis previstos

- **Vendedor:** vê e executa apenas as próprias avaliações.
- **Supervisor:** acompanha somente vendedores das equipes que gerencia e registra avaliação prática.
- **Diretor:** acompanha toda a organização.
- **Platform admin:** administra a plataforma e todas as organizações.

As RPCs que concretizam esses acessos serão introduzidas somente após a importação e validação do catálogo.

## Próximas fases

1. **Fase 1B — Catálogo:** importar níveis, competências, cinco testes, versões e 150 questões.
2. **Fase 1C — Aplicação segura:** iniciar tentativa, salvar resposta, retomar e entregar.
3. **Fase 1D — Painéis e prática:** resultados por competência, role-play e certificações.
4. **Fase 1E — Frontend:** substituir a página provisória e remover `pending: true`.
