arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz_av2 <- dirname(dirname(normalizePath(sub("^--file=", "", arquivo[[1]]), winslash = "/")))
raiz <- dirname(raiz_av2)
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
options(av2.coleta_automatica = FALSE)
# Carrega as definições, sem abrir navegador ou iniciar servidor HTTP.
anterior <- getwd()
setwd(raiz_av2)

ambiente <- new.env()
app <- source("app.R", local = ambiente, encoding = "UTF-8")$value
setwd(anterior)

# Uma sessão real inicia o servidor antes de existir um contexto reativo.
sessao <- shiny::MockShinySession$new()
tryCatch(shiny::withReactiveDomain(sessao, {
  ambiente$criar_servidor(raiz, buscar = function() stop("Sem rede neste teste"))(
    input = sessao$input, output = sessao$output, session = sessao)
}), finally = sessao$close())

shiny::testServer(ambiente$criar_servidor(raiz, buscar = function() stop("Falha de rede de teste")), {
  session$setInputs(cidades = names(ambiente$cores_av2), variavel = "temperatura_c", comuns = TRUE,
    janela = range(ambiente$base_inicial$dados$instante), automatico = FALSE, atualizar = 0)
  session$flushReact()
  stopifnot(nrow(recorte()) == 122L, nrow(comparaveis()) == 110L)
  stopifnot(grepl("observações na série temporal", output$metricas$html, fixed = TRUE))
  session$setInputs(cidades = "Curitiba")
  session$flushReact()
  stopifnot(nrow(recorte()) == 25L, nrow(comparaveis()) == 25L)
  antes <- base()$dados
  session$setInputs(atualizar = 1)
  session$flushReact()
  stopifnot(identical(base()$dados, antes), grepl("Falha de rede de teste", base()$erro))
})
cat("OK: filtros reativos e falha de atualização sem perda dos dados.\n")
