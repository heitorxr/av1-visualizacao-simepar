arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), winslash = "/")
if (!file.exists(file.path(raiz, "app.R"))) stop("RED: aplicativo global ainda não existe")
.libPaths(c(file.path(dirname(raiz), ".biblioteca"), .libPaths()))
app <- source(file.path(raiz, "app.R"), encoding = "UTF-8")$value
stopifnot(inherits(app, "shiny.appobj"), file.exists(file.path(raiz, "iniciar.R")))
parse(file.path(raiz, "iniciar.R"))
cat("Inicialização: aplicativo real criado a partir da base inicial e lançador válido.\n")
