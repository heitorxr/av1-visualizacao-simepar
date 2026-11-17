arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), winslash = "/")
modulo <- file.path(raiz, "R", "analise.R")
if (file.exists(modulo)) source(modulo, encoding = "UTF-8")
if (!exists("preparar_analise_global")) stop("RED: análise global ainda não implementada")
# Fixture pequena, somente para testar seleção de horários; não pertence à base real.
t <- as.POSIXct("2026-11-16 12:00:00", tz = "UTC") + c(0, 0, 3600, 3600, 7200)
z <- data.frame(estacao = c("São Paulo", "Guarulhos", "São Paulo", "Guarulhos", "São Paulo"),
                instante = t, datahora = format(t, "%d/%m/%Y %H:%M"),
                temperatura_c = c(20, 21, 22, 23, 24), umidade_pct = c(80, 75, 70, 65, 60), vento_kmh = c(0, 2, 4, 6, 8))
a <- preparar_analise_global(z, c("São Paulo", "Guarulhos"), min(t), max(t), TRUE, "temperatura_c")
stopifnot(all(c("serie", "comparaveis", "resumo", "turnos", "correlacoes") %in% names(a)),
          nrow(a$serie) == 5L, nrow(a$comparaveis) == 4L, nrow(a$resumo) == 2L,
          all(a$resumo$n == 2L), nrow(a$correlacoes) == 3L,
          isTRUE(all.equal(a$correlacoes$Spearman[1], cor(a$comparaveis$temperatura_c, a$comparaveis$umidade_pct, method = "spearman"))))
b <- preparar_analise_global(z, c("São Paulo", "Guarulhos"), min(t), max(t), FALSE, "vento_kmh")
stopifnot(nrow(b$comparaveis) == 5L, any(b$comparaveis$vento_kmh == 0))
cat("Análise: horários comuns, amostra, correlação, resumos e calmaria verificados.\n")
if (!exists("situacao_estacoes")) stop("RED: estado de atualização por estação ainda não implementado")
z$observado_em <- z$instante
s <- situacao_estacoes(z, c("São Paulo", "Guarulhos", "Campinas"), agora = max(t) + 3600)
stopifnot(nrow(s) == 3L, all(c("estacao", "observado_em", "atraso_min", "status") %in% names(s)),
          s$status[s$estacao == "São Paulo"] == "Recente",
          s$status[s$estacao == "Campinas"] == "Sem boletim")
s <- situacao_estacoes(z, "São Paulo", agora = max(t) + 10800)
stopifnot(s$status == "Boletim antigo")
cat("Atualidade: idades por estação e ausência não confundidas com coleta recente.\n")
