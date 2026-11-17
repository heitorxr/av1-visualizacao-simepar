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

plotar_serie <- function(dados, cidades, variavel) {
  estilo_grafico()
  grade <- montar_grade(dados, cidades, variavel)
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
    points(as.numeric(z$instante), z$valor, col = cores_av2[[cidade]], pch = pontos_av2[[cidade]], cex = 0.85)
  }
}

plotar_associacao <- function(dados) {
  estilo_grafico()
  plot(dados$temperatura_c, dados$umidade_pct, type = "n", xlab = "Temperatura (°C)", ylab = "Umidade relativa (%)",
       xlim = limites_av2(dados$temperatura_c), ylim = limites_av2(dados$umidade_pct), bty = "n")
  abline(h = axTicks(2), v = axTicks(1), col = "#edf0f3", lwd = 0.8)
  points(dados$temperatura_c, dados$umidade_pct, col = cores_av2[dados$estacao], pch = pontos_av2[dados$estacao], cex = 0.95)
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
  estilo_grafico()
  plot(as.numeric(resumo$turno), resumo$media, type = "n", xaxt = "n", xlab = "Turno derivado da hora local",
       ylab = rotulos_av2[[variavel]], xlim = c(0.8, 4.2), ylim = limites_av2(resumo$media), bty = "n")
  abline(h = axTicks(2), col = "#edf0f3", lwd = 0.8)
  axis(1, at = 1:4, labels = c("Madrugada", "Manhã", "Tarde", "Noite"), cex.axis = 0.8)
  for (cidade in unique(resumo$estacao)) {
    z <- resumo[resumo$estacao == cidade, ]
    z <- z[order(z$turno), ]
    lines(as.numeric(z$turno), z$media, col = cores_av2[[cidade]], lwd = 2)
    points(as.numeric(z$turno), z$media, col = cores_av2[[cidade]], pch = pontos_av2[[cidade]], cex = 1.05)
  }
}
