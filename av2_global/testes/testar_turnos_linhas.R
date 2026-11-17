script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
source(file.path(raiz, "R", "analise.R"), encoding = "UTF-8")
# Fixture somente em memória: quatro turnos reais e lacunas em uma cidade.
horas <- as.POSIXct(paste("2026-11-16", c("01:00:00", "07:00:00", "13:00:00", "19:00:00", "07:00:00", "13:00:00")), tz = "America/Sao_Paulo")
dados <- data.frame(estacao = c(rep("São Paulo", 4), rep("Guarujá", 2)), instante = horas,
  temperatura_c = c(20, 22, 25, 18, 24, 26), umidade_pct = rep(70, 6), vento_kmh = c(0, 2, 3, 4, 5, 6))
resumo <- preparar_turnos_visuais(dados, c("São Paulo", "Guarujá"), "temperatura_c")
# Observa as coordenadas enviadas ao dispositivo real, não apenas nomes de funções.
chamadas <- new.env(); chamadas$linhas <- list(); chamadas$retangulos <- 0L
ambiente <- new.env(parent = environment(plotar_turnos))
ambiente$lines <- function(x, y, ...) {
  chamadas$linhas[[length(chamadas$linhas) + 1L]] <- list(x = x, y = y)
  graphics::lines(x, y, ...)
}
ambiente$rect <- function(...) { chamadas$retangulos <- chamadas$retangulos + 1L; graphics::rect(...) }
desenhar <- plotar_turnos; environment(desenhar) <- ambiente
arquivo <- tempfile(fileext = ".png")
png(arquivo, width = 360, height = 280)
p <- desenhar(resumo, "temperatura_c")
dev.off()
if (length(chamadas$linhas) != 2L || chamadas$retangulos != 0L)
  stop("RED: médias por turno devem ser linhas por cidade, não um quadro de células")
stopifnot(identical(levels(p$turno), c("Madrugada", "Manhã", "Tarde", "Noite")), nrow(p) == 8L,
  is.numeric(p$.y), length(p$.y) == nrow(p), identical(p$.y, p$media))
for (linha in chamadas$linhas) stopifnot(identical(linha$x, as.numeric(1:4)))
stopifnot(any(vapply(chamadas$linhas, function(linha) identical(linha$y, c(20, 22, 25, 18)), logical(1))),
  any(vapply(chamadas$linhas, function(linha) identical(linha$y, c(NA_real_, 24, 26, NA_real_)), logical(1))))
v <- preparar_turnos_visuais(dados, c("São Paulo", "Guarujá"), "vento_kmh")
stopifnot(v$media[v$estacao == "São Paulo" & v$turno == "Madrugada"] == 0,
  all(is.na(v$media[v$n == 0L])), file.info(arquivo)$size > 0)
unlink(arquivo)
cat("Turnos em linhas: quatro turnos, coordenadas reais, lacunas NA e vento zero preservados.\n")
