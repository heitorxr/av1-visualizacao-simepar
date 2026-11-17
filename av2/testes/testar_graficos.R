arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz_av2 <- dirname(dirname(normalizePath(sub("^--file=", "", arquivo[[1]]), winslash = "/")))
raiz <- dirname(raiz_av2)
env <- new.env()
source(file.path(raiz_av2, "R", "analise.R"), local = env, encoding = "UTF-8")
source(file.path(raiz_av2, "R", "graficos.R"), local = env, encoding = "UTF-8")
dados <- read.csv(file.path(raiz, "dados/entrada/dados_publicados.csv"))
dados$instante <- as.POSIXct(dados$datahora, format = "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")

verificar_graficos <- function() {
  destino <- tempfile("av2-graficos-", fileext = ".png")
  png(destino, width = 1000, height = 600, type = "cairo")
  aberto <- TRUE
  on.exit({ if (aberto) dev.off(); unlink(destino) }, add = TRUE)
  marcas <- numeric()
  env$axis <- function(side, at, ...) {
    if (side == 1) marcas <<- at
    graphics::axis(side, at = at, ...)
  }
  env$plotar_serie(dados, unique(dados$estacao), "temperatura_c")
  # A fonte é horária: o eixo não deve inventar marcas como 20h20 ou 01h53.
  stopifnot(length(marcas) >= 2L, all(marcas %% 3600 == 0))
  rm("axis", envir = env)
  comuns <- env$selecionar_horarios_comuns(dados, unique(dados$estacao))
  env$plotar_associacao(comuns)
  env$plotar_comparacao(env$preparar_comparacao(comuns, "vento_kmh"), "vento_kmh")
  env$plotar_turnos(env$resumir_turnos(comuns, "temperatura_c"), "temperatura_c")
  dev.off()
  aberto <- FALSE
  stopifnot(file.info(destino)$size > 0)
}
verificar_graficos()
cat("OK: quatro gráficos executados e marcas temporais compatíveis com a grade horária.\n")
