# Confere que os trechos impressos sao expressoes reais dos scripts executados.
argumento <- grep("^--file=", commandArgs(), value = TRUE)
raiz <- dirname(dirname(normalizePath(sub("^--file=", "", argumento[1]), winslash = "/")))
ambiente <- new.env()
ambiente$raiz <- raiz
visualizacao <- parse(file.path(raiz, "R", "03_visualizar.R"), keep.source = FALSE)
for (expressao in visualizacao) {
  if (is.call(expressao) && identical(expressao[[1]], as.name("cairo_pdf"))) break
  eval(expressao, envir = ambiente)
}
linhas <- ambiente$secoes_verso[[3]]$linhas
stopifnot(!any(grepl("...", linhas, fixed = TRUE)))
impressos <- parse(text = linhas, keep.source = FALSE)
originais <- c(as.list(parse(file.path(raiz, "R", "02_analisar.R"), keep.source = FALSE)),
               as.list(visualizacao))
stopifnot(length(impressos) == 4L)
for (expressao in impressos) {
  stopifnot(any(vapply(originais, function(original) identical(expressao, original), logical(1))))
}
message("OK: quatro expressoes do verso correspondem ao codigo real, sem placeholders.")
