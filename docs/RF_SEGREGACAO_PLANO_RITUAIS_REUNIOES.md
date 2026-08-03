# Segregação do plano comercial, rituais e reuniões

## Objetivo

Impedir que vendedores e supervisores recebam o plano comercial completo ou
rituais incompatíveis com seu papel, sem quebrar Treinamentos, Feedbacks ou
Reuniões durante a implantação.

## Matriz de rituais

### Vendedor

- Abertura do PDV
- Fechamento do dia
- Feedback individual
- Microtreinamento
- Role-play

### Supervisor

Recebe os cinco rituais do vendedor e também:

- Performance mensal
- Reunião de supervisores
- Revisão de funil

### Diretor e administrador da plataforma

Recebem todos os nove rituais, incluindo a Reunião executiva de performance.

## Implantação em duas fases

### Fase compatível — migration 20260802190000

- Classifica os rituais em `metadata.audience_roles`.
- Cria `get_commercial_plan_reference(uuid)`.
- Cria `get_management_rituals_for_current_user(uuid)`.
- Mantém temporariamente as policies antigas de leitura direta para não quebrar
  o frontend que já está em produção.
- O novo frontend usa as duas RPCs e recebe somente os rituais permitidos.

### Fase de endurecimento — posterior ao deploy

Depois que o novo frontend estiver publicado e validado, uma migration separada
deve remover as policies amplas de `commercial_plans` e `management_rituals` e
substituí-las por policies restritas à liderança e ao público classificado.

Essa segunda migration não faz parte deste pacote para impedir que o `db push`
aplique as duas fases no mesmo momento.

## Proteções do frontend

- O plano completo é consultado somente por administrador e diretor.
- Telas operacionais usam somente a referência mínima do plano.
- A página Reuniões obtém rituais por RPC filtrada no servidor.
- A policy existente de `meeting_records` continua limitando os registros à
  equipe autorizada.
- As consultas React Query usam o identificador do usuário na chave.
- Consultas de equipes e membros destinadas a formulários não são executadas
  para vendedores.

## Arquivos

- `src/hooks/useCommercialPlan.ts`
- `src/pages/app/MeetingsPage.tsx`
- `src/pages/app/TrainingPage.tsx`
- `src/pages/app/FeedbacksPage.tsx`
- `supabase/migrations/20260802190000_segrega_plano_rituais_reunioes_por_perfil.sql`
- `supabase/verification/14_validate_segregacao_plano_rituais_reunioes_readonly.sql`

## Impacto em dados

A migration não remove planos, rituais, reuniões, equipes ou usuários. Ela
classifica os rituais existentes e cria duas RPCs seguras. As policies antigas
são preservadas nesta fase compatível.
