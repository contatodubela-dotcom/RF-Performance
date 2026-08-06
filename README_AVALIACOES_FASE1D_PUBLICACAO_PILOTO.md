# Avaliações e Certificações — Fase 1D — Publicação piloto

Este pacote publica somente o **Teste 1 — Diagnóstico inicial** e sua versão
`2026.08-v1` para homologação controlada.

## Escopo

- organização: RF Consórcios;
- participante: Usuário Teste RF;
- perfil: vendedor;
- acesso: grant individual privado já implantado;
- outros membros: bloqueados;
- outros testes e versões: permanecem em rascunho;
- erros críticos eliminatórios: continuam desativados;
- tentativas: nenhuma é criada pela migration.

## Arquivos

- migration de publicação controlada;
- validador somente leitura com 30 verificações;
- documentação da estratégia e das condições de homologação.

## Procedimento

1. verificar hashes;
2. executar busca estática por comandos destrutivos;
3. executar `npx supabase@latest db push --dry-run`;
4. aplicar a migration após revisão;
5. executar o validador no SQL Editor;
6. testar visualmente com o Usuário Teste RF;
7. verificar que o segundo membro ativo não recebe o teste.
