# ProKnow_C_com_Bibliometrix

Scripts em R para as Fases 1 e 2 do protocolo **ProKnow-C** (Knowledge Development
Process, Constructivist), aplicados à Revisão Sistemática de Literatura (RSL) sobre
**Governo Aberto e Resiliência Organizacional em Consórcios Públicos Intermunicipais**,
desenvolvida no Programa de Pós-Graduação em Contabilidade (PPGC/UFPA).

## Objetivo

Automatizar duas etapas do funil ProKnow-C a partir de exportações brutas da Web of
Science / Scopus:

1. **Fase 1 Matriz de Triagem de Títulos**: padroniza o export bruto e prepara a
   planilha para marcação manual de alinhamento (coluna `Alinhamento_Titulo`).
2. **Fase 2 Funil Matemático**: aplica os três pilares de representatividade
   científica sobre os artigos alinhados — Elite Pareto (80% das citações), Estado da
   Arte (artigos recentes) e Repescagem por Autoria — e consolida o portfólio para
   leitura de resumos.

## Estrutura do repositório

```
.
├── scripts/
│   ├── fase1_triagem.R      # Fase 1 do ProKnow-C
│   └── fase2_funil.R        # Fase 2 do ProKnow-C
├── docs/
│   ├── Figura1.drawio       # Fluxograma do funil ProKnow-C (editável em app.diagrams.net)
│   └── session_info.txt     # Versões de R/pacotes usadas na última validação
├── data/
│   ├── raw/                 # Exports brutos (NÃO versionado — ver seção "Dados")
│   └── processed/           # Planilhas geradas pelos scripts (NÃO versionado)
├── ProKnow_C_com_Bibliometrix.Rproj
├── LICENSE                  # MIT — código (scripts/)
├── docs/LICENSE-CC-BY.md    # CC-BY 4.0 — diagrama e documentação
└── CITATION.cff
```

## Como rodar

1. Abra `ProKnow_C_com_Bibliometrix.Rproj` no RStudio (garante que `here::here()`
   resolva a raiz do projeto corretamente, independentemente do sistema operacional).
2. Instale as dependências:
   ```r
   install.packages(c("dplyr", "readr", "readxl", "writexl", "stringr", "here"))
   ```
3. Coloque o export bruto da Web of Science ou Scopus em `data/raw/`.
4. Rode `scripts/fase1_triagem.R`. Ele gera `data/processed/1_Matriz_Triagem_Titulos.xlsx`.
5. Preencha manualmente a coluna `Alinhamento_Titulo` nessa planilha (1 = alinhado ao
   construto, 0 = não alinhado).
6. Rode `scripts/fase2_funil.R`. Ele gera `data/processed/2_Portfolio_Para_Resumos.xlsx`,
   já ordenado pela ordem de leitura recomendada.

## Dados

Os exports brutos da Web of Science e Scopus **não são redistribuídos neste
repositório** por restrição de licença dos provedores (Clarivate/Elsevier). As pastas
`data/raw/` e `data/processed/` estão no `.gitignore`. Para reproduzir os resultados,
é necessário acesso institucional a essas bases (neste projeto, via Portal de
Periódicos da Capes/CAFe) e refazer a busca com as strings documentadas no fluxograma
(`docs/Figura1.drawio`).

Buscas originais realizadas em 21–22/05/2026, retornando 256 registros brutos
(121 Web of Science + 135 Scopus).

## Reprodutibilidade

A validação mais recente do pipeline (com dataset sintético, não incluído por não ser
necessário para reprodução) foi feita com as versões registradas em
`docs/session_info.txt`. Para travar as versões de pacotes no seu próprio ambiente,
rode `renv::init()` seguido de `renv::snapshot()` a partir da raiz do projeto — isso
gera um `renv.lock` específico do seu ambiente, que deve ser commitado.

## Funil ProKnow-C (resultado desta RSL)

256 → 172 (triagem de título + remoção de duplicatas) → 27 (leitura de resumos) → 25
(teste de representatividade de Pareto, 2 excluídos) → 22 (3 artigos inacessíveis para
leitura integral) → **PB = 21** (1 excluído após leitura integral, por ausência da
dimensão de Governo Aberto).

Ver `docs/Figura1.drawio` para o fluxograma completo, incluindo as strings de busca
usadas em cada base.

## Citação

Ver `CITATION.cff`.

## Licença

- Código (`scripts/`): [MIT](LICENSE)
- Diagrama e documentação (`docs/`): [CC-BY 4.0](docs/LICENSE-CC-BY.md)
