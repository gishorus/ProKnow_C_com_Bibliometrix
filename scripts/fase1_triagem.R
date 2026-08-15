# ==============================================================================
# PROKNOW-C FASE 1: IMPORTAÇÃO, DEDUPLICAÇÃO E MATRIZ DE TRIAGEM DE TÍTULOS
# Origem: Web of Science (Core Collection) + Scopus (exportações diretas)
# Construto: Governo Aberto, Resiliência e Consórcios Públicos Intermunicipais
# ==============================================================================
#
# Como rodar:
#   1. Abra este projeto via ProKnow_C_com_Bibliometrix.Rproj no RStudio.
#   2. Coloque os exports brutos em data/raw/:
#        - Web of Science: export .xls/.xlsx via "Save to Excel" (Fast5000 ou completo)
#        - Scopus: export .csv com todos os campos disponíveis
#   3. Ajuste NOME_ARQUIVO_WOS e NOME_ARQUIVO_SCOPUS abaixo.
#   4. Rode este script inteiro. Ele gera data/processed/1_Matriz_Triagem_Titulos.xlsx,
#      já combinada e deduplicada, pronta para marcação manual de Alinhamento_Titulo.
#
# Pacotes necessários (ver docs/session_info.txt para versões validadas):
#   install.packages(c("dplyr", "readr", "readxl", "writexl", "stringr", "here"))

library(dplyr)
library(readr)
library(readxl)
library(writexl)
library(stringr)
library(here)

# --------------------------------------------------------------------------
# 0. Configuração
# --------------------------------------------------------------------------
NOME_ARQUIVO_WOS     <- "savedrecs.xls"
NOME_ARQUIVO_SCOPUS  <- "scopus_export.csv"

caminho_wos     <- here("data", "raw", NOME_ARQUIVO_WOS)
caminho_scopus  <- here("data", "raw", NOME_ARQUIVO_SCOPUS)
caminho_saida   <- here("data", "processed", "1_Matriz_Triagem_Titulos.xlsx")

cat("=======================================================\n")
cat("  PROKNOW-C: IMPORTACAO, DEDUPLICACAO E TRIAGEM DE TITULOS\n")
cat("=======================================================\n\n")

# --------------------------------------------------------------------------
# 1. Leitura e normalização — Web of Science
# --------------------------------------------------------------------------
cat("Lendo export da Web of Science...\n")
wos_bruto <- read_excel(caminho_wos)

colunas_wos_esperadas <- c("Article Title", "Authors", "Publication Year", "Source Title", "Abstract", "DOI")
faltando_wos <- setdiff(colunas_wos_esperadas, names(wos_bruto))
if (length(faltando_wos) > 0) {
  stop("[ERRO] Export da WoS sem as colunas esperadas: ", paste(faltando_wos, collapse = ", "),
       ". Confira ", caminho_wos, ".")
}

wos_norm <- wos_bruto %>%
  transmute(
    TI = `Article Title`,
    AU = Authors,
    PY = as.numeric(`Publication Year`),
    SO = `Source Title`,
    TC = as.numeric(.data[[grep("Times Cited, WoS Core", names(wos_bruto), value = TRUE)[1]]]),
    AB = Abstract,
    DI = DOI,
    Fonte = "WoS"
  )

cat("-> WoS:", nrow(wos_norm), "registros.\n")

# --------------------------------------------------------------------------
# 2. Leitura e normalização — Scopus
# --------------------------------------------------------------------------
cat("Lendo export da Scopus...\n")
scopus_bruto <- read_csv(caminho_scopus, show_col_types = FALSE)

colunas_scopus_esperadas <- c("Title", "Authors", "Year", "Source title", "Cited by", "Abstract", "DOI")
faltando_scopus <- setdiff(colunas_scopus_esperadas, names(scopus_bruto))
if (length(faltando_scopus) > 0) {
  stop("[ERRO] Export da Scopus sem as colunas esperadas: ", paste(faltando_scopus, collapse = ", "),
       ". Confira ", caminho_scopus, ".")
}

scopus_norm <- scopus_bruto %>%
  transmute(
    TI = Title,
    AU = Authors,
    PY = as.numeric(Year),
    SO = `Source title`,
    TC = as.numeric(`Cited by`),
    AB = Abstract,
    DI = DOI,
    Fonte = "Scopus"
  )

cat("-> Scopus:", nrow(scopus_norm), "registros.\n\n")

# --------------------------------------------------------------------------
# 3. Combinação e deduplicação (duas etapas)
# --------------------------------------------------------------------------
# Etapa 1: deduplicação por DOI. WoS é mantida preferencialmente em empates
# (ordenação por Fonte antes do distinct()), critério documentado aqui por
# ser arbitrário mas precisa ser consistente e auditável.
#
# Etapa 2: deduplicação adicional por título normalizado, sobre o resultado
# da etapa 1. Necessária porque o mesmo artigo pode ter DOI indexado de forma
# diferente entre WoS e Scopus (variação de formatação ou erro de OCR/export
# em uma das bases) — casos que a etapa 1, sozinha, não captura.
combinado <- bind_rows(wos_norm, scopus_norm) %>%
  mutate(
    DI_norm = str_trim(str_to_lower(DI)),
    TI_norm = str_trim(str_to_lower(str_replace_all(TI, "[[:punct:][:space:]]+", " ")))
  ) %>%
  arrange(desc(Fonte == "WoS"))

etapa1 <- combinado %>%
  mutate(chave_doi = ifelse(!is.na(DI_norm) & DI_norm != "", DI_norm, paste0("__semdoi__", row_number()))) %>%
  distinct(chave_doi, .keep_all = TRUE)

etapa2 <- etapa1 %>% distinct(TI_norm, .keep_all = TRUE)

n_duplicatas <- nrow(combinado) - nrow(etapa2)
cat("-> Total combinado (WoS + Scopus):", nrow(combinado), "\n")
cat("-> Duplicatas removidas:", n_duplicatas, "\n")
cat("-> Registros unicos apos deduplicacao:", nrow(etapa2), "\n\n")

# --------------------------------------------------------------------------
# 4. Padronização final e exportação
# --------------------------------------------------------------------------
base_triagem <- etapa2 %>%
  mutate(TC = ifelse(is.na(TC), 0, TC)) %>%
  arrange(desc(TC)) %>%
  transmute(
    TI, AU, PY, SO, TC, AB, DI, Fonte,
    Identificador = row_number(),
    Alinhamento_Titulo = NA_real_,
    Justificativa_Exclusao = NA_character_
  )

write_xlsx(base_triagem, caminho_saida)

cat("=======================================================\n")
cat("  MATRIZ DE TRIAGEM GERADA\n")
cat("  Total de registros unicos:", nrow(base_triagem), "\n")
cat("  Arquivo salvo em:", caminho_saida, "\n")
cat("  Preencha manualmente a coluna Alinhamento_Titulo (1/0) antes da Fase 2.\n")
cat("=======================================================\n")
