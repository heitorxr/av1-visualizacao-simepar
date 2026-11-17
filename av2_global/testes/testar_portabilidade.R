local({
  script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
  raiz <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
  .libPaths(c(file.path(dirname(raiz), ".biblioteca"), .libPaths()))
  copia <- tempfile("global-portavel-")
  dir.create(copia)
  on.exit(unlink(copia, recursive = TRUE), add = TRUE)
  arquivos <- list.files(raiz, recursive = TRUE, all.files = TRUE, full.names = FALSE, no.. = TRUE)
  arquivos <- arquivos[!grepl("^(cache/|dados/coletas/)", arquivos)]
  for (nome in arquivos) {
    destino <- file.path(copia, nome)
    dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(file.path(raiz, nome), destino))
  }
  anterior <- getwd()
  on.exit(setwd(anterior), add = TRUE)
  setwd(copia)
  env <- new.env(parent = globalenv())
  app <- source(file.path(copia, "app.R"), local = env, encoding = "UTF-8")$value
  stopifnot(inherits(app, "shiny.appobj"), file.exists(file.path(copia, "estilo.css")), nrow(env$inicial_global$dados) > 0)
  cat("Portabilidade: somente av2_global basta; sem arquivos da versão SIMEPAR.\n")
})
