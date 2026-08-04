# Pacote RF Performance — Avaliações e Certificação Fase 1A

## Arquivos

- `supabase/migrations/20260804213000_avaliacoes_certificacao_fase1a_fundacao.sql`
- `supabase/validators/16_validate_avaliacoes_certificacao_fase1a_readonly.sql`
- `docs/avaliacoes-certificacao-fase1a-arquitetura.md`

## Esta fase faz

- cria a fundação de dados;
- isola gabaritos e correções no schema `private`;
- ativa e força RLS;
- revoga acessos diretos de `anon` e `authenticated`;
- cria índices, constraints e funções auxiliares de escopo.

## Esta fase não faz

- não importa as 150 questões;
- não cria tentativas reais;
- não altera o frontend;
- não remove `pending: true` do menu;
- não publica RPCs para o navegador.

## Ordem segura

1. Copiar os arquivos para o repositório.
2. Conferir `git diff --stat` e o conteúdo da migration.
3. Aplicar a migration com o fluxo Supabase já usado no projeto.
4. Executar o validador somente leitura.
5. Somente continuar se o validador retornar 20 resultados `PASS`.
