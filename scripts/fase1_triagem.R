# ==============================================================================
# PROKNOW-C FASE 1: GERAÇÃO DA MATRIZ DE TRIAGEM DE TÍTULOS
# Origem: Web of Science (Exportação Direta)
# Construto: Governo Aberto, Resiliência e Gestão Local
# ==============================================================================
#
# Como rodar:
#   1. Abra este projeto via ProKnow_C_com_Bibliometrix.Rproj no RStudio
#      (garante que here::here() resolva a raiz do projeto corretamente).
#   2. Coloque o export bruto da Web of Science em data/raw/
#      (pasta ignorada pelo Git — ver README.md, seção "Dados").
#   3. Ajuste NOME_ARQUIVO_ENTRADA abaixo para o nome do seu arquivo.
#   4. Rode este script inteiro.
#
# Pacotes necessários (ver renv.lock para versões travadas):
#   install.packages(c("dplyr", "readr", "readxl", "writexl", "here"))

library(dplyr)
library(readr)
library(readxl)
library(writexl)
library(here)

# --------------------------------------------------------------------------
# 0. Configuração
# --------------------------------------------------------------------------
NOME_ARQUIVO_ENTRADA <- "savedrecs.xls"  # troque pelo nome real do seu arquivo

caminho_arquivo <- here("data", "raw", NOME_ARQUIVO_ENTRADA)
caminho_saida   <- here("data", "processed", "1_Matriz_Triagem_Titulos.xlsx")

cat("=======================================================\n")
cat("  PROKNOW-C: PREPARAÇÃO PARA TRIAGEM DE TÍTULOS\n")
cat("=======================================================\n\n")

# --------------------------------------------------------------------------
# 1. Leitura Inteligente (A WoS às vezes salva CSV com extensão .xls)
# --------------------------------------------------------------------------
cat("Lendo arquivo bruto da Web of Science...\n")
base_wos <- tryCatch({
  read_excel(caminho_arquivo)
}, error = function(e) {
  read_csv(caminho_arquivo, show_col_types = FALSE)
})

cat("-> Base bruta carregada:", nrow(base_wos), "linha(s),", ncol(base_wos), "coluna(s).\n\n")

# --------------------------------------------------------------------------
# 1b. Validação de sanidade
# --------------------------------------------------------------------------
# read_excel() pode "ter sucesso" silenciosamente mesmo quando o arquivo
# real é XLSX salvo com extensão .xls (ou vice-versa), retornando poucas
# linhas com colunas erradas sem lançar erro. Isso faz o tryCatch acima
# nunca cair no fallback de CSV, e o funil seguiria com dado corrompido.
# A validação abaixo pega esse caso cedo.
colunas_esperadas <- c("Article Title", "Authors", "Publication Year", "Source Title", "Abstract", "DOI")
colunas_faltando <- setdiff(colunas_esperadas, names(base_wos))

if (length(colunas_faltando) > 0) {
  stop(
    "[ERRO] Arquivo lido, mas faltam colunas esperadas: ",
    paste(colunas_faltando, collapse = ", "),
    ".\nIsso costuma indicar que a extensão do arquivo (.xls/.xlsx/.csv) não bate ",
    "com o formato real do conteúdo. Confira o arquivo em ", caminho_arquivo,
    " e ajuste a extensão ou o formato de exportação da WoS/Scopus."
  )
}

if (nrow(base_wos) < 2) {
  stop(
    "[ERRO] Apenas ", nrow(base_wos), " linha(s) foram lidas — abaixo do esperado ",
    "para um export bibliográfico. Provável leitura incorreta do arquivo. Confira ",
    caminho_arquivo, "."
  )
}

cat("-> Validação de colunas e volume: OK.\n\n")

# --------------------------------------------------------------------------
# 2. Padronização das Colunas (Mapeamento WoS para Bibliometrix)
# --------------------------------------------------------------------------
base_triagem <- base_wos %>%
  select(
    TI = `Article Title`,
    AU = `Authors`,
    PY = `Publication Year`,
    SO = `Source Title`,
    TC = contains("Times Cited, WoS Core"),
    AB = `Abstract`,
    DI = `DOI`
  ) %>%
  mutate(
    Identificador = row_number(),
    Alinhamento_Titulo = "",
    Justificativa_Exclusao = "",
    TC = as.numeric(TC),
    PY = as.numeric(PY)
  ) %>%
  mutate(TC = ifelse(is.na(TC), 0, TC)) %>%
  arrange(desc(TC))

# --------------------------------------------------------------------------
# 3. Exportação da Planilha de Trabalho
# --------------------------------------------------------------------------
write_xlsx(base_triagem, caminho_saida)

cat("=======================================================\n")
cat("  MATRIZ GERADA\n")
cat("  Arquivo salvo em:", caminho_saida, "\n")
cat("=======================================================\n")
