arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz_av2 <- dirname(dirname(normalizePath(sub("^--file=", "", arquivo[[1]]), winslash = "/")))
raiz <- dirname(raiz_av2)
source(file.path(raiz_av2, "R", "analise.R"), encoding = "UTF-8")
dados <- read.csv(file.path(raiz, "dados", "entrada", "dados_publicados.csv"), colClasses = c(estacao_id = "character"))
dados$instante <- as.POSIXct(dados$datahora, format = "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
cidades <- unique(dados$estacao)

recorte <- recortar_dados(dados, cidades, min(dados$instante), max(dados$instante))
stopifnot(nrow(recorte) == 122L, identical(recorte, dados))
comuns <- selecionar_horarios_comuns(recorte, cidades)
stopifnot(nrow(comuns) == 110L, length(unique(comuns$instante)) == 22L)
stopifnot(all(table(comuns$estacao) == 22L))

# A grade mostra as três ausências sem criar valores intermediários.
grade <- montar_grade(recorte, cidades, "temperatura_c")
stopifnot(nrow(grade) == 125L, sum(is.na(grade$valor)) == 3L)
stopifnot(!anyNA(grade$valor[grade$estacao != "Maringá"]))

rho <- correlacao_segura(comuns$temperatura_c, comuns$umidade_pct)
stopifnot(isTRUE(all.equal(rho, -0.7421203, tolerance = 1e-7)))
stopifnot(is.na(correlacao_segura(c(1, 1, 1), c(2, 3, 4))))
stopifnot(is.na(correlacao_segura(c(1, 2), c(2, 1))))
r <- resumir_estacoes(comuns, "vento_kmh")
for (i in seq_len(nrow(r))) {
  x <- comuns$vento_kmh[comuns$estacao == r$estacao[[i]]]
  stopifnot(r$n[[i]] == length(x), identical(r$mediana[[i]], median(x)))
  stopifnot(identical(r$minimo[[i]], min(x)), identical(r$maximo[[i]], max(x)))
}

# Filtros e entradas vazias não alteram os dados originais.
uma <- recortar_dados(dados, "Curitiba", min(dados$instante), max(dados$instante))
stopifnot(nrow(uma) == 25L, nrow(selecionar_horarios_comuns(uma, "Curitiba")) == 25L)
vazio <- recortar_dados(dados, character(), min(dados$instante), max(dados$instante))
stopifnot(nrow(vazio) == 0L, nrow(resumir_estacoes(vazio, "vento_kmh")) == 0L)
stopifnot(nrow(resumir_turnos(comuns, "temperatura_c")) == 20L)
stopifnot(identical(recorte, dados))
cat("OK: 122 observações, 110 comparáveis, 3 lacunas, correlação, quartis, turnos e filtros conferidos.\n")
