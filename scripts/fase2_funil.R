# ==============================================================================
# PROKNOW-C FASE 2: FUNIL MATEMÁTICO E REPRESENTATIVIDADE CIENTÍFICA
# Operações: Pareto (80%), Artigos Recentes (Estado da Arte) e Repescagem
# ==============================================================================
#
# Pré-requisito: rode fase1_triagem.R primeiro e preencha manualmente a coluna
# "Alinhamento_Titulo" (1 = alinhado, 0 = não alinhado) no arquivo gerado em
# data/processed/1_Matriz_Triagem_Titulos.xlsx antes de rodar este script.
#
# Pacotes necessários (ver renv.lock para versões travadas):
#   install.packages(c("dplyr", "readxl", "writexl", "stringr", "here"))

library(dplyr)
library(readxl)
library(writexl)
library(stringr)
library(here)

# --------------------------------------------------------------------------
# 0. Configuração
# --------------------------------------------------------------------------
ANO_CORTE_RECENTES <- 2024  # ajuste conforme a janela de "estado da arte" do seu protocolo

caminho_entrada <- here("data", "processed", "1_Matriz_Triagem_Titulos.xlsx")
caminho_saida   <- here("data", "processed", "2_Portfolio_Para_Resumos.xlsx")

cat("=======================================================\n")
cat("  INICIANDO FASE 2 DO PROKNOW-C: FUNIL MATEMÁTICO\n")
cat("=======================================================\n\n")

# --------------------------------------------------------------------------
# 1. Carregar a Matriz de Triagem
# --------------------------------------------------------------------------
base_triada <- tryCatch({
  x <- read_excel(caminho_entrada)
  cat("[OK] Arquivo Excel lido com sucesso.\n")
  x
}, error = function(e) {
  stop(paste("[ERRO] Não foi possível ler o arquivo. Verifique se o caminho está correto",
             "e se o arquivo está fechado no Excel.\nDetalhe:", e$message))
})

# --------------------------------------------------------------------------
# 2. Filtrar apenas os artigos ALINHADOS (1) e tratar campos
# --------------------------------------------------------------------------
alinhados <- base_triada %>%
  filter(Alinhamento_Titulo == 1) %>%
  mutate(
    TC = as.numeric(TC),
    PY = as.numeric(PY)
  ) %>%
  mutate(TC = ifelse(is.na(TC), 0, TC)) %>%
  arrange(desc(TC))

total_alinhados <- nrow(alinhados)
cat("-> Total de artigos alinhados pelo título (Filtro 1):", total_alinhados, "\n\n")

if (total_alinhados == 0) stop("Nenhum artigo marcado como '1' (Alinhado). O funil não pode prosseguir.")

# ==============================================================================
# PILAR A: ELITE PARETO (80% DAS CITAÇÕES)
# ==============================================================================
total_citacoes <- sum(alinhados$TC)

if (total_citacoes == 0) {
  cat("[AVISO] A soma de citações é zero. Nenhum artigo fará Pareto por citação.\n")
  pareto_elite <- data.frame()
} else {
  pareto_elite <- alinhados %>%
    mutate(Percentual_Acumulado = cumsum(TC) / total_citacoes * 100) %>%
    filter(Percentual_Acumulado <= 80 | lag(Percentual_Acumulado, default = 0) < 80)
}

cat("-> PILAR A (Elite Pareto 80%):", nrow(pareto_elite), "artigos retidos.\n")

# ==============================================================================
# PILAR B: ESTADO DA ARTE (ARTIGOS RECENTES)
# ==============================================================================
recentes <- alinhados %>%
  filter(!Identificador %in% pareto_elite$Identificador) %>%
  filter(PY >= ANO_CORTE_RECENTES & !is.na(PY))

cat("-> PILAR B (Recentes >=", ANO_CORTE_RECENTES, "):", nrow(recentes), "artigos resgatados.\n")

# ==============================================================================
# PILAR C: REPESCAGEM DE AUTORES (CONEXÃO INTELECTUAL)
# ==============================================================================
if (nrow(pareto_elite) > 0) {
  autores_elite <- pareto_elite$AU %>%
    str_split(";") %>%
    unlist() %>%
    str_trim() %>%
    unique()

  artigos_restantes <- alinhados %>%
    filter(!Identificador %in% pareto_elite$Identificador) %>%
    filter(!Identificador %in% recentes$Identificador)

  if (nrow(artigos_restantes) > 0) {
    repescados <- artigos_restantes %>%
      rowwise() %>%
      mutate(
        Autores_Deste_Artigo = list(str_trim(unlist(str_split(AU, ";")))),
        Tem_Autor_Elite = any(Autores_Deste_Artigo %in% autores_elite)
      ) %>%
      filter(Tem_Autor_Elite == TRUE) %>%
      select(-Autores_Deste_Artigo, -Tem_Autor_Elite) %>%
      ungroup()
  } else {
    repescados <- data.frame()
  }
} else {
  repescados <- data.frame()
}

cat("-> PILAR C (Repescagem de Autores):", nrow(repescados), "artigos repescados.\n\n")

# ==============================================================================
# CONSOLIDAÇÃO DO BANCO PARA LEITURA DE RESUMOS (PORTFÓLIO FASE 2)
# ==============================================================================
portfolio_fase2 <- bind_rows(
  if (nrow(pareto_elite) > 0) pareto_elite %>% mutate(Criterio_ProKnowC = "1. Elite Pareto (80%)"),
  if (nrow(recentes) > 0) recentes %>% mutate(Criterio_ProKnowC = "2. Estado da Arte (Recente)"),
  if (nrow(repescados) > 0) repescados %>% mutate(Criterio_ProKnowC = "3. Repescagem (Autoria)")
) %>%
  arrange(desc(TC), desc(PY)) %>%
  mutate(Ordem_Leitura = row_number())

write_xlsx(portfolio_fase2, caminho_saida)

cat("=======================================================\n")
cat("  PORTFÓLIO FASE 2 GERADO COM SUCESSO!\n")
cat("  Total de artigos para ler o Resumo:", nrow(portfolio_fase2), "\n")
cat("  Arquivo salvo em:", caminho_saida, "\n")
cat("=======================================================\n")
