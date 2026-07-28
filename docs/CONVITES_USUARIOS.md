# Convites e vínculos de usuários

## Objetivo

Implementar o fluxo seguro de convite para usuários organizacionais do RF
Performance Comercial.

Papéis permitidos:

- `director`
- `supervisor`
- `salesperson`

O papel global `platform_admin` não pode ser criado por este fluxo.

## Arquitetura

1. Um administrador autenticado usa a tela **Usuários**.
2. O frontend invoca a Edge Function `invite-user`.
3. A função valida a sessão do solicitante.
4. A função valida o papel e a organização.
5. A função usa uma secret key somente no ambiente protegido da Edge Function.
6. O Supabase Auth envia o convite.
7. O perfil público e o vínculo organizacional são criados ou reativados.
8. A operação é registrada em auditoria.

## Permissões

### Platform admin

Pode convidar:

- diretor;
- supervisor;
- vendedor.

### Diretor

Pode convidar, somente na própria organização:

- supervisor;
- vendedor.

Diretores não podem convidar outros diretores.

## Segurança

- A função não aceita chamadas sem uma sessão de usuário válida.
- O `verify_jwt` da plataforma fica desativado para esta função, mas o JWT é
  obrigatoriamente validado dentro do código com `auth.getUser()`.
- As origens são limitadas pelo secret `ALLOWED_ORIGINS`.
- A secret key nunca é enviada ao navegador.
- Convites repetidos com o mesmo papel são idempotentes.
- Um conflito de papel não altera privilégios silenciosamente.
- Se um convite novo falhar antes da criação do vínculo, a função tenta remover
  o usuário recém-criado para evitar registros órfãos.
- Usuários globais `platform_admin` não recebem vínculo empresarial por convite.

## Variáveis de ambiente da Edge Function

O Supabase fornece automaticamente:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEYS`
- `SUPABASE_SECRET_KEYS`

Também são aceitas as variáveis legadas como fallback:

- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Defina manualmente:

```text
APP_URL=http://localhost:8080
ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

Antes de convidar usuários reais, substitua `APP_URL` pelo domínio de produção
do Cloudflare Pages e adicione esse domínio a `ALLOWED_ORIGINS` e às Redirect
URLs do Supabase Auth.

## Configuração da função

Acrescente ao `supabase/config.toml`:

```toml
[functions.invite-user]
verify_jwt = false
```

A autenticação não fica pública: o código da função rejeita toda chamada sem
JWT válido.

## Deploy

```powershell
npx supabase secrets set `
  APP_URL=http://localhost:8080 `
  ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080

npx supabase functions deploy invite-user
```

## Teste inicial

Use um e-mail de teste controlado pelo administrador. Não convide Raphael,
supervisores ou vendedores reais antes da validação completa.

Fluxo esperado:

1. Abrir `/app/usuarios`.
2. Clicar em **Convidar usuário**.
3. Informar nome, e-mail e papel.
4. Confirmar que o vínculo aparece na lista.
5. Abrir o e-mail do convite.
6. Definir a senha em `/atualizar-senha`.
7. Confirmar o acesso limitado ao papel escolhido.
8. Executar
   `supabase/verification/06_validate_invited_user_readonly.sql`.

## Observação sobre o fluxo de autenticação

O aplicativo é uma SPA executada inteiramente no navegador. O cliente Supabase
usa o fluxo implícito para aceitar convites administrativos, pois o fluxo PKCE
exige que a troca do código ocorra no mesmo navegador que iniciou o processo.
