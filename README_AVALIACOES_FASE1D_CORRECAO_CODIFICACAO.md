# Avaliações e Certificações — Fase 1D — Correção de codificação

Este pacote corrige os textos privados de justificativa e referência dos 150 gabaritos da RF Consórcios.

## Escopo

- conversão determinística de `WIN1252` para `UTF8`;
- 149 justificativas corrigidas;
- 150 referências corrigidas;
- tabela privada de auditoria com valores anteriores e posteriores;
- preservação de alternativas corretas, criticidade, tentativa piloto, notas e certificações;
- nenhuma alteração no frontend.

## Arquivos

- `supabase/migrations/20260806104500_avaliacoes_certificacao_fase1d_corrige_codificacao_gabaritos.sql`
- `supabase/validators/21_validate_avaliacoes_certificacao_fase1d_correcao_codificacao_readonly.sql`
- `docs/avaliacoes-certificacao-fase1d-correcao-codificacao.md`

## Segurança

A tabela `private.assessment_question_key_text_repairs`:

- mantém os textos originais e corrigidos;
- possui RLS ativa e forçada;
- não concede acesso a `public`, `anon` ou `authenticated`;
- não deve ser exposta diretamente ao navegador.

## Resultado esperado

- 150 registros privados continuam existentes;
- 0 justificativas com mojibake;
- 0 referências com mojibake;
- gabarito A/B/C/D permanece 38/38/37/37;
- tentativa piloto permanece concluída com 29/30;
- validador: 30 verificações com `PASS`.
