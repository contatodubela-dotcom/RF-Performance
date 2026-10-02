# Gestão Administrativa da Biblioteca de Treinamentos

## Objetivo

Permitir que o Administrador da Plataforma cadastre e mantenha treinamentos
diretamente pelo RF Performance, sem SQL manual, migrations específicas para
cada novo curso ou comandos no terminal.

## O que o pacote adiciona

- rota exclusiva do Platform Admin: `/app/administracao/treinamentos`;
- item de menu **Gestão de Treinamentos**;
- atalho **Gerenciar treinamentos** na página de Treinamentos;
- criação e edição de treinamentos;
- publicação e retorno para rascunho;
- definição de categoria, público e destaque;
- duplicação de treinamento com módulos e aulas em rascunho;
- arquivamento sem exclusão física e sem apagar progresso;
- criação e edição de módulos;
- criação e edição de aulas;
- arquivamento de módulos e aulas;
- upload de PDF, PowerPoint, Word e imagens para o bucket privado
  `training-materials`;
- cadastro e arquivamento de materiais;
- atualização automática dos metadados de módulos, aulas e duração;
- RPCs administrativas restritas ao Platform Admin.

## Preservação do que já está em produção

O pacote não recria as tabelas existentes e não altera os IDs atuais. Os
treinamentos, módulos, aulas, materiais e progressos existentes permanecem
intactos.

Arquivamento usa `status = 'archived'` e `archived_at`; não existe exclusão
física dos registros da biblioteca pela interface.

## Arquivos principais

- `supabase/migrations/20261002030000_gestao_treinamentos_admin.sql`
- `src/pages/app/TrainingLibraryAdminPage.tsx`
- `src/services/trainingLibraryAdminService.ts`
- `src/types/trainingLibraryAdmin.ts`
- `src/constants/routes.ts`
- `src/constants/permissions.ts`
- `src/components/layout/Sidebar.tsx`
- `src/pages/app/TrainingPage.tsx`
- `src/App.tsx`

## Implantação

1. Aplicar a migration no Supabase:
   `supabase db push --linked --dry-run`
2. Conferir que somente a migration
   `20261002030000_gestao_treinamentos_admin.sql` está pendente.
3. Aplicar:
   `supabase db push --linked`
4. Rodar:
   `npm run build`
5. Fazer o deploy da aplicação.
6. Entrar como Platform Admin e selecionar a organização ativa.
7. Abrir **Administração → Gestão de Treinamentos**.

## Fluxo recomendado para um novo treinamento

1. Clique em **Novo treinamento**.
2. Cadastre título, descrição, categoria, público e destaque.
3. O treinamento nasce como **Rascunho**.
4. Adicione módulos, se houver experiência estruturada.
5. Adicione aulas e conteúdo de cada aula.
6. Envie apostila, apresentação e outros materiais.
7. Revise o curso.
8. Edite o treinamento e altere o status para **Publicado**.

## Duplicação

Ao duplicar, o sistema copia treinamento, módulos e aulas como rascunho.
Arquivos não são duplicados automaticamente, evitando referências duplicadas e
cópias ocultas no Storage. Os materiais do novo treinamento devem ser enviados
explicitamente.

## Segurança

- a nova rota é exclusiva de `platform_admin`;
- todas as novas RPCs administrativas validam
  `private.is_platform_admin()`;
- o bucket continua privado;
- upload e remoção de upload falho no Storage são permitidos somente ao
  Platform Admin;
- leitura dos materiais continua seguindo as regras existentes;
- o progresso dos usuários não é apagado pelo arquivamento.

## Testes mínimos antes do merge

- build do frontend concluído;
- rota indisponível para perfis não admin;
- criar treinamento rascunho;
- adicionar módulo;
- adicionar aula;
- enviar PDF;
- publicar treinamento;
- confirmar aparição na biblioteca para o público selecionado;
- duplicar e confirmar cópia em rascunho;
- arquivar um treinamento de teste e confirmar que ele some da biblioteca sem
  apagar histórico.
