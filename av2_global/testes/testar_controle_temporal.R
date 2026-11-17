script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
source(file.path(raiz, "testes", "testar_servidor.R"), encoding = "UTF-8")
# A hora nova existe somente nesta fixture; nenhum arquivo de dados é gravado.
attr(inicial$dados$instante, "tzone") <- "America/Sao_Paulo"
novo <- inicial
a <- novo$dados[1, ]
a$instante <- max(novo$dados$instante) + 3600
a$observado_em <- a$instante
a$datahora <- format(a$instante, "%d/%m/%Y %H:%M")
novo$dados <- rbind(novo$dados, a)
mensagens <- list()
sessao <- shiny::MockShinySession$new()
sessao$sendInputMessage <- function(inputId, message) {
  if (inputId == "janela") mensagens[[length(mensagens) + 1L]] <<- message
}
srv <- criar_servidor_global(raiz, inicial, function(...) novo, identity, cadastro)
shiny::testServer(srv, {
  session$setInputs(cidades = cadastro$estacao, variavel = "temperatura_c", janela = as.numeric(range(t)), comuns = TRUE, automatico = FALSE)
  session$flushReact()
  session$setInputs(atualizar = 1)
  session$flushReact()
}, session = sessao)
stopifnot(length(mensagens) > 0)
m <- tail(mensagens, 1)[[1]]
if (!identical(m[["time-format"]], "%d/%m %H:%M") || !identical(m$timezone, "-0300")) stop("RED: hora nova deve preservar formato curto e fuso no controle temporal")
cat("Controle temporal: nova hora preserva rótulos curtos e fuso de Brasília.\n")
