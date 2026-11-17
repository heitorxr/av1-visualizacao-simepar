arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), winslash = "/")
.libPaths(c(file.path(dirname(raiz), ".biblioteca"), .libPaths()))
library(shiny)
options(warn = 2)
source(file.path(raiz, "testes", "testar_analise.R"), encoding = "UTF-8")
modulo <- file.path(raiz, "R", "interface.R")
if (file.exists(modulo)) source(modulo, encoding = "UTF-8")
if (!exists("criar_servidor_global")) stop("RED: interface global ainda não implementada")
z$estacao_id <- ifelse(z$estacao == "São Paulo", "SBSP", "SBGR")
z$fonte <- "Fixture exclusiva de teste"
z$ponto_orvalho_c <- z$temperatura_c - 4
z$metar <- "Fixture exclusiva de teste"
inicial <- list(dados = z, origem = "Fixture exclusiva de teste", coletado_em = max(t), tentativa_em = max(t), historico_em = max(t), erro = NULL)
cadastro <- data.frame(estacao_id = c("SBSP", "SBGR"), estacao = c("São Paulo", "Guarulhos"), aeroporto = c("Congonhas", "Guarulhos"))
chamadas <- 0L
buscar <- function(raiz, forcar = FALSE) { chamadas <<- chamadas + 1L; inicial }
ui <- criar_ui_global(inicial, cadastro)
stopifnot(grepl("São Paulo em observação", as.character(ui), fixed = TRUE), grepl("automatico", as.character(ui), fixed = TRUE))
servidor <- criar_servidor_global(raiz, inicial, buscar, identity, cadastro)
sessao <- shiny::MockShinySession$new()
shiny::withReactiveDomain(sessao, servidor(sessao$input, sessao$output, sessao))
sessao$close()
shiny::testServer(servidor, {
  session$setInputs(cidades = cadastro$estacao, variavel = "temperatura_c", janela = as.numeric(range(t)), comuns = TRUE, automatico = FALSE)
  session$flushReact()
  stopifnot(grepl("5", output$metricas$html, fixed = TRUE), grepl("4", output$metricas$html, fixed = TRUE),
            grepl("Fixture", output$situacao$html, fixed = TRUE), length(output$serie$src) == 1L)
  session$setInputs(atualizar = 1)
  session$flushReact()
  stopifnot(chamadas == 1L)
})
cat("Interface: inicialização, saídas reativas, gráfico e atualização manual verificados.\n")
chamadas <- 0L
shiny::testServer(servidor, {
  session$setInputs(cidades = cadastro$estacao, variavel = "temperatura_c", janela = as.numeric(range(t)), comuns = TRUE, automatico = FALSE)
  session$elapse(300001)
  stopifnot(chamadas == 0L)
  session$setInputs(automatico = TRUE)
  session$flushReact()
  if (chamadas != 1L) stop("RED: ativar atualização automática deve consultar a fonte")
  session$elapse(300001)
  stopifnot(chamadas == 2L)
  session$setInputs(automatico = FALSE)
  session$elapse(600001)
  stopifnot(chamadas == 2L)
})
cat("Automática: cinco minutos, ativação e pausa sem consultas indevidas verificados.\n")
