# Avaliações e Certificações — Fase 1D — Correção auditável de codificação

## Problema confirmado

A auditoria encontrou mojibake em todos os 150 registros privados de gabarito:

- 149 justificativas afetadas;
- 150 referências afetadas;
- 0 motivos críticos afetados.

Exemplos:

- `consÃ³rcio` → `consórcio`;
- `reuniÃ£o` → `reunião`;
- `nÂº` → `nº`;
- `â€”` → `—`.

## Estratégia

A migration usa a mesma conversão validada em preflight:

```sql
convert_from(convert_to(texto, 'WIN1252'), 'UTF8')
```

A conversão é aplicada apenas aos campos que apresentam padrões suspeitos.

## Auditoria e reversibilidade

Antes da atualização, cada gabarito é registrado em:

```text
private.assessment_question_key_text_repairs
```

A tabela guarda:

- justificativa antes e depois;
- referência antes e depois;
- motivo crítico antes e depois;
- alternativa correta e criticidade anteriores;
- datas, revisores e metadados anteriores;
- código e horário do reparo.

Assim, o conteúdo original permanece disponível para auditoria e eventual restauração controlada.

## Campos alterados

Somente:

- `private.assessment_question_keys.justification`;
- `private.assessment_question_keys.source_reference`;
- `private.assessment_question_keys.updated_at`;
- marcador auditável em `metadata`.

Não são alterados:

- `correct_option_code`;
- `is_critical`;
- `critical_reason`;
- questões e alternativas públicas;
- tentativas, respostas, notas e competências;
- certificações;
- publicação e acesso piloto.

## Validação

O validador somente leitura confirma 30 condições, incluindo:

- auditoria privada inacessível ao navegador;
- 150 snapshots antes/depois;
- ausência de mojibake após o reparo;
- distribuição A/B/C/D preservada;
- tentativa piloto `72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe` preservada com 29/30;
- publicação e acesso individual preservados;
- nenhum certificado emitido pelo diagnóstico.
