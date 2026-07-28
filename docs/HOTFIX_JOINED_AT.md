# Hotfix de joined_at

## Motivo

O fluxo de convite foi validado, porém o primeiro teste mostrou que
`organization_members.joined_at` permaneceu nulo mesmo após:

- confirmação do e-mail;
- definição da senha;
- primeiro login.

## Correção

A migration adiciona:

- função privada para sincronizar o aceite do convite;
- trigger em `auth.users`;
- backfill dos vínculos já confirmados;
- manutenção automática para convites futuros.

## Regra

`joined_at` passa a receber, nesta ordem:

1. `email_confirmed_at`;
2. `last_sign_in_at`;
3. horário atual como fallback.

O valor somente é preenchido quando ainda estiver nulo.

## Aplicação segura

1. Execute `npx supabase migration list`.
2. Execute `npx supabase db push --dry-run`.
3. Confirme que somente a migration do hotfix será aplicada.
4. Execute `npx supabase db push`.
5. Execute `07_validate_joined_at_readonly.sql`.
