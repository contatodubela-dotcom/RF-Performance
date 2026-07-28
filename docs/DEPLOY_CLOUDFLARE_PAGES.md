# Deploy no Cloudflare Pages

## Objetivo

Publicar o RF Performance Comercial em Cloudflare Pages usando integração com
o repositório GitHub.

## Configuração do projeto Pages

- Repositório: `contatodubela-dotcom/RF-Performance`
- Branch de produção: `main`
- Framework preset: `Vite`
- Build command: `npm run build`
- Build output directory: `dist`
- Root directory: `/`
- Node.js: `22.16.0`

## Variáveis públicas de build

Cadastre em Production e Preview:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

Use exatamente os mesmos valores do arquivo local `.env.local`.

Não cadastre no Cloudflare Pages:

- secret key;
- service_role;
- senha do banco;
- token da Supabase CLI;
- qualquer segredo da Edge Function.

## Arquivos desta fase

### `.node-version`

Fixa o Node.js usado no build.

### `public/_redirects`

Garante que rotas da SPA sejam resolvidas pelo `index.html`.

### `public/_headers`

Adiciona proteção básica contra enquadramento, interpretação incorreta de
conteúdo e uso desnecessário de recursos do navegador.

## Primeira publicação

Após o merge desta fase:

1. Acesse Cloudflare > Workers & Pages.
2. Crie uma aplicação Pages conectada ao GitHub.
3. Selecione o repositório RF-Performance.
4. Configure a branch `main`.
5. Informe o comando e o diretório de build.
6. Cadastre as duas variáveis públicas.
7. Salve e aguarde o deploy.
8. Registre o endereço `https://<projeto>.pages.dev`.

## Ajustes no Supabase Auth

Depois de conhecer o endereço Pages:

- Site URL:
  `https://<projeto>.pages.dev`

- Redirect URLs:
  `https://<projeto>.pages.dev/atualizar-senha`
  `http://localhost:8080/atualizar-senha`
  `http://127.0.0.1:8080/atualizar-senha`

Mantenha URLs exatas em produção.

## Atualização da Edge Function

Atualize os secrets:

```powershell
npx supabase secrets set `
  APP_URL=https://<projeto>.pages.dev `
  ALLOWED_ORIGINS=https://<projeto>.pages.dev,http://localhost:8080,http://127.0.0.1:8080
```

A alteração dos secrets entra em vigor sem novo deploy da função.

## Testes obrigatórios

- abrir `/login` diretamente;
- autenticar como administrador;
- atualizar a página em `/app/plano-90-dias`;
- abrir `/app/equipes` diretamente;
- sair e entrar novamente;
- solicitar recuperação de senha com e-mail controlado;
- convidar somente um usuário de teste;
- confirmar redirecionamento para `/atualizar-senha`;
- validar a visão restrita do vendedor;
- confirmar ausência de chaves secretas no bundle e no repositório.

Não convide usuários reais antes da conclusão desses testes.
