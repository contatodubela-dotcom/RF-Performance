# Hotfix — rótulos multiempresa do plano comercial

## Motivo

A primeira versão demonstrável funcionou corretamente, mas ainda exibia rótulos
específicos da empresa piloto e do seu diretor em pontos do template:

- `Meta RF Consórcios` no código da tela;
- `Direção RF` e `EPSA / RF` nos responsáveis;
- `ROPRE com Raphael` como ritual planejado.

Esses textos dificultariam a reutilização do aplicativo para outras empresas.

## Correção

- A meta geral passa a usar o nome da organização ativa.
- Os responsáveis passam a usar `Direção da empresa` e `EPSA / Empresa`.
- O ritual executivo passa a se chamar `Reunião executiva de performance`.
- O responsável desse ritual passa a ser `EPSA / Direção`.
- O formulário de reunião usa exemplo genérico.

## Observação

O módulo `Abordagem em shopping` permanece no template atual porque representa a
operação de consórcio de automóveis em PDVs de shopping. Ele é editável e pode
ser substituído quando outro tipo de operação for implantado.
