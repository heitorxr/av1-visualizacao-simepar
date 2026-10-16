# Composicao em R base: PDF vetorial A4 e previas PNG de 180 dpi.
obj <- readRDS(file.path(raiz, "resultados", "analise.rds"))
a <- obj$analise
r <- obj$resumo
pares_correlacao <- a[is.finite(a$temperatura_c) & is.finite(a$umidade_pct), ]
correlacao <- cor(pares_correlacao$temperatura_c, pares_correlacao$umidade_pct,
                 method = "spearman")
saida <- file.path(raiz, "resultados")
cores <- c("Curitiba" = "#0072B2", "Foz do Iguaçu" = "#D55E00", "Londrina" = "#009E73",
           "Maringá" = "#8B5094", "Paranaguá" = "#9A6500")
simbolos <- setNames(c(16, 17, 15, 18, 8), names(cores))
fmt <- function(x, casas = 1) formatC(x, digits = casas, format = "f", decimal.mark = ",")
fonte <- "Arial"

# Trechos reais dos scripts, distribuidos em duas colunas no verso.
codigo_esquerda <- c(
  "dados <- read.csv(file.path(entrada,",
  "  \"dados_publicados.csv\"),",
  "  fileEncoding = \"UTF-8\",",
  "  colClasses = c(estacao_id = \"character\"))",
  "",
  "dados$instante <- as.POSIXct(",
  "  dados$datahora,",
  "  format = \"%d/%m/%Y %H:%M\",",
  "  tz = \"America/Sao_Paulo\")",
  "",
  "completo <- apply(dados[variaveis], 1,",
  "  function(x) all(is.finite(x)))",
  "",
  "contagens <- table(",
  "  dados$datahora[completo])"
)
codigo_direita <- c(
  "horarios_comuns <- names(contagens)[",
  "  contagens == length(unique(dados$estacao_id))]",
  "analise <- dados[completo &",
  "  dados$datahora %in% horarios_comuns, ]",
  "",
  "analise$turno <- factor(",
  "  turnos[hora %/% 6 + 1],",
  "  levels = turnos, ordered = TRUE)",
  "",
  "por_turno <- aggregate(analise[variaveis],",
  "  analise[c(\"estacao\", \"turno\")], mean)",
  "",
  "correlacao <- cor(pares_correlacao$temperatura_c,",
  "  pares_correlacao$umidade_pct,",
  "  method = \"spearman\")"
)

# A explicacao e a amostra para revisao saem da mesma fonte, sem copias manuais.
secoes_verso <- list(
  list(y = 254, titulo = "A base e o recorte", linhas = c(
    "Escolhi esta base porque já a utilizava quando trabalhava no SIMEPAR. Usei o recorte",
    "de 14/10/2026, 19h, a 15/10/2026, 19h, adotando o horário de Brasília.",
    "",
    "São 122 registros: cada um corresponde a uma estação em um horário. Comparei temperatura",
    "(°C), umidade relativa (%) e vento (km/h). As qualitativas são a estação e o turno: madrugada",
    "(00–05h), manhã (06–11h), tarde (12–17h) e noite (18–23h).",
    "",
    "Maringá tem três horários sem dados. Mantive todas as temperaturas no gráfico 1 e indiquei",
    "as faltas com tracejados. Nos gráficos 2–4, usei os 22 horários comuns: 110 registros, sem",
    "preencher valores ausentes."
  )),
  list(y = 197, titulo = "Como montei os gráficos", linhas = c(
    "Usei linhas para temperatura e dispersão para compará-la à umidade. A correlação global de Spearman",
    "foi −0,742 nos 110 pares das cinco estações. É um resumo do conjunto, não uma explicação causal.",
    "",
    "No vento, o ponto mostra a média; a linha liga mínimo e máximo, não limites de confiança.",
    "Na matriz, comparei as temperaturas médias por estação e turno.",
    "",
    "Deixei o fundo branco e reduzi a decoração, como sugere Tufte. As cores e os símbolos das",
    "estações se repetem nos três primeiros gráficos, aplicando a similaridade da Gestalt."
  )),
  list(y = 149, titulo = "Principais comandos R", codigo = TRUE,
       quebra = length(codigo_esquerda), linhas = c(codigo_esquerda, codigo_direita)),
  list(y = 38, titulo = "Fontes e reprodução", compacto = TRUE, linhas = c(
    "SIMEPAR, páginas públicas; coleta em 15/10/2026. HTML e URLs preservados no projeto.",
    "stage.simepar.br/prognozweb/simepar/dados_estacoes/{identificador}",
    "IDs: 25264916, 25534852, 23185109, 23275159 e 25435458.",
    "Ara e Zanluca. Introdução à Visualização de Dados Aplicada, seções 2.3, 2.5, 2.6 e 3.",
    "Reprodução offline: Rscript executar.R tudo.",
    "Usei IA como apoio na programação e na revisão."
  ))
)

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
  texto(12, 284, "Paraná em 24 horas", 26, negrito = TRUE)
  text(198, 284, "14/10/2026, 19h a 15/10/2026, 19h", adj = c(1, 0.5),
       cex = 8.5 / 12, col = "#596470")
  texto(12, 273, "Temperatura, umidade e vento em cinco estações do SIMEPAR", 10.5)
  maior_amplitude <- r[which.max(r$amplitude_c), ]
  maior_vento <- r[which.max(r$vento_medio), ]
  texto(12, 263, paste0(maior_amplitude$estacao, ": maior amplitude (", fmt(maior_amplitude$amplitude_c),
                        " °C)  |  ", maior_vento$estacao, ": maior vento médio (", fmt(maior_vento$vento_medio), " km/h)"),
        10, negrito = TRUE)
  # A mesma cor e o mesmo simbolo sempre identificam a mesma estacao.
  xpos <- c(12, 47, 97, 131, 165)
  for (i in seq_along(cores)) {
    points(xpos[i], 253, pch = simbolos[i], col = cores[i], cex = 0.7)
    texto(xpos[i] + 3, 253, names(cores)[i], 8.5)
  }
  texto(12, 242, "1  Temperatura horária (°C)", 11, negrito = TRUE)
  texto(12, 235, "Pontos: medições; tracejado: intervalo sem dado.", 8.5, cor = "#596470")
  texto(12, 149, "2  Calor e umidade", 11, negrito = TRUE)
  texto(116, 149, "3  Vento entre estações", 11, negrito = TRUE)
  texto(12, 142, paste0("Correlação global de Spearman: ", sub("-", "−", fmt(correlacao, 3), fixed = TRUE)),
        8, cor = "#596470")
  texto(12, 136, paste0(nrow(pares_correlacao), " pares das cinco estações"),
        8, cor = "#596470")
  texto(116, 142, "Ponto: média; linha: mínimo–máximo.", 8, cor = "#596470")
  texto(12, 77, "4  A tarde foi o turno mais quente", 11, negrito = TRUE)
  texto(12, 70, "Temperatura média (°C); n = horários por estação.", 8.5, cor = "#596470")
  texto(12, 16, "SIMEPAR | coleta: 15/10/2026 | G1: 122 registros; G2–G4: 110 em 22 horários comuns.", 7.7, cor = "#596470")
  texto(12, 10, "Horário de Brasília adotado. Recorte de 24h, sem interpretação climática.", 7.7, cor = "#596470")

  # 1. Preserva TODAS as temperaturas publicadas, sem preencher valores ausentes.
  # Ligacoes tracejadas indicam os intervalos sem observacao; nao sao medicoes.
  painel(c(0.04, 0.97, 0.525, 0.775), c(2.4, 3.2, 0.2, 0.6))
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

# Verso na mesma folha, com a identificacao informada pelo aluno.
verso <- function() {
  pagina()
  texto(14, 284, "Escolha dos dados e construção", 20, negrito = TRUE)
  texto(14, 274, "CE303 — AV1 | UFPR | 2026.2", 10)
  texto(14, 266, "Heitor Cardoso Fernandes", 12, negrito = TRUE)
  bloco <- function(y, titulo, linhas, codigo = FALSE, quebra = Inf, compacto = FALSE) {
    texto(14, y, titulo, 12, negrito = TRUE)
    for (i in seq_along(linhas)) {
      if (codigo) {
        direita <- i > quebra
        indice <- if (direita) i - quebra else i
        text(if (direita) 112 else 14, y - 8 - (indice - 1) * 3.7,
             linhas[i], adj = c(0, 0.5), cex = 8.5 / 12, family = "mono")
      } else {
        texto(14, y - 7 - (i - 1) * if (compacto) 3.7 else 4.2,
              linhas[i], if (compacto) 8.2 else 9.3)
      }
    }
  }
  for (secao in secoes_verso[1:3]) {
    bloco(secao$y, secao$titulo, secao$linhas, isTRUE(secao$codigo),
          if (is.null(secao$quebra)) Inf else secao$quebra)
  }

  # Cinco registros reais do primeiro horario comum, sem identificador da estacao.
  amostra <- a[a$instante == min(a$instante),
               c("estacao", "instante", "temperatura_c", "umidade_pct", "vento_kmh", "turno")]
  texto(14, 80, "Amostra dos dados — primeiro horário comum", 12, negrito = TRUE)
  posicoes <- c(14, 51, 110, 139, 166, 178)
  cabecalhos <- c("Estação", "Data/hora", "T (°C)", "UR (%)", "Vento (km/h)", "Turno")
  alinhamentos <- c(0, 0, 1, 1, 1, 0)
  for (j in seq_along(cabecalhos)) {
    text(posicoes[j], 72, cabecalhos[j], adj = c(alinhamentos[j], 0.5),
         cex = 8.5 / 12, font = 2)
  }
  segments(14, 69.5, 196, 69.5, col = "#C9D1D8", lwd = 0.6)
  for (i in seq_len(nrow(amostra))) {
    valores <- c(amostra$estacao[i],
                 format(amostra$instante[i], "%d/%m/%Y %Hh", tz = "America/Sao_Paulo"),
                 fmt(amostra$temperatura_c[i]), fmt(amostra$umidade_pct[i]),
                 fmt(amostra$vento_kmh[i]), as.character(amostra$turno[i]))
    for (j in seq_along(valores)) {
      text(posicoes[j], 67 - (i - 1) * 4.5, valores[j],
           adj = c(alinhamentos[j], 0.5), cex = 8.5 / 12)
    }
  }
  secao <- secoes_verso[[4]]
  bloco(secao$y, secao$titulo, secao$linhas, compacto = TRUE)
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
write.csv(data.frame(n = nrow(pares_correlacao), rho_spearman = correlacao,
                     amostra = "cinco estacoes nos mesmos 22 horarios"),
          file.path(saida, "correlacao_temperatura_umidade.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
writeLines(unlist(lapply(secoes_verso[1:2], function(secao) {
  c(secao$titulo, secao$linhas, "")
})), file.path(saida, "texto_para_verificacao.txt"), useBytes = TRUE)
writeLines(capture.output(sessionInfo()), file.path(saida, "sessao_R.txt"))
message("PDF A4 e duas previas gerados.")
