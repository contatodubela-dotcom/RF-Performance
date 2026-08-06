# Avaliações e Certificações — Fase 1D — Acesso piloto individual

## Objetivo

Criar um portão privado e auditável para liberar uma versão de avaliação a um membro específico, antes de qualquer publicação geral.

## Piloto validado

- Organização: RF Consórcios
- Organização ID: `414a2e84-bc62-4c64-99ee-76db1cbc4654`
- Usuário: Usuário Teste RF
- E-mail: `empilhaplus@gmail.com`
- User ID: `e88242b6-e44e-4de7-97cf-dbefc0605eaf`
- Organization Member ID: `49239d09-0f85-471f-8f46-5c240cd98600`
- Perfil: `salesperson`

## Avaliação piloto

- Teste: Teste 1 — Diagnóstico inicial
- Test ID: `4bbd0f10-5444-5826-860b-aed020cb6acc`
- Versão: `2026.08-v1`
- Version ID: `fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4`
- Questões vinculadas: 30
- Gabaritos privados: 30
- Tentativas existentes antes da migration: 0

## O que a migration faz

1. executa preflight estrito do piloto e do catálogo;
2. cria `private.assessment_test_access_grants`;
3. cria `private.assessment_test_access_allowed(...)`;
4. aplica bloqueio por padrão em:
   - `public.get_available_assessments(uuid)`;
   - `public.start_assessment_attempt(uuid, uuid)`;
5. cadastra um único grant individual para o piloto;
6. reafirma que navegador, `anon` e `authenticated` não acessam a tabela/helper privados;
7. mantém o Teste 1 e sua versão em `draft`;
8. não cria tentativas.

## O que a migration não faz

- não publica o Teste 1;
- não publica nenhuma versão;
- não libera outros membros;
- não ativa erros críticos eliminatórios;
- não altera o frontend;
- não cria certificados;
- não cria tentativas.

## Comportamento esperado após aplicação

O grant privado já existirá, mas o Teste 1 continuará invisível porque o teste e a versão permanecem em rascunho. A publicação controlada será preparada separadamente, somente depois que o validador retornar 27 de 27 verificações com `PASS`.

## Arquivos

- Migration: `supabase/migrations/20260806023000_avaliacoes_certificacao_fase1d_acesso_piloto_individual.sql`
- Validador: `supabase/validators/19_validate_avaliacoes_certificacao_fase1d_acesso_piloto_readonly.sql`
- Arquitetura: `docs/avaliacoes-certificacao-fase1d-acesso-piloto.md`

## Sequência segura

1. conferir os hashes dos quatro arquivos;
2. revisar a migration;
3. executar dry-run local;
4. aplicar a migration remota;
5. executar o validador somente leitura;
6. confirmar 27/27 `PASS`;
7. somente então preparar a publicação temporária e reversível do Teste 1.
