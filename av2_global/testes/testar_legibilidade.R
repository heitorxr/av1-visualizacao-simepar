script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
source(file.path(raiz, "R", "analise.R"), encoding = "UTF-8")
# Fixture apenas em memória: uma cidade tem madrugada, a outra só tem manhã.
t <- as.POSIXct(c("2026-11-16 01:00:00", "2026-11-16 02:00:00", "2026-11-16 10:00:00"), tz = "America/Sao_Paulo")
z <- data.frame(estacao = c("São Paulo", "São Paulo", "Guarujá"), instante = t,
                datahora = format(t, "%d/%m/%Y %H:%M"), temperatura_c = c(20,22,25), umidade_pct = c(70,65,60), vento_kmh = c(0,2,4))
a <- preparar_analise_global(z, c("São Paulo", "Guarujá"), min(t), max(t), TRUE)
stopifnot(nrow(a$comparaveis) == 0L)
if (nrow(a$turnos) != 8L) stop("RED: quadro de turnos deve manter todas as cidades e os quatro turnos")
p <- a$turnos[a$turnos$estacao == "São Paulo" & a$turnos$turno == "Madrugada", ]
g <- a$turnos[a$turnos$estacao == "Guarujá" & a$turnos$turno == "Madrugada", ]
stopifnot(nrow(p) == 1L, p$n == 2L, p$media == mean(z$temperatura_c[1:2]),
          nrow(g) == 1L, g$n == 0L, is.na(g$media), all(c(".x", ".y") %in% names(a$turnos)))
cat("Turnos: madrugada real preservada; ausência explícita, sem imputação.\n")
if (!exists("preparar_serie_visual")) stop("RED: resumo diário da série ainda não implementado")
d <- preparar_serie_visual(z, "temperatura_c", diaria = TRUE)
stopifnot(nrow(d) == 2L, sum(d$n) == nrow(z), all(c(".x", ".y", "minimo", "maximo") %in% names(d)),
          d$.y[d$estacao == "São Paulo"] == mean(z$temperatura_c[1:2]),
          all(format(d$instante, "%H:%M", tz = "America/Sao_Paulo") == "00:00"))
h <- preparar_serie_visual(z, "vento_kmh", diaria = FALSE)
stopifnot(nrow(h) == nrow(z), identical(h$.y, z$vento_kmh), any(h$.y == 0))
cat("Série: médias diárias fiéis, denominadores e retorno às horas preservados.\n")
if (!exists("preparar_frequencias")) stop("RED: agrupamento de pontos por frequência ainda não implementado")
w <- rbind(z, z)
f <- preparar_frequencias(w)
stopifnot(nrow(f) < nrow(w), sum(f$n) == nrow(w), all(c("t_min","t_max","u_min","u_max","cidades",".x",".y") %in% names(f)))
w$umidade_pct[1] <- 100
f <- preparar_frequencias(w)
stopifnot(sum(f$n) == nrow(w), all(f$u_max <= 100), nrow(preparar_frequencias(w[FALSE, ])) == 0L)
cat("Associação: faixas conservam todas as observações e o limite de 100%.\n")
