# Os filtros retornam novas tabelas; a coleta original não é modificada.
recortar_dados <- function(dados, cidades, inicio, fim) {
  dados[dados$estacao %in% cidades & dados$instante >= inicio & dados$instante <= fim, , drop = FALSE]
}

selecionar_horarios_comuns <- function(dados, cidades) {
  variaveis <- c("temperatura_c", "umidade_pct", "vento_kmh")
  completos <- dados[complete.cases(dados[variaveis]) & dados$estacao %in% cidades, , drop = FALSE]
  if (!length(cidades) || !nrow(completos)) return(completos[FALSE, , drop = FALSE])
  contagens <- table(completos$datahora)
  horarios <- names(contagens)[contagens == length(cidades)]
  completos[completos$datahora %in% horarios, , drop = FALSE]
}

montar_grade <- function(dados, cidades, variavel) {
  if (!nrow(dados)) return(data.frame(estacao = character(), instante = as.POSIXct(character()), valor = numeric()))
  grade <- expand.grid(estacao = cidades, instante = seq(min(dados$instante), max(dados$instante), by = "hour"), stringsAsFactors = FALSE)
  valores <- dados[c("estacao", "instante", variavel)]
  names(valores)[[3]] <- "valor"
  # O merge deixa NA onde não houve medida; as linhas dos gráficos param nesses pontos.
  merge(grade, valores, by = c("estacao", "instante"), all.x = TRUE, sort = TRUE)
}

correlacao_segura <- function(x, y) {
  validos <- is.finite(x) & is.finite(y)
  x <- x[validos]
  y <- y[validos]
  if (length(x) < 3L || length(unique(x)) < 2L || length(unique(y)) < 2L) return(NA_real_)
  cor(x, y, method = "spearman")
}

resumir_estacoes <- function(dados, variavel) {
  vazio <- data.frame(estacao = character(), n = integer(), minimo = numeric(), q1 = numeric(), mediana = numeric(), media = numeric(), q3 = numeric(), maximo = numeric())
  if (!nrow(dados)) return(vazio)
  linhas <- lapply(split(dados, dados$estacao), function(grupo) {
    x <- grupo[[variavel]][is.finite(grupo[[variavel]])]
    if (!length(x)) return(NULL)
    q <- quantile(x, c(0.25, 0.5, 0.75), names = FALSE, type = 7)
    data.frame(estacao = grupo$estacao[[1]], n = length(x), minimo = min(x), q1 = q[[1]], mediana = q[[2]], media = mean(x), q3 = q[[3]], maximo = max(x))
  })
  linhas <- Filter(Negate(is.null), linhas)
  if (!length(linhas)) return(vazio)
  resultado <- do.call(rbind, linhas)
  rownames(resultado) <- NULL
  resultado
}

resumir_turnos <- function(dados, variavel) {
  if (!nrow(dados)) return(data.frame(estacao = character(), turno = character(), n = integer(), media = numeric()))
  # Turno é uma categoria derivada da hora local, não uma medida da estação.
  turnos <- c("Madrugada", "Manhã", "Tarde", "Noite")
  hora <- as.integer(format(dados$instante, "%H", tz = "America/Sao_Paulo"))
  dados$turno <- turnos[hora %/% 6L + 1L]
  grupos <- split(dados, interaction(dados$estacao, dados$turno, drop = TRUE))
  resultado <- do.call(rbind, lapply(grupos, function(grupo) {
    x <- grupo[[variavel]][is.finite(grupo[[variavel]])]
    data.frame(estacao = grupo$estacao[[1]], turno = grupo$turno[[1]], n = length(x), media = if (length(x)) mean(x) else NA_real_)
  }))
  rownames(resultado) <- NULL
  resultado$turno <- factor(resultado$turno, levels = turnos, ordered = TRUE)
  resultado[order(resultado$estacao, resultado$turno), ]
}
