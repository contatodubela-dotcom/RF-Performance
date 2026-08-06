# Fase 1D — Publicação controlada do diagnóstico piloto

## Decisão

O Teste 1 é publicado apenas depois da criação do portão privado de acesso.
A publicação não transforma o catálogo em acesso geral: as RPCs continuam
exigindo uma liberação ativa para a versão e para o membro autenticado.

## Participante piloto

- nome: Usuário Teste RF;
- usuário: `e88242b6-e44e-4de7-97cf-dbefc0605eaf`;
- vínculo: `49239d09-0f85-471f-8f46-5c240cd98600`;
- organização: `414a2e84-bc62-4c64-99ee-76db1cbc4654`.

## Avaliação publicada

- teste: `4bbd0f10-5444-5826-860b-aed020cb6acc`;
- versão: `fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4`;
- código: `teste_1_diagnostico`;
- versão lógica: `2026.08-v1`;
- questões: 30;
- tentativas máximas: 2;
- intervalo: 24 horas;
- nota geral: 60%;
- nota jurídica: 70%;
- revisão: imediata após correção;
- erros críticos eliminatórios: desativados.

## Garantias da migration

A migration falha antes de qualquer alteração quando:

- o piloto ou a organização não estão ativos;
- o grant individual não é único;
- existe grant organizacional;
- outro membro já possui acesso;
- a versão não possui 30 questões e 30 gabaritos;
- alguma chave crítica eliminatória está ativa;
- já existe tentativa do teste;
- os estados atuais não são exatamente `draft`.

Depois da atualização, a transaction confirma que:

- somente o Teste 1 fica `active`;
- somente a versão do Teste 1 fica `published`;
- todos os demais testes e versões continuam `draft`;
- o piloto continua autorizado;
- os demais membros continuam bloqueados;
- nenhuma tentativa foi criada.

## Homologação

Após o validador passar, o teste deve ser executado com o Usuário Teste RF.
O teste manual deve verificar listagem, início, salvamento, retomada, entrega,
correção, notas, competências e revisão detalhada do diagnóstico.
