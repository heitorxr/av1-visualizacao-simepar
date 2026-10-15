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
ligacoes <- list()
ambiente$plot <- function(...) {
  painel_atual <<- painel_atual + 1L
  graphics::plot(...)
}
ambiente$points <- function(x, y, ...) {
  if (painel_atual == 1L) medicoes <<- c(medicoes, y[is.finite(y)])
  graphics::points(x, y, ...)
}
ambiente$segments <- function(x0, y0, x1, y1, ...) {
  estilo <- list(...)
  if (painel_atual == 1L) {
    ligacoes[[length(ligacoes) + 1L]] <<- data.frame(
      x0 = x0, y0 = y0, x1 = x1, y1 = y1,
      lty = rep_len(estilo$lty, length(x0)),
      cor = rep_len(estilo$col, length(x0))
    )
  }
  graphics::segments(x0, y0, x1, y1, ...)
}
# Usa o mesmo dispositivo Cairo da entrega, sem substituir o PDF do trabalho.
scratch <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("LOCALAPPDATA"), "hermes", "cache", "scratch")
} else tempdir()
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
previa <- tempfile("teste_grafico1_", tmpdir = scratch, fileext = ".pdf")
grDevices::cairo_pdf(previa, width = 210 / 25.4, height = 297 / 25.4)
tryCatch(ambiente$frente(), finally = {
  grDevices::dev.off()
  unlink(previa)
})
publicadas <- ambiente$obj$dados$temperatura_c
stopifnot(length(publicadas) == 122L)
if (length(medicoes) != length(publicadas)) {
  stop(sprintf("Grafico 1 desenhou %d medicoes; deve preservar as %d temperaturas publicadas.",
               length(medicoes), length(publicadas)))
}
stopifnot(isTRUE(all.equal(sort(medicoes), sort(publicadas))))
trechos <- do.call(rbind, ligacoes)
stopifnot(sum(trechos$lty == 2) == 3L,
          all(trechos$cor[trechos$lty == 2] == ambiente$cores[["Maringá"]]),
          all((trechos$x1 - trechos$x0 > 1) == (trechos$lty == 2)))
cat("OK: grafico 1 preserva as 122 temperaturas publicadas.\n")
cat("OK: somente os tres intervalos ausentes de Maringa sao tracejados.\n")
