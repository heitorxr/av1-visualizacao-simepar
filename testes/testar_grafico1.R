# Regressao: o grafico temporal deve mostrar todas as medicoes publicadas.
args <- commandArgs(TRUE)
raiz <- normalizePath(if (length(args)) args[1] else getwd(), winslash = "/")
ambiente <- new.env(parent = globalenv())
ambiente$raiz <- raiz
# Carrega objetos e funcoes sem executar a exportacao final do script.
for (expressao in parse(file.path(raiz, "R", "03_visualizar.R"), encoding = "UTF-8")) {
  if (is.call(expressao) && identical(expressao[[1]], as.name("cairo_pdf"))) break
  eval(expressao, ambiente)
}
painel_atual <- 0L
medicoes <- numeric()
ambiente$plot <- function(...) {
  painel_atual <<- painel_atual + 1L
  graphics::plot(...)
}
ambiente$points <- function(x, y, ...) {
  if (painel_atual == 1L) medicoes <<- c(medicoes, y[is.finite(y)])
  graphics::points(x, y, ...)
}
# O dispositivo e nulo: testa o desenho sem substituir o PDF do trabalho.
grDevices::pdf(NULL)
tryCatch(ambiente$frente(), finally = grDevices::dev.off())
publicadas <- ambiente$obj$dados$temperatura_c
stopifnot(length(publicadas) == 122L)
if (length(medicoes) != length(publicadas)) {
  stop(sprintf("Grafico 1 desenhou %d medicoes; deve preservar as %d temperaturas publicadas.",
               length(medicoes), length(publicadas)))
}
stopifnot(isTRUE(all.equal(sort(medicoes), sort(publicadas))))
cat("OK: grafico 1 preserva as 122 temperaturas publicadas.\n")
