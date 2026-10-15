# Verificacoes reproduziveis da coleta congelada, calculos e artefatos.
obj <- readRDS(file.path(raiz, "resultados", "analise.rds"))
a <- obj$analise
fontes <- read.csv(file.path(raiz, "dados", "entrada", "fontes.csv"), fileEncoding = "UTF-8")
checks <- character()
checar <- function(condicao, descricao) {
  if (!isTRUE(condicao)) stop("FALHOU: ", descricao)
  checks <<- c(checks, paste("OK:", descricao))
}
checar(nrow(a) >= 80L, "minimo de 80 observacoes")
checar(all(vapply(a[c("temperatura_c", "umidade_pct", "vento_kmh")], is.numeric, logical(1))),
       "tres variaveis quantitativas")
checar(length(unique(a$estacao)) == 5L && nlevels(a$turno) == 4L,
       "duas categorias: estacao e turno (derivado)")
checar(!anyDuplicated(a[c("estacao_id", "instante")]), "nenhum par estacao-horario duplicado")
checar(all(is.finite(as.matrix(a[c("temperatura_c", "umidade_pct", "vento_kmh")]))),
       "medidas analisadas finitas")
checar(all(table(a$instante) == 5L), "cinco estacoes em cada horario analisado")
checar(length(unique(table(a$estacao))) == 1L, "mesmo peso temporal por estacao")
checar(nrow(obj$dados) == 122L && nrow(a) == 110L,
       "snapshot congelado: 122 registros publicados e 110 analisados")
checar(sum(obj$auditoria$motivo == "sem as tres medidas publicadas") == 3L &&
         sum(obj$auditoria$motivo == "fora dos horarios comuns") == 12L,
       "tres lacunas de publicacao e doze exclusoes para comparacao comum")
checar(all(obj$grade$temperatura_c[!complete.cases(obj$grade[c("temperatura_c", "umidade_pct", "vento_kmh")])] |> is.na()),
       "grade mantem NA nas lacunas")
checar(nrow(obj$grade) == 125L && sum(is.na(obj$grade$temperatura_c)) == 15L,
       "grade comparativa registra as quinze posicoes fora dos horarios comuns")
for (i in seq_len(nrow(fontes))) {
  arquivo <- file.path(raiz, fontes$arquivo[i])
  checar(unname(tools::md5sum(arquivo)) == fontes$md5[i],
         paste("HTML original preservado:", fontes$estacao[i]))
}
# Reextracao independente para conferir cada valor do CSV com o HTML congelado.
checar(requireNamespace("jsonlite", quietly = TRUE), "jsonlite disponivel para auditar a fonte")
mapa <- c("Temperatura Média" = "temperatura_c", "Umidade Relativa" = "umidade_pct",
          "Velocidade do Vento" = "vento_kmh")
for (i in seq_len(nrow(fontes))) {
  html <- paste(readLines(file.path(raiz, fontes$arquivo[i]), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  for (nome in names(mapa)) {
    padrao <- paste0("name:\\s*'", nome, "'[\\s\\S]*?data:\\s*(\\[\\[[\\s\\S]*?\\]\\])")
    trecho <- regmatches(html, regexec(padrao, html, perl = TRUE))[[1]][2]
    original <- jsonlite::fromJSON(trecho, simplifyVector = FALSE)
    x <- obj$dados[obj$dados$estacao == fontes$estacao[i], ]
    for (par in original) {
      valor <- x[[mapa[[nome]]]][match(par[[1]], x$datahora)]
      esperado <- if (is.null(par[[2]])) NA_real_ else as.numeric(par[[2]])
      checar(isTRUE(all.equal(valor, esperado, check.attributes = FALSE)),
             paste("fonte", fontes$estacao[i], nome, par[[1]]))
    }
  }
}
for (cidade in unique(a$estacao)) {
  x <- a[a$estacao == cidade, ]
  r <- obj$resumo[obj$resumo$estacao == cidade, ]
  checar(isTRUE(all.equal(r$amplitude_c, max(x$temperatura_c) - min(x$temperatura_c))),
         paste("amplitude:", cidade))
  checar(isTRUE(all.equal(r$vento_medio, mean(x$vento_kmh))), paste("vento medio:", cidade))
  z <- obj$por_turno[obj$por_turno$estacao == cidade, ]
  checar(as.character(z$turno[which.max(z$temperatura_c)]) == "Tarde",
         paste("titulo do grafico 4 confirmado:", cidade))
}
for (nome in c("AV1_frente_verso_A4.pdf", "AV1_frente.png", "AV1_verso.png")) {
  arquivo <- file.path(raiz, "resultados", nome)
  checar(file.exists(arquivo) && file.info(arquivo)$size > 1000,
         paste("artefato nao vazio:", nome))
}
writeLines(c(paste("Verificacoes aprovadas:", length(checks)), checks),
           file.path(raiz, "resultados", "verificacoes.txt"), useBytes = TRUE)
message("Todas as ", length(checks), " verificacoes passaram.")
