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
       turnos = resumir_turnos(comparaveis, variavel), correlacoes = correlacoes)
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
