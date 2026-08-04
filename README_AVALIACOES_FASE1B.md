# RF Performance — Avaliações e Certificações — Fase 1B

## Conteúdo do pacote

- `supabase/migrations/20260804233000_avaliacoes_certificacao_fase1b_catalogo_publico.sql`: catálogo público versionado, seguro para commit.
- `supabase/validators/17_validate_avaliacoes_certificacao_fase1b_readonly.sql`: validador somente leitura, seguro para commit.
- `privado_nao_commitir/NAO_COMMITIR_gabaritos_privados_fase1b_04ago2026.sql`: gabaritos privados; **NUNCA adicionar ao Git**.
- `docs/avaliacoes-certificacao-fase1b-catalogo.md`: decisões e contagens.

## Vínculo confirmado

- Organização: `RF Consórcios` (`414a2e84-bc62-4c64-99ee-76db1cbc4654`)
- Plano de referência: `Plano de Aceleração Comercial — 90 Dias` (`baa2bbd9-7688-4fcc-92a8-16a96ca969db`)

O catálogo é vinculado tecnicamente à organização. O plano aparece apenas em `metadata` para rastreabilidade, pois as tabelas da Fase 1A não possuem `commercial_plan_id`.

## Ordem segura

1. Copiar apenas a migration pública e o validador para o repositório.
2. Conferir `git status` e o conteúdo da migration.
3. Aplicar a migration pública via Supabase CLI.
4. Executar o arquivo privado pelo SQL Editor do projeto correto.
5. Executar o validador e exigir 20/20 PASS.
6. Commitar somente a migration pública, o validador e a documentação.

## Erros críticos

As 96 marcações de origem foram preservadas apenas no gabarito privado como `source_critical_flag`. Todas permanecem com `is_critical = false` até homologação manual.

## Fonte

- Versão: `2026.08-v1`
- Revisão: `2026-08-03`
- SHA-256: `e3ba2f891bf274be34439dc3e0007f0d9d3768b91c45f1a44aecae5197c852ab`
