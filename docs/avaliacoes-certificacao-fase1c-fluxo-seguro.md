# Avaliações e Certificações — Fase 1C

## Objetivo

Implementar o fluxo transacional do quiz por RPC, mantendo tabelas e gabaritos sem acesso direto pelo navegador.

## RPCs públicas

- `get_available_assessments(uuid)` — lista somente testes ativos com versão publicada.
- `start_assessment_attempt(uuid, uuid)` — inicia ou retoma tentativa própria.
- `get_assessment_attempt(uuid)` — entrega o snapshot sem gabarito.
- `save_assessment_answer(uuid, uuid, text)` — salva ou altera resposta enquanto a tentativa estiver aberta.
- `submit_assessment_attempt(uuid)` — entrega e corrige no servidor, na mesma transação.
- `get_assessment_attempt_result(uuid)` — retorna notas, competências e revisão conforme o portão seguro.

## Segurança

- todas as RPCs usam `SECURITY DEFINER` e `search_path` fixo;
- somente `authenticated` recebe `EXECUTE` nas RPCs públicas;
- `anon` e `PUBLIC` permanecem sem execução;
- as funções privadas não são executáveis pelo cliente;
- nenhuma tabela do módulo recebe privilégio direto de leitura ou gravação;
- `get_assessment_attempt` não consulta `private.assessment_question_keys`;
- a correção ocorre apenas em `submit_assessment_attempt`;
- uma tentativa aceita somente o próprio usuário autenticado;
- snapshots tornam enunciados e alternativas imutáveis por tentativa;
- limite de tentativas, cooldown e pré-requisitos são conferidos no servidor;
- lock transacional reduz corrida para criação simultânea de tentativas.

## Progressão configurada

1. Teste 1: sem pré-requisito; diagnóstico concluído libera o Teste 2.
2. Teste 2: exige Teste 1 corrigido.
3. Teste 3: exige aprovação no Teste 2.
4. Teste 4: exige aprovação no Teste 3.
5. Teste 5: exige aprovação no Teste 4.

## Política de revisão

- diagnóstico: revisão detalhada após a correção;
- testes de certificação: revisão detalhada somente após aprovação ou após a última tentativa;
- na primeira reprovação, o usuário recebe notas e desempenho por competência, mas não o gabarito completo.

Essa regra preserva o objetivo pedagógico sem transformar a primeira tentativa em fonte de respostas para a segunda.

## Configuração preservada do catálogo

- 30 questões por teste;
- 2 tentativas;
- cooldown de 24 horas;
- sem limite de tempo nesta versão;
- ordem das questões fixa;
- ordem das alternativas embaralhada;
- 96 marcações críticas permanecem pendentes de homologação;
- zero erros críticos eliminatórios ativos.

## Estado após a migration

Os cinco testes e as cinco versões continuam em `draft`. Portanto:

- nenhuma avaliação aparece como disponível;
- nenhuma tentativa é criada automaticamente;
- o item do menu continua pendente;
- a publicação e o frontend ficam para a próxima fase.
