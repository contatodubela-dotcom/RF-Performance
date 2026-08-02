# RF Performance — Plano e metas da operação real — Fase 2

## Escopo

Esta fase alinha o Plano de 90 Dias e as metas à estrutura real confirmada da RF:

- 5 PDVs;
- 5 equipes;
- 5 supervisores-vendedores;
- 15 vendedores;
- 20 produtores ativos;
- 5 vagas;
- capacidade plena de 25 produtores;
- mínimo inicial de 7 cotas por produtor;
- referência operacional atual de 140 cotas/mês;
- capacidade plena inicial de 175 cotas/mês;
- curva de maturidade: 175, 200, 225 e 250 cotas nos meses 3, 6, 9 e 12.

## Regra sobre o baseline

O número 140 não é tratado como baseline histórico. Ele é uma referência operacional calculada por capacidade:

- 20 produtores ativos × 7 cotas = 140.

O baseline histórico fica nulo e com status pendente até a validação do dashboard oficial de vendas.

## Alterações no banco

A migration:

- atualiza `organizations.metadata`;
- atualiza o único `commercial_plans` não arquivado da RF;
- mantém `status`, datas e execução do plano;
- atualiza apenas o objetivo da primeira fase;
- corrige títulos e descrições com referências antigas;
- preserva status, conclusão, evidências e responsáveis das ações;
- atualiza as metas gerais;
- cria ou atualiza metas para os 5 PDVs;
- cria ou atualiza metas para as 5 equipes;
- preserva `actual_value` das metas existentes;
- não altera RLS, grants, funções ou schema.

## Distribuição de capacidade

Cada PDV e equipe recebe:

- capacidade plena: 35 cotas/mês;
- referência atual conforme produtores ativos:
  - Volkswagen São Gonçalo: 35;
  - Volkswagen Grande Rio: 21;
  - Volkswagen Caxias: 28;
  - FIAT Caxias: 28;
  - FIAT Grande Rio: 28.

As referências somam 140 na estrutura atual e 175 na capacidade plena.

## Arquivos

- `supabase/migrations/20260801110000_atualiza_plano_metas_rf_fase2.sql`
- `supabase/verification/12_validate_plano_metas_rf_fase2_readonly.sql`

## Aplicação

Na raiz do projeto:

```powershell
npx supabase db push
```

A migration possui validações transacionais. Se a organização, o plano, os cinco PDVs, as cinco equipes ou as somas esperadas não forem encontrados, a transação é cancelada.

## Validação

Depois da aplicação, execute no Supabase SQL Editor:

```text
supabase/verification/12_validate_plano_metas_rf_fase2_readonly.sql
```

Resultado esperado:

```text
validation_result = PASS
```

O campo `validation_details` também deve mostrar:

- `location_goal_count = 5`;
- `team_goal_count = 5`;
- `location_current_total = 140`;
- `location_full_total = 175`;
- `team_current_total = 140`;
- `team_full_total = 175`;
- `legacy_reference_count = 0`.

## O que esta fase não faz

- não importa o histórico do dashboard;
- não cria usuários ou convites;
- não vincula supervisores às equipes;
- não distribui a meta definitiva aprovada pelos supervisores;
- não altera resultados realizados;
- não altera segurança ou permissões.
