cores_av2 <- c("São Paulo" = "#1465C0", "Guarulhos" = "#C25708", "Campinas" = "#00835B", "São José dos Campos" = "#7950B3", "Guarujá" = "#B51D58")
# Cada estação também tem um símbolo: a leitura não depende apenas da cor.
pontos_av2 <- setNames(c(16, 17, 15, 18, 8), names(cores_av2))
simbolos_av2 <- setNames(c("●", "▲", "■", "◆", "✳"), names(cores_av2))
rotulos_av2 <- c(temperatura_c = "Temperatura (°C)", umidade_pct = "Umidade relativa (%)", vento_kmh = "Vento (km/h)")

limites_av2 <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(c(0, 1))
  limites <- range(x)
  margem <- max(diff(limites) * 0.08, 0.5)
  limites + c(-margem, margem)
}

preparar_comparacao <- function(dados, variavel) {
  resumo <- resumir_estacoes(dados, variavel)
  resumo <- resumo[order(resumo$mediana, resumo$estacao), ]
  resumo$.x <- resumo$mediana
  resumo$.y <- seq_len(nrow(resumo))
  resumo
}

estilo_grafico <- function(esquerda = 4.2) {
  par(mar = c(4.2, esquerda, 1, 1), mgp = c(2.6, 0.7, 0), las = 1,
      col.axis = "#43556c", col.lab = "#182b43", fg = "#a9b8ca", bg = "white", family = "sans", cex = 0.95)
}

plotar_serie <- function(dados, cidades, variavel, diaria = FALSE) {
  estilo_grafico()
  visual <- preparar_serie_visual(dados, variavel, diaria)
  grade <- if (diaria) {
    # Completa apenas o eixo: dias sem leitura continuam NA, não zero.
    dias <- seq(min(visual$instante), max(visual$instante), by = "day")
    g <- expand.grid(estacao = cidades, instante = dias, stringsAsFactors = FALSE)
    v <- visual[c("estacao", "instante", ".y")]; names(v)[3] <- "valor"
    merge(g, v, by = c("estacao", "instante"), all.x = TRUE)
  } else montar_grade(dados, cidades, variavel)
  x <- as.numeric(grade$instante)
  plot(x, grade$valor, type = "n", xaxt = "n", xlab = "Horário local · Brasília", ylab = rotulos_av2[[variavel]],
       xlim = limites_av2(x), ylim = limites_av2(grade$valor), bty = "n")
  abline(h = axTicks(2), col = "#edf0f3", lwd = 0.8)
  # As marcas usam horas da própria grade, sem arredondar segundos do relógio.
  horarios <- sort(unique(grade$instante))
  posicoes <- unique(round(seq(1, length(horarios), length.out = min(5, length(horarios)))))
  marcas <- as.numeric(horarios[posicoes])
  axis(1, at = marcas, labels = format(as.POSIXct(marcas, origin = "1970-01-01", tz = "America/Sao_Paulo"), "%d/%m\n%H:%M"), cex.axis = 0.8)
  for (cidade in cidades) {
    z <- grade[grade$estacao == cidade, ]
    z <- z[order(z$instante), ]
    lines(as.numeric(z$instante), z$valor, col = cores_av2[[cidade]], lwd = 2)
    points(as.numeric(z$instante), z$valor, col = cores_av2[[cidade]], pch = pontos_av2[[cidade]], cex = if (diaria) 0.85 else 0.45)
  }
  invisible(visual)
}

plotar_associacao <- function(dados, frequencias = FALSE) {
  estilo_grafico()
  if (frequencias) {
    z <- preparar_frequencias(dados)
    plot(z$.x, z$.y, type = "n", xlab = "Temperatura (°C)", ylab = "Umidade relativa (%)",
      xlim = limites_av2(c(z$t_min, z$t_max)), ylim = range(c(0, 100)), bty = "n")
    if (nrow(z)) {
      intensidade <- (log1p(z$n) / log1p(max(z$n)))
      paleta <- colorRampPalette(c("#edf3fa", "#1465C0"))(100)
      rect(z$t_min, z$u_min, z$t_max, z$u_max, col = paleta[pmax(1, ceiling(intensidade * 100))], border = "white")
      # Números só quando cabem na célula; clique/hover informa n em qualquer largura.
      largura_celula <- par("pin")[1] / diff(par("usr")[1:2])
      if (par("pin")[1] > 4.5 && strwidth(as.character(max(z$n)), units = "inches", cex = 0.7) < largura_celula * 0.9)
        text(z$.x, z$.y, labels = z$n, cex = 0.7, col = ifelse(intensidade > 0.55, "white", "#182b43"))
      chave <- unique(c(1L, round(sqrt(max(z$n))), max(z$n)))
      legend("topright", legend = paste("n =", chave), fill = paleta[pmax(1, ceiling(log1p(chave) / log1p(max(z$n)) * 100))],
        border = NA, bty = "n", cex = 0.75, inset = 0.04, text.col = "#182b43")
    }
    return(invisible(z))
  }
  plot(dados$temperatura_c, dados$umidade_pct, type = "n", xlab = "Temperatura (°C)", ylab = "Umidade relativa (%)",
       xlim = limites_av2(dados$temperatura_c), ylim = limites_av2(dados$umidade_pct), bty = "n")
  abline(h = axTicks(2), v = axTicks(1), col = "#edf0f3", lwd = 0.8)
  points(dados$temperatura_c, dados$umidade_pct, col = adjustcolor(cores_av2[dados$estacao], alpha.f = 0.35), pch = pontos_av2[dados$estacao], cex = 0.6)
  invisible(dados)
}

plotar_comparacao <- function(resumo, variavel) {
  estilo_grafico(esquerda = 8.5)
  plot(resumo$mediana, resumo$.y, type = "n", xlab = rotulos_av2[[variavel]], ylab = "", yaxt = "n",
       xlim = limites_av2(c(resumo$minimo, resumo$maximo)), ylim = c(0.5, nrow(resumo) + 0.5), bty = "n")
  abline(v = axTicks(1), col = "#edf0f3", lwd = 0.8)
  axis(2, at = resumo$.y, labels = resumo$estacao, tick = FALSE, cex.axis = 0.85)
  segments(resumo$minimo, resumo$.y, resumo$maximo, resumo$.y, col = "#a9b1bc", lwd = 1.1)
  segments(resumo$q1, resumo$.y, resumo$q3, resumo$.y, col = cores_av2[resumo$estacao], lwd = 5)
  points(resumo$mediana, resumo$.y, col = cores_av2[resumo$estacao], pch = pontos_av2[resumo$estacao], cex = 1.25)
}

plotar_turnos <- function(resumo, variavel) {
  # Quadro de valores: não sobrepõe cidades nem deixa ausência invisível.
  estilo_grafico(esquerda = 6.2)
  cidades <- unique(resumo$estacao[order(resumo$.y)])
  plot(NA, xlim = c(0.5, 4.5), ylim = c(0.5, length(cidades) + 0.5),
    xaxt = "n", yaxt = "n", xlab = "Turno · Brasília", ylab = "", bty = "n")
  axis(1, at = 1:4, labels = c("Madr.\n00–05h", "Manhã\n06–11h", "Tarde\n12–17h", "Noite\n18–23h"), cex.axis = 0.75, gap.axis = -1)
  nomes <- c("São Paulo" = "S. Paulo", "São José dos Campos" = "S. J. Campos")
  rotulos <- ifelse(cidades %in% names(nomes), nomes[cidades], cidades)
  axis(2, at = seq_along(cidades), labels = rotulos, tick = FALSE, cex.axis = 0.75)
  rect(resumo$.x - 0.48, resumo$.y - 0.46, resumo$.x + 0.48, resumo$.y + 0.46,
    col = ifelse(resumo$n == 0, "#f1f1f1", adjustcolor(cores_av2[resumo$estacao], alpha.f = 0.12)), border = "white")
  rotulos <- ifelse(resumo$n == 0, "Sem obs.\nn=0", paste0(formatC(resumo$media, format = "f", digits = 1, decimal.mark = ","), "\nn=", resumo$n))
  text(resumo$.x, resumo$.y, rotulos, cex = 0.73, col = "#182b43")
  invisible(resumo)
}
