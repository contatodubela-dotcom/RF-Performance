# RF Performance — Operação real com cinco PDVs — Fase 1

## Escopo

Esta fase altera somente a estrutura operacional:

- converte os 3 modelos existentes em PDVs reais;
- preserva os IDs dos três PDVs e três times existentes;
- preserva o vínculo do usuário de teste;
- cria 2 PDVs e 2 equipes adicionais;
- registra supervisores e vendedores confirmados em `metadata`;
- não cria contas nem convites;
- não altera ainda o baseline 130, a meta 169 ou as metas do plano;
- não importa ainda o dashboard histórico.

## Mapeamento usado

- `PDV Modelo 1` → `Volkswagen Caxias`
- `PDV Modelo 2` → `Volkswagen Grande Rio`
- `PDV Modelo 3` → `Volkswagen São Gonçalo`
- novo → `FIAT Caxias`
- novo → `FIAT Grande Rio`

O Modelo 1 foi convertido em Volkswagen Caxias porque já continha dados de Caxias
e possui o usuário de teste vinculado. O vínculo permanece no mesmo `team_id`.

## Extração

```powershell
Expand-Archive `
  -LiteralPath "$env:USERPROFILE\Downloads\RF_Performance_Operacao_Real_5_PDVs_Fase1_v1.zip" `
  -DestinationPath "." `
  -Force
```

## Conferência local

```powershell
git status --short
```

Esperado:

```text
?? docs/RF_OPERACAO_REAL_5_PDVS_FASE1.md
?? supabase/migrations/20260731170000_operacao_real_rf_cinco_pdvs_fase1.sql
?? supabase/verification/10_validate_operacao_real_rf_cinco_pdvs_readonly.sql
```

Os arquivos de inventário 08 e 09 também continuarão aparecendo enquanto não forem
adicionados ao Git.

## Verificação antes da execução

```powershell
npx supabase migration list
```

```powershell
npx supabase db push --dry-run
```

O dry-run deve listar apenas:

```text
20260731170000_operacao_real_rf_cinco_pdvs_fase1.sql
```

Não execute o `db push` real antes da revisão e autorização.

## Validação posterior

Após a aplicação, copie o validador:

```powershell
Get-Content `
  -LiteralPath ".\supabase\verification\10_validate_operacao_real_rf_cinco_pdvs_readonly.sql" `
  -Raw |
Set-Clipboard
```

Execute no SQL Editor. O resultado esperado é `PASS`.
