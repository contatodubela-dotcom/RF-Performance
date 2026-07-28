# Template operacional demonstrável

## Objetivo

Deixar a RF Consórcios preparada para apresentação antes do levantamento dos
nomes reais dos shoppings, supervisores e vendedores.

## Estrutura inicial

- 3 PDVs modelo, editáveis;
- 3 equipes modelo, editáveis;
- 3 posições planejadas de supervisor;
- 20 posições planejadas de vendedor;
- capacidade distribuída em 7 + 7 + 6 vendedores;
- referência mensal de 130 cotas;
- objetivo mensal de 169 cotas, equivalente a crescimento de 30%;
- plano com duração inicial de 90 dias.

## Registros de modelo

Os registros recebem metadados de configuração:

- `template_record`;
- `template_key`;
- `setup_status`;
- `data_origin`;
- `confirmed_at`;
- `confirmed_by`;
- capacidade planejada.

Enquanto `setup_status` for `pending_confirmation`, a interface informa que os
dados são provisórios. O administrador pode editar e confirmar os registros
sem apagá-los ou recriá-los.

## Usuários

Nenhum supervisor ou vendedor fictício é criado. Usuários reais continuam
entrando pelo fluxo seguro de convite.

O Usuário Teste RF pode ser vinculado a uma equipe modelo pela própria tela de
equipes, somente para demonstração de acesso.

## Transferência de vendedor

Cada vendedor pode pertencer a somente uma equipe ativa por vez. Para transferir:

1. encerrar o vínculo atual;
2. criar o vínculo na nova equipe;
3. preservar o histórico anterior.

## Reutilização

Os componentes do frontend leem os metadados do registro e não dependem dos
nomes da RF. Outras organizações podem receber a mesma estrutura com nomes,
capacidades e metas diferentes.
