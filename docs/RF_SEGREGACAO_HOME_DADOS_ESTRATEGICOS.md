# Segregação da Home e dos dados estratégicos

## Objetivo

Separar a experiência inicial por perfil e impedir que vendedores recebam
indicadores globais ou o campo `organizations.metadata`.

## Visibilidade

### Administrador da plataforma e diretor

Mantêm a Home estratégica, com referências de capacidade, estrutura,
vagas, checklist e configuração da operação.

### Supervisor

Recebe uma Home tática sem indicadores globais. O acesso continua limitado
aos módulos permitidos pelas rotas e pelas policies existentes.

### Vendedor

Recebe uma Home pessoal voltada a reuniões, treinamentos, avaliações e
feedbacks, sem referências globais, capacidade, vagas, estrutura ou checklist.

## Proteções implementadas

- cache do React Query separado por usuário;
- cache limpo no logout;
- hooks estratégicos habilitados apenas para administrador e diretor;
- `activeOrganization` reduzida a colunas básicas;
- retirada do `SELECT` geral de `authenticated` em `organizations`;
- `organizations.metadata` acessível somente por RPC autorizada;
- listagem administrativa feita por RPC exclusiva de `platform_admin`;
- nenhuma alteração em usuários, vínculos, PDVs, equipes, metas ou histórico.

## Migration

`20260802164500_restringe_metadados_estrategicos_organizacao.sql`

## Validador

`13_validate_segregacao_dados_estrategicos_readonly.sql`

## Testes obrigatórios

1. TypeScript, lint e build.
2. Administrador: Home estratégica completa.
3. Diretor: Home estratégica completa.
4. Supervisor: Home tática, sem indicadores globais.
5. Vendedor: Home pessoal, sem indicadores globais.
6. Troca vendedor → administrador no mesmo navegador sem cache cruzado.
7. Página Organizações funcionando para `platform_admin`.
8. Validador SQL com resultado `PASS`.
