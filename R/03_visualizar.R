# Composicao em R base: PDF vetorial A4 e previas PNG de 180 dpi.
obj <- readRDS(file.path(raiz, "resultados", "analise.rds"))
a <- obj$analise
r <- obj$resumo
saida <- file.path(raiz, "resultados")
cores <- c("Curitiba" = "#0072B2", "Foz do Iguaçu" = "#D55E00", "Londrina" = "#009E73",
           "Maringá" = "#8B5094", "Paranaguá" = "#9A6500")
simbolos <- setNames(c(16, 17, 15, 18, 8), names(cores))
fmt <- function(x, casas = 1) formatC(x, digits = casas, format = "f", decimal.mark = ",")
fonte <- "Arial"

# Coordenadas da pagina em milimetros; o restante usa eixos estatisticos usuais.
pagina <- function() {
  par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0),
      family = fonte, fg = "#243240", col.axis = "#49545F", col.lab = "#243240",
      cex = 1, cex.axis = 0.72, cex.lab = 0.82, mgp = c(1.7, 0.4, 0), tcl = -0.2)
  plot.new()
  plot.window(xlim = c(0, 210), ylim = c(0, 297), xaxs = "i", yaxs = "i")
}
texto <- function(x, y, rotulo, tamanho = 10, cor = "#243240", negrito = FALSE, ...) {
  text(x, y, rotulo, adj = c(0, 0.5), cex = tamanho / 12,
       col = cor, font = if (negrito) 2 else 1, ...)
}
painel <- function(figura, margens = c(2.8, 3, 1.5, 0.7)) {
  par(fig = figura, mar = margens, new = TRUE, xaxs = "i", yaxs = "i")
}
eixos <- function(x, y) {
  axis(1, at = x, col = NA, col.ticks = "#9BA4AD")
  axis(2, at = y, las = 1, col = NA, col.ticks = NA)
}

frente <- function() {
  pagina()
  texto(12, 284, "O mesmo dia, cinco tempos", 23, negrito = TRUE)
  texto(12, 271, "Cinco estações do Paraná | 14/10, 19h a 15/10/2026, 19h", 10.5)
  maior_amplitude <- r[which.max(r$amplitude_c), ]
  maior_vento <- r[which.max(r$vento_medio), ]
  texto(12, 258, paste0(maior_amplitude$estacao, ": maior amplitude térmica (", fmt(maior_amplitude$amplitude_c), " °C)."), 11, negrito = TRUE)
  texto(12, 250, paste0(maior_vento$estacao, ": vento médio mais intenso (", fmt(maior_vento$vento_medio), " km/h)."), 11, negrito = TRUE)
  texto(12, 238, sprintf("%d registros analisados  /  %d horários comuns  /  %d estações",
                         nrow(a), length(unique(a$instante)), nrow(r)), 10, cor = "#596470")
  # A mesma cor e o mesmo simbolo sempre identificam a mesma estacao.
  xpos <- c(12, 47, 97, 131, 165)
  for (i in seq_along(cores)) {
    points(xpos[i], 227, pch = simbolos[i], col = cores[i], cex = 0.7)
    texto(xpos[i] + 3, 227, names(cores)[i], 8.5)
  }
  texto(12, 215, "1  Curitiba começa mais fria e varia mais", 11, negrito = TRUE)
  texto(12, 208, "Temperatura (°C), 122 registros. Tracejado: intervalo sem dado; pontos: medições.", 8.5, cor = "#596470")
  texto(12, 143, "2  Ar mais quente, em geral menos úmido", 10, negrito = TRUE)
  texto(116, 143, "3  O vento separa as estações", 10, negrito = TRUE)
  texto(12, 136, "Um ponto = uma estação em um horário.", 8, cor = "#596470")
  texto(116, 136, "Linha: mínimo–máximo; ponto: média.", 8, cor = "#596470")
  texto(12, 77, "4  Em todas as estações, a tarde é o turno mais quente", 10.5, negrito = TRUE)
  texto(12, 70, "Temperatura média (°C) por turno; cor e número mostram a mesma medida.", 8.5, cor = "#596470")
  texto(12, 16, "Fonte: SIMEPAR, páginas públicas das estações; coleta em 15/10/2026.", 7.7, cor = "#596470")
  texto(12, 10, "G1: 122 registros; G2–G4: 110, nos mesmos 22 horários. Recorte do tempo, não do clima.", 7.7, cor = "#596470")

  # 1. Preserva TODAS as temperaturas publicadas, sem preencher valores ausentes.
  # Ligacoes tracejadas indicam os intervalos sem observacao; nao sao medicoes.
  painel(c(0.04, 0.97, 0.515, 0.697), c(2.4, 3.2, 0.2, 0.6))
  inicio <- min(obj$dados$instante)

  plot(NA, xlim = c(0, 24), ylim = c(14, 28), axes = FALSE, xlab = "", ylab = "")
  abline(h = seq(16, 28, 4), col = "#E8EBEF", lwd = 0.65)
  axis(2, at = seq(16, 28, 4), las = 1, col = NA, col.ticks = NA)
  axis(1, at = c(0, 5, 11, 17, 24), labels = c("14/10 19h", "15/10 00h", "06h", "12h", "19h"), col = NA, col.ticks = "#9BA4AD")
  for (cidade in names(cores)) {
    z <- obj$dados[obj$dados$estacao == cidade & is.finite(obj$dados$temperatura_c), ]
    z <- z[order(z$instante), ]
    h <- as.numeric(difftime(z$instante, inicio, units = "hours"))
    n <- length(h)
    segments(h[-n], z$temperatura_c[-n], h[-1], z$temperatura_c[-1],
             col = cores[cidade], lwd = 1.35, lty = ifelse(diff(h) > 1, 2, 1))
    points(h, z$temperatura_c, col = cores[cidade], pch = simbolos[cidade], cex = 0.36)
  }

  # 2. Dispersao observada; nao ajustamos uma regressao causal.
  painel(c(0.04, 0.525, 0.282, 0.445), c(3, 3.2, 0.1, 0.9))
  plot(NA, xlim = c(14, 28), ylim = c(60, 103), axes = FALSE,
       xlab = "Temperatura (°C)", ylab = "Umidade relativa (%)")
  abline(h = c(60, 80, 100), col = "#E8EBEF", lwd = 0.6)
  eixos(c(16, 20, 24, 28), c(60, 80, 100))
  for (cidade in names(cores)) {
    z <- a[a$estacao == cidade, ]
    points(z$temperatura_c, z$umidade_pct, pch = simbolos[cidade],
           col = adjustcolor(cores[cidade], alpha.f = 0.72), cex = 0.54)
  }

  # 3. Intervalo observado, nao intervalo de confianca nem rajada.
  painel(c(0.52, 0.97, 0.282, 0.445), c(3, 5.1, 0.1, 0.9))
  ord <- order(r$vento_medio)
  z <- r[ord, ]
  plot(NA, xlim = c(0, 17), ylim = c(0.5, 5.5), axes = FALSE,
       xlab = "Velocidade do vento (km/h)", ylab = "")
  abline(v = c(0, 5, 10, 15), col = "#E8EBEF", lwd = 0.6)
  axis(1, at = c(0, 5, 10, 15), col = NA, col.ticks = "#9BA4AD")
  axis(2, at = 1:5, labels = z$estacao, las = 1, col = NA, col.ticks = NA, cex.axis = 0.62)
  segments(z$vento_min, 1:5, z$vento_max, 1:5, col = cores[z$estacao], lwd = 1.8)
  points(z$vento_medio, 1:5, pch = simbolos[z$estacao], col = cores[z$estacao], cex = 0.85)
  text(z$vento_medio, (1:5) + 0.3, labels = fmt(z$vento_medio), cex = 0.65, col = "#243240")

  # 4. Matriz estacao x turno: categorias explicitas, mesma escala de cor.
  painel(c(0.04, 0.97, 0.082, 0.222), c(1.8, 6, 0.1, 0.2))
  cidades <- names(cores)
  turnos <- levels(a$turno)
  plot(NA, xlim = c(0.5, 4.5), ylim = c(0.5, 5.5), axes = FALSE, xlab = "", ylab = "")
  paleta <- colorRampPalette(c("#F0F5F7", "#B4D4DC", "#39879E"))(100)
  for (i in seq_along(cidades)) for (j in seq_along(turnos)) {
    z <- obj$por_turno
    v <- z$temperatura_c[z$estacao == cidades[i] & z$turno == turnos[j]]
    indice <- max(1, min(100, round((v - 15) / (26 - 15) * 99) + 1))
    rect(j - 0.48, 6 - i - 0.46, j + 0.48, 6 - i + 0.46, col = paleta[indice], border = NA)
    text(j, 6 - i, fmt(v), cex = 0.78, col = "#132C38")
  }
  axis(2, at = 5:1, labels = cidades, las = 1, col = NA, col.ticks = NA, cex.axis = 0.72)
  n_turnos <- table(a$turno) / length(cidades)
  axis(1, at = 1:4, labels = paste0(turnos, " (n=", n_turnos, ")"),
       col = NA, col.ticks = NA, cex.axis = 0.7)
}

# Verso na mesma folha; identificacao fica em branco para preenchimento manual.
verso <- function() {
  pagina()
  texto(14, 282, "Construção da visualização", 21, negrito = TRUE)
  texto(14, 269, "CE303 — AV1 | UFPR | 2026.2", 10)
  texto(14, 256, "Nome completo: __________________________________________________", 11)
  bloco <- function(y, titulo, linhas) {
    texto(14, y, titulo, 12, negrito = TRUE)
    for (i in seq_along(linhas)) texto(14, y - 8 - (i - 1) * 5.2, linhas[i], 9.3)
  }
  bloco(242, "Base de dados e recorte", c(
    "Uma observação corresponde a uma estação em um horário publicado.",
    sprintf("A coleta contém %d registros; a grade completa teria %d (5 estações x 25 horários).", nrow(obj$dados), nrow(obj$auditoria)),
    "Maringá não publicou três horários do recorte. Para comparar as cidades na mesma",
    sprintf("base temporal, foram usados %d horários comuns: %d observações, sem interpolação.", length(unique(a$instante)), nrow(a)),
    "Período: 14/10/2026, 19h a 15/10/2026, 19h, com os dois extremos incluídos.",
    "Adotou-se o horário de Brasília; a página não explicita o fuso dos registros."
  ))
  bloco(194, "Variáveis e organização", c(
    "Quantitativas: temperatura média do ar (°C), umidade relativa (%) e vento (km/h).",
    "Qualitativas: estação (original) e turno do dia (categoria derivada do horário).",
    "Turnos: madrugada 00–05h; manhã 06–11h; tarde 12–17h; noite 18–23h.",
    "Horas de uma mesma estação são dependentes; a análise é somente descritiva.",
    "As médias por turno usam os horários disponíveis em comum, não dias completos."
  ))
  bloco(153, "Por que estes quatro gráficos?", c(
    "1. Linhas com escala comum mostram evolução e amplitude térmica entre estações.",
    "2. Dispersão preserva os pares temperatura–umidade, sem sugerir causalidade.",
    "3. Ponto e intervalo comparam vento médio e extremos observados (não são ICs).",
    "4. Matriz de calor resume as duas categorias; os números permitem leitura precisa.",
    "Cores e símbolos consistentes reduzem a busca por legendas; escalas têm unidades.",
    "Tufte: mostrar dados; retirar molduras, fundos e tinta redundante; revisar o resultado.",
    "Gestalt: proximidade e alinhamento agrupam painéis; não há 3D nem eixo duplo."
  ))
  bloco(101, "Principais comandos R usados", c(
    "download.file(url, destino)                         # preserva o HTML público",
    "jsonlite::fromJSON(trecho)                         # lê pares de horário e valor",
    "as.POSIXct(datahora, format=\"%d/%m/%Y %H:%M\")      # interpreta a data",
    "table(...); merge(...); aggregate(..., mean)        # alinha e resume",
    "plot(...); lines(...); points(...); segments(...)   # constrói os gráficos",
    "cairo_pdf(..., width=210/25.4, height=297/25.4)       # exporta o A4 vetorial"
  ))
  bloco(53, "Fontes e reprodução", c(
    "SIMEPAR, dados públicos das estações. HTML original e endereços completos em",
    "dados/brutos/ e dados/entrada/fontes.csv. Coleta: 15/10/2026.",
    "stage.simepar.br/prognozweb/simepar/dados_estacoes/{identificador}",
    "IDs: 25264916, 25534852, 23185109, 23275159 e 25435458.",
    "Ara, A.; Zanluca, A. Introdução à Visualização de Dados Aplicada (viz2025.pdf),",
    "seções 2.3, 2.5, 2.6 e 3. Reprodução offline: Rscript executar.R tudo.",
    "Apoio de IA na programação e revisão; conteúdo sujeito à revisão do aluno."
  ))
}

cairo_pdf(file.path(saida, "AV1_frente_verso_A4.pdf"), width = 210 / 25.4, height = 297 / 25.4,
          family = fonte, onefile = TRUE)
frente()
verso()
dev.off()
for (nome in c("frente", "verso")) {
  png(file.path(saida, paste0("AV1_", nome, ".png")), width = 210, height = 297,
      units = "mm", res = 180, type = "cairo", bg = "white")
  if (nome == "frente") frente() else verso()
  dev.off()
}
writeLines(capture.output(sessionInfo()), file.path(saida, "sessao_R.txt"))
message("PDF A4 e duas previas gerados.")
