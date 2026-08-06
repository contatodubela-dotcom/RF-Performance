# Avaliações e certificações — Testes 2 a 5 — homologação piloto

## Contexto

O Teste 1 foi homologado com o Usuário Teste RF. A tentativa concluída obteve
29 respostas corretas em 30, 96,67% de nota geral, 100% em legislação e nenhum
erro crítico.

O catálogo já contém as 150 questões e as cinco versões `2026.08-v1`. Os
Testes 2, 3, 4 e 5 permaneciam em rascunho, sem tentativas e sem grants.

## Objetivo da Fase 1E

Publicar as quatro versões restantes exclusivamente para o usuário piloto,
mantendo o controle privado de acesso e a progressão:

1. Teste 2 exige que o Teste 1 esteja corrigido;
2. Teste 3 exige aprovação no Teste 2;
3. Teste 4 exige aprovação no Teste 3;
4. Teste 5 exige aprovação no Teste 4.

## Segurança

A migration:

- usa uma transação única;
- executa preflight estrito;
- exige 30 questões revisadas, 120 alternativas, 30 gabaritos e posições 1–30;
- exige zero tentativas nos Testes 2 a 5;
- exige zero grants ativos anteriores para as versões;
- cria apenas grants com escopo `member`;
- não cria acesso com escopo `organization`;
- não modifica RPCs, RLS, respostas, notas ou certificados;
- confirma que somente o Teste 2 fica elegível inicialmente;
- preserva a tentativa piloto do Teste 1, suas 30 respostas e 30 notas privadas.

## Resultado esperado no frontend

O usuário piloto deve visualizar as cinco avaliações. O Teste 1 permanece
concluído, o Teste 2 aparece disponível para iniciar e os Testes 3 a 5 aparecem
bloqueados por pré-requisito.
