# RF Performance — Testes 2 a 5 — Homologação piloto

Este pacote publica, de forma controlada, os Testes 2, 3, 4 e 5 para o mesmo
usuário piloto utilizado na Fase 1D.

## Arquivos

- `supabase/migrations/20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto.sql`
- `supabase/validators/23_validate_avaliacoes_certificacao_testes2a5_homologacao_piloto_readonly.sql`
- `docs/avaliacoes-certificacao-testes2a5-homologacao-piloto.md`

## Efeito esperado

- Testes 2 a 5 passam de `draft` para `active`;
- versões `2026.08-v1` passam de `draft` para `published`;
- quatro grants privados individuais são criados para o Usuário Teste RF;
- nenhum grant organizacional é criado;
- apenas o Teste 2 fica liberado pelo pré-requisito;
- Testes 3, 4 e 5 permanecem bloqueados até as aprovações anteriores;
- nenhuma tentativa, resposta, nota ou certificação é criada;
- a tentativa piloto do Teste 1 permanece em `29/30`.

## Ordem segura

1. copiar os três arquivos para o projeto;
2. conferir hashes;
3. inspecionar estaticamente a migration;
4. executar `npm run build` apenas se houver alteração frontend — este pacote não altera frontend;
5. executar `npx supabase db push --dry-run`;
6. aplicar com `npx supabase db push`;
7. executar o validador somente leitura no SQL Editor;
8. testar visualmente a progressão no frontend;
9. adicionar os arquivos seletivamente ao Git.
