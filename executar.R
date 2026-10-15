# Entrada do projeto: Rscript executar.R coletar|analisar|renderizar|verificar|tudo
arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz <- if (length(arquivo)) {
  dirname(normalizePath(sub("^--file=", "", arquivo[1]), winslash = "/"))
} else {
  normalizePath(getwd(), winslash = "/")
}
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
options(stringsAsFactors = FALSE, timeout = 90)
acao <- commandArgs(TRUE)
if (!length(acao)) acao <- "tudo"
rotas <- c(coletar = "01_coletar.R", analisar = "02_analisar.R",
           renderizar = "03_visualizar.R", verificar = "04_verificar.R")
if (!acao[1] %in% c(names(rotas), "tudo")) stop("Acao desconhecida.")
# 'tudo' reproduz a coleta congelada, sem acessar nem substituir a fonte.
etapas <- if (acao[1] == "tudo") names(rotas)[-1] else acao[1]
for (etapa in etapas) {
  message("Etapa: ", etapa)
  source(file.path(raiz, "R", rotas[[etapa]]), encoding = "UTF-8")
}
