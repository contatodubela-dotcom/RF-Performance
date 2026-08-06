# Arquitetura — acesso piloto individual às avaliações

## Problema

As RPCs da Fase 1C filtravam avaliações por organização, vínculo ativo, versão publicada, pré-requisitos, tentativas e cooldown. Não existia uma dimensão de autorização individual por teste ou versão.

Publicar o Teste 1 sem um portão adicional permitiria acesso a todos os membros ativos da organização.

## Solução

Foi adicionada uma tabela no schema `private`:

```text
private.assessment_test_access_grants
```

Cada registro é associado a:

- organização;
- teste;
- versão do teste;
- escopo `member` ou `organization`;
- membro, quando o escopo for individual;
- período opcional de validade;
- estado `active` ou `revoked`;
- motivo e metadados de auditoria.

## Bloqueio por padrão

O helper privado:

```text
private.assessment_test_access_allowed(
  organization_id,
  organization_member_id,
  test_id,
  test_version_id
)
```

retorna `true` apenas quando:

1. o membro e o perfil permanecem ativos;
2. teste e versão pertencem à organização indicada;
3. existe grant ativo e não arquivado;
4. o grant está dentro da janela de validade;
5. o grant é individual para o membro ou organizacional.

Sem grant, o resultado é `false`.

## Defesa em profundidade

O helper é usado em dois pontos:

### Listagem

`get_available_assessments` somente agrega versões que estejam:

- publicadas e válidas;
- ligadas a teste ativo;
- autorizadas pelo helper privado.

### Início direto

`start_assessment_attempt` valida novamente o helper, mesmo que alguém tente chamar a RPC diretamente com um `test_id`.

Quando não há liberação, a RPC lança:

```text
ASSESSMENT_ACCESS_NOT_GRANTED
```

## Privacidade

A tabela e o helper ficam no schema `private`.

Permissões diretas são revogadas de:

- `public`;
- `anon`;
- `authenticated`.

O navegador continua acessando apenas as RPCs públicas autorizadas.

## Grant piloto

A migration inclui somente um grant:

- organização: `414a2e84-bc62-4c64-99ee-76db1cbc4654`;
- membro: `49239d09-0f85-471f-8f46-5c240cd98600`;
- teste: `4bbd0f10-5444-5826-860b-aed020cb6acc`;
- versão: `fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4`;
- escopo: `member`.

Não existe grant organizacional e os demais testes não recebem grants.

## Estado de publicação

A migration não altera:

```text
assessment_tests.status = draft
assessment_test_versions.status = draft
assessment_test_versions.published_at = null
```

Assim, o grant isolado não torna a avaliação visível. Ele apenas prepara o portão seguro para a próxima etapa controlada.

## Reversibilidade operacional

Antes da operação real, um grant pode ser revogado definindo:

```text
status = revoked
```

ou preenchendo:

```text
archived_at
```

A publicação e a reversão temporárias do Teste 1 serão tratadas em script separado, depois da validação desta migration.
