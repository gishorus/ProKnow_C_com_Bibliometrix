# ProKnow_C_com_Bibliometrix

Scripts em R para as Fases 1 e 2 do protocolo **ProKnow-C** (Knowledge Development
Process, Constructivist), aplicados à Revisão Sistemática de Literatura (RSL) sobre
**Governo Aberto e Resiliência Organizacional em Consórcios Públicos Intermunicipais**,
desenvolvida no Programa de Pós-Graduação em Contabilidade (PPGC/UFPA).

## Objetivo

Automatizar duas etapas do funil ProKnow-C a partir de exportações brutas da Web of
Science e Scopus:

1. **Fase 1 Importação, deduplicação e triagem de títulos**: lê os exports brutos das
   duas bases, normaliza para um esquema comum, remove duplicatas (por DOI e, quando o
   DOI diverge entre bases, por título normalizado) e prepara a planilha para marcação
   manual de alinhamento (coluna `Alinhamento_Titulo`).
2. **Fase 2 Funil matemático**: aplica os três pilares de representatividade científica
   sobre os artigos alinhados, Elite Pareto (80% das citações), Estado da Arte (artigos
   recentes) e Repescagem por Autoria, e consolida o portfólio para leitura de resumos.

## Estrutura do repositório

```
.
├── scripts/
│   ├── fase1_triagem.R      # Importação WoS + Scopus, deduplicação, matriz de triagem
│   └── fase2_funil.R        # Funil Pareto / recentes / repescagem
├── docs/
│   ├── Figura1.drawio       # Fluxograma do funil ProKnow-C (editável em app.diagrams.net)
│   ├── LICENSE-CC-BY.md     # Licença do conteúdo em docs/
│   └── session_info.txt     # Versões de R/pacotes validadas
├── data/
│   ├── raw/                 # Exports brutos (NÃO versionado — ver seção "Dados")
│   └── processed/           # Planilhas geradas pelos scripts (NÃO versionado)
├── ProKnow_C_com_Bibliometrix.Rproj
├── LICENSE                  # MIT — código (scripts/)
└── CITATION.cff
```

## Como rodar

1. Abra `ProKnow_C_com_Bibliometrix.Rproj` no RStudio.
2. Instale as dependências:
   ```r
   install.packages(c("dplyr", "readr", "readxl", "writexl", "stringr", "here"))
   ```
3. Coloque os exports brutos em `data/raw/`:
   - Web of Science: export `.xls`/`.xlsx` (colunas padrão da WoS, incluindo
     `Times Cited, WoS Core`).
   - Scopus: export `.csv` com todos os campos disponíveis (precisa das colunas
     `Title`, `Authors`, `Year`, `Source title`, `Cited by`, `Abstract`, `DOI`).
4. Rode `scripts/fase1_triagem.R`. Ele importa as duas bases, deduplica e gera
   `data/processed/1_Matriz_Triagem_Titulos.xlsx`.
5. Preencha manualmente a coluna `Alinhamento_Titulo` nessa planilha (1 = alinhado ao
   construto, 0 = não alinhado). O script da Fase 2 recusa rodar se houver células em
   branco nessa coluna.
6. Rode `scripts/fase2_funil.R`. Ele gera `data/processed/2_Portfolio_Para_Resumos.xlsx`,
   ordenado pela ordem de leitura recomendada, com DOIs já formatados como links.

## Dados

Os exports brutos da Web of Science e Scopus **não são redistribuídos neste
repositório** por restrição de licença dos provedores (Clarivate/Elsevier). As pastas
`data/raw/` e `data/processed/` estão no `.gitignore`. Para reproduzir os resultados, é
necessário acesso institucional a essas bases (neste projeto, via Portal de Periódicos
da Capes/CAFe) e refazer a busca com as strings documentadas no fluxograma
(`docs/Figura1.drawio`).

Buscas realizadas em 10/05/2026 nas bases Web of Science (Core Collection) e Scopus,
retornando 256 registros brutos (121 Web of Science + 135 Scopus).

## Deduplicação — critério documentado

A deduplicação usa duas etapas, nessa ordem:

1. **Por DOI normalizado.** Quando o mesmo DOI aparece nas duas bases, mantém-se a
   versão da Web of Science (critério de desempate arbitrário, mas fixo e auditável).
2. **Por título normalizado**, aplicada sobre o resultado da etapa 1. Necessária porque
   3 dos 256 registros brutos tinham o mesmo artigo indexado com DOI ligeiramente
   diferente entre WoS e Scopus (variação de formatação ou erro de exportação em uma das
   bases), o que a etapa 1 sozinha não captura.

Esse processo foi validado com os dados brutos reais desta pesquisa e reproduz
exatamente os 172 registros e 84 duplicatas documentados no funil abaixo.

## Reprodutibilidade

O pipeline (Fases 1 e 2) foi validado de ponta a ponta contra os dados reais desta
pesquisa em 14–15/08/2026: a Fase 1 reproduz 172 registros a partir dos 256 brutos, e a
Fase 2, aplicada sobre a triagem real de 27 artigos alinhados, reproduz exatamente 10
(Elite Pareto) + 15 (Estado da Arte) + 0 (Repescagem) = 25 artigos.

Versões de R/pacotes usadas nessa validação estão em `docs/session_info.txt`. Um
`renv.lock` formal (via `renv::init()` + `renv::snapshot()`) ainda não foi gerado neste
repositório — fica como próximo passo de engenharia, não bloqueador para a submissão do
artigo.

## Funil ProKnow-C (resultado desta RSL)

256 → 172 (importação WoS + Scopus, deduplicação) → 27 (triagem de título) → 25 (Elite
Pareto + Estado da Arte, 2 excluídos no teste de representatividade) → 22 (3 artigos
inacessíveis para leitura integral) → **PB = 21** (1 excluído após leitura integral, por
ausência da dimensão de Governo Aberto).

Ver `docs/Figura1.drawio` para o fluxograma completo, incluindo as strings de busca
usadas em cada base.

## Citação

Ver `CITATION.cff`.

## Licença

- Código (`scripts/`): [MIT](LICENSE)
- Diagrama e documentação (`docs/`): [CC-BY 4.0](docs/LICENSE-CC-BY.md)
