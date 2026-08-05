# RF Performance — Avaliações e Certificações — Fase 1C

## Arquivos

- `supabase/migrations/20260805003000_avaliacoes_certificacao_fase1c_fluxo_seguro_quiz.sql`
- `supabase/validators/18_validate_avaliacoes_certificacao_fase1c_readonly.sql`
- `docs/avaliacoes-certificacao-fase1c-fluxo-seguro.md`

## Ordem de aplicação

1. Copiar os três arquivos públicos para o projeto.
2. Conferir hashes e ausência de comandos destrutivos.
3. Executar `npx supabase@latest db push --dry-run`.
4. Aplicar com `npx supabase@latest db push`.
5. Executar o validador no SQL Editor do projeto `spkxjirsdddnxusyowyl`.
6. Exigir 24 resultados `PASS` antes do commit.

## Escopo

A migration cria oito funções: seis RPCs públicas e duas auxiliares privadas. Também registra a sequência de pré-requisitos e a política de revisão no `metadata` dos cinco testes.

Ela não publica testes, não altera o frontend, não ativa o menu, não cria tentativas e não modifica os 150 gabaritos.
