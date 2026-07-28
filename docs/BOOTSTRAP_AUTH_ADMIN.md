# Bootstrap de autenticação e administrador inicial

## Objetivo

Documentar a configuração e a validação do primeiro administrador técnico do RF Performance Comercial.

Este procedimento é específico do ambiente hospedado do projeto RF Performance e não deve ser transformado em seed ou migration com e-mail/UUID pessoal.

## Configuração validada no Supabase Auth

- Provedor de e-mail habilitado.
- Novos cadastros públicos desabilitados.
- Entradas anônimas desabilitadas.
- Confirmação de e-mail habilitada.
- Site URL local: `http://localhost:8080`.
- Redirect local de atualização de senha: `http://localhost:8080/atualizar-senha`.

## Administrador inicial

O primeiro usuário técnico deve:

1. existir em `auth.users`;
2. possuir perfil correspondente em `public.profiles`;
3. estar com `status = 'active'`;
4. estar com `system_role = 'platform_admin'`;
5. possuir a promoção registrada em `public.audit_logs`.

O `platform_admin` é um papel global e não precisa de registro em `public.organization_members` para administrar as organizações da plataforma.

## Smoke test aprovado

O teste manual deve confirmar:

- login com e-mail e senha;
- redirecionamento para `/app/inicio`;
- nome e papel exibidos como administrador da plataforma;
- organização RF Consórcios carregada;
- três PDVs ativos exibidos;
- acesso ao grupo Administração;
- persistência da sessão após atualizar a página;
- logout e novo login funcionais;
- acesso direto a uma rota protegida sem sessão redireciona para `/login`.

## Segurança

- `.env.local` permanece ignorado pelo Git.
- O frontend utiliza somente `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`.
- A chave publicável pode existir no bundle do navegador e continua sujeita às policies RLS.
- Nunca usar no frontend: secret key, service role, senha do banco ou JWT secret.
- O e-mail e UUID do administrador não devem ser gravados em migrations ou seeds.

## Próxima fase

Implementar o fluxo administrativo de convites e vínculos:

- Edge Function `invite-user`;
- validação de origem autorizada;
- criação idempotente de `organization_members`;
- atribuição controlada de `director`, `supervisor` ou `salesperson`;
- vinculação posterior a equipes;
- auditoria do convite e do vínculo;
- testes de isolamento entre perfis e organizações.
