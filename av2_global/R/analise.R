pasta_modulo <- if (exists("raiz_global")) file.path(raiz_global, "R") else {
  arquivos_fonte <- Filter(Negate(is.null), lapply(sys.frames(), function(quadro) quadro$ofile))
  dirname(normalizePath(tail(arquivos_fonte, 1)[[1]], winslash = "/"))
}
raiz_projeto <- dirname(dirname(pasta_modulo))
# Mantém os mesmos cálculos testados em módulos próprios, sem depender da versão SIMEPAR.
source(file.path(pasta_modulo, "estatistica.R"), local = TRUE, encoding = "UTF-8")
source(file.path(pasta_modulo, "graficos.R"), local = TRUE, encoding = "UTF-8")
cores_av2 <- setNames(unname(cores_av2), c("São Paulo", "Guarulhos", "Campinas", "São José dos Campos", "Guarujá"))
pontos_av2 <- setNames(c(16, 17, 15, 18, 8), names(cores_av2))
simbolos_av2 <- setNames(c("●", "▲", "■", "◆", "✳"), names(cores_av2))
rotulos_av2[["umidade_pct"]] <- "Umidade relativa derivada (%)"

preparar_analise_global <- function(dados, cidades, inicio, fim, comuns = TRUE, variavel = "temperatura_c") {
  # Compara instantes absolutos; mudar o fuso de exibição não muda o recorte.
  segundos <- as.numeric(dados$instante)
  serie <- dados[dados$estacao %in% cidades & segundos >= as.numeric(inicio) & segundos <= as.numeric(fim), , drop = FALSE]
  comparaveis <- if (comuns) selecionar_horarios_comuns(serie, cidades) else {
    serie[complete.cases(serie[c("temperatura_c", "umidade_pct", "vento_kmh")]), , drop = FALSE]
  }
  grupos <- c(list("Conjunto selecionado" = comparaveis), split(comparaveis, comparaveis$estacao))
  correlacoes <- do.call(rbind, lapply(names(grupos), function(nome) {
    g <- grupos[[nome]]
    data.frame(Estação = nome, Pares = nrow(g), Spearman = correlacao_segura(g$temperatura_c, g$umidade_pct), check.names = FALSE)
  }))
  list(serie = serie, comparaveis = comparaveis,
       resumo = preparar_comparacao(comparaveis, variavel),
       turnos = preparar_turnos_visuais(serie, cidades, variavel), correlacoes = correlacoes)
}

preparar_turnos_visuais <- function(dados, cidades, variavel) {
  turnos <- c("Madrugada", "Manhã", "Tarde", "Noite")
  grade <- expand.grid(estacao = cidades, turno = turnos, stringsAsFactors = FALSE)
  resumo <- resumir_turnos(dados, variavel)
  resumo$turno <- as.character(resumo$turno)
  # Usa as horas disponíveis da variável, não a interseção entre cidades.
  z <- merge(grade, resumo, by = c("estacao", "turno"), all.x = TRUE, sort = FALSE)
  z$n[is.na(z$n)] <- 0L
  z$turno <- factor(z$turno, levels = turnos, ordered = TRUE)
  z$.x <- as.numeric(z$turno)
  z$.y <- z$media
  z[order(match(z$estacao, cidades), z$.x), ]
}

preparar_serie_visual <- function(dados, variavel, diaria = TRUE) {
  if (!diaria) {
    dados$.x <- as.numeric(dados$instante)
    dados$.y <- dados[[variavel]]
    dados$n <- as.integer(is.finite(dados$.y))
    dados$minimo <- dados$maximo <- dados$.y
    return(dados)
  }
  dias <- format(dados$instante, "%Y-%m-%d", tz = "America/Sao_Paulo")
  grupos <- split(seq_len(nrow(dados)), paste(dados$estacao, dias, sep = "|"))
  linhas <- lapply(grupos, function(i) {
    x <- dados[[variavel]][i]
    x <- x[is.finite(x)]
    data.frame(estacao = dados$estacao[i[1]], instante = as.POSIXct(paste(dias[i[1]], "00:00:00"), tz = "America/Sao_Paulo"),
      n = length(x), .y = if (length(x)) mean(x) else NA_real_,
      minimo = if (length(x)) min(x) else NA_real_, maximo = if (length(x)) max(x) else NA_real_)
  })
  z <- do.call(rbind, linhas)
  z$.x <- as.numeric(z$instante)
  rownames(z) <- NULL
  z[order(z$instante, z$estacao), ]
}

# Células de 1 °C × 5 pontos percentuais; n conserva a amostra, sem jitter.
preparar_frequencias <- function(dados) {
  vazio <- data.frame(n = integer(), t_min = numeric(), t_max = numeric(),
    u_min = numeric(), u_max = numeric(), cidades = character(), .x = numeric(), .y = numeric())
  z <- dados[is.finite(dados$temperatura_c) & is.finite(dados$umidade_pct) &
    dados$umidade_pct >= 0 & dados$umidade_pct <= 100, , drop = FALSE]
  if (!nrow(z)) return(vazio)
  z$t <- floor(z$temperatura_c)
  z$u <- pmin(95, floor(z$umidade_pct / 5) * 5)
  grupos <- split(z, paste(z$t, z$u, sep = "|"))
  do.call(rbind, lapply(grupos, function(g) data.frame(n = nrow(g),
    t_min = g$t[1], t_max = g$t[1] + 1, u_min = g$u[1], u_max = g$u[1] + 5,
    cidades = paste(sort(unique(g$estacao)), collapse = ", "), .x = g$t[1] + 0.5, .y = g$u[1] + 2.5)))
}

situacao_estacoes <- function(dados, cidades, agora = Sys.time()) {
  do.call(rbind, lapply(cidades, function(cidade) {
    z <- dados[dados$estacao == cidade, , drop = FALSE]
    observado <- if (nrow(z)) max(z$observado_em) else as.POSIXct(NA, tz = "UTC")
    idade <- as.numeric(difftime(agora, observado, units = "mins"))
    status <- if (is.na(idade)) "Sem boletim" else if (idade < -5) "Horário futuro" else if (idade <= 120) "Recente" else "Boletim antigo"
    data.frame(estacao = cidade, observado_em = observado, atraso_min = idade, status = status)
  }))
}
