# A AV1 e somente leitura; horarios locais usam o fuso do Parana.
.estacoes_av2 <- function() {
  data.frame(estacao_id = c("25264916", "25534852", "23185109", "23275159", "25435458"),
             estacao = c("Curitiba", "Paranaguá", "Londrina", "Maringá", "Foz do Iguaçu"),
             stringsAsFactors = FALSE)
}

.validar_dados_av2 <- function(dados, agora) {
  colunas <- c("datahora", "temperatura_c", "umidade_pct", "vento_kmh", "estacao_id", "estacao")
  if (!is.data.frame(dados) || !nrow(dados) ||
      !(identical(names(dados), colunas) || identical(names(dados), c(colunas, "instante")))) {
    stop("Colunas ou dados invalidos.")
  }
  estacoes <- .estacoes_av2()
  if (!is.character(dados$estacao_id) || !is.character(dados$estacao) ||
      anyNA(dados$estacao_id) || anyNA(dados$estacao) ||
      !setequal(dados$estacao_id, estacoes$estacao_id) ||
      any(dados$estacao != estacoes$estacao[match(dados$estacao_id, estacoes$estacao_id)])) {
    stop("IDs, nomes ou conjunto de estacoes invalidos.")
  }
  instante <- as.POSIXct(dados$datahora, format = "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
  if (!is.character(dados$datahora) || anyNA(instante) ||
      any(format(instante, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo") != dados$datahora)) {
    stop("Horario invalido.")
  }
  if ("instante" %in% names(dados) &&
      (!inherits(dados$instante, "POSIXct") || anyNA(dados$instante) ||
       any(as.numeric(dados$instante) != as.numeric(instante)))) stop("Instante inconsistente.")
  dados$instante <- instante
  if (any(as.numeric(instante) > as.numeric(agora))) stop("Dados futuros nao sao aceitos.")
  if (anyDuplicated(dados[c("estacao_id", "datahora")])) stop("Leitura duplicada.")
  medidas <- c("temperatura_c", "umidade_pct", "vento_kmh")
  for (coluna in medidas) {
    valor <- dados[[coluna]]
    if (!is.numeric(valor) || any(is.nan(valor)) || any(!is.na(valor) & !is.finite(valor))) {
      stop("Medida invalida: ", coluna)
    }
  }
  if (any(dados$umidade_pct < 0 | dados$umidade_pct > 100, na.rm = TRUE)) stop("Umidade fora de 0 a 100%.")
  # Limite conservador de plausibilidade, nao um limite instrumental.
  if (any(dados$vento_kmh < 0 | dados$vento_kmh > 400, na.rm = TRUE)) stop("Vento fora de 0 a 400 km/h.")
  completas <- complete.cases(dados[medidas])
  if (!setequal(dados$estacao_id[completas], estacoes$estacao_id)) stop("Falta leitura completa em alguma estacao.")
  dados
}

.validar_avanco_av2 <- function(dados, anteriores) {
  ids <- .estacoes_av2()$estacao_id
  ultimo <- function(d) vapply(ids, function(id) max(as.numeric(d$instante[d$estacao_id == id])), numeric(1))
  novos <- ultimo(dados)
  antigos <- ultimo(anteriores)
  if (any(novos < antigos)) stop("Regressao temporal em alguma estacao.")
  if (!any(novos > antigos)) stop("Nenhuma leitura mais recente; base preservada.")
  invisible(TRUE)
}

.data_valida_av2 <- function(x) {
  inherits(x, "POSIXct") && length(x) == 1L && !is.na(x) && is.finite(as.numeric(x))
}

carregar_base_av2 <- function(raiz) {
  entrada <- file.path(raiz, "dados", "entrada")
  dados <- read.csv(file.path(entrada, "dados_publicados.csv"),
                    colClasses = c(estacao_id = "character"), fileEncoding = "UTF-8")
  dados$instante <- as.POSIXct(dados$datahora, format = "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
  fontes <- read.csv(file.path(entrada, "fontes.csv"), fileEncoding = "UTF-8")
  datas <- as.POSIXct(fontes$coleta_utc, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  if (anyNA(datas) || length(datas) != 5L || anyDuplicated(fontes$estacao_id) ||
      !setequal(as.character(fontes$estacao_id), .estacoes_av2()$estacao_id)) stop("Fontes da AV1 invalidas.")
  dados <- .validar_dados_av2(dados, max(datas))
  base <- list(dados = dados, origem = "Coleta preservada da AV1", coletado_em = max(datas),
               tentativa_em = as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"), erro = NULL)
  cache <- file.path(raiz, "av2", "cache", "ultima_coleta.rds")
  if (file.exists(cache)) {
    candidato <- tryCatch(suppressWarnings({
      x <- readRDS(cache)
      if (!is.list(x) || !identical(names(x), names(base)) ||
          !identical(x$origem, "Coleta atual do SIMEPAR") || !is.null(x$erro) ||
          !.data_valida_av2(x$coletado_em) || !.data_valida_av2(x$tentativa_em) ||
          as.numeric(x$coletado_em) < as.numeric(base$coletado_em) ||
          as.numeric(x$tentativa_em) < as.numeric(x$coletado_em) ||
          as.numeric(x$tentativa_em) > as.numeric(Sys.time())) stop("Metadados de cache invalidos.")
      x$dados <- .validar_dados_av2(x$dados, x$coletado_em)
      .validar_avanco_av2(x$dados, base$dados)
      x
    }), error = function(e) NULL)
    if (!is.null(candidato)) return(candidato)
  }
  base
}

.baixar_pagina_av2 <- function(url) {
  scratch <- getOption("av2.pasta_temporaria", tempdir())
  dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
  destino <- tempfile("av2-pagina-", tmpdir = scratch, fileext = ".html")
  on.exit(unlink(destino), add = TRUE)
  opcoes <- options(timeout = 8)
  on.exit(options(opcoes), add = TRUE)
  # Sem repeticoes, cookies, CAPTCHA ou troca de dominio ao bloquear.
  avisos <- character()
  status <- tryCatch(withCallingHandlers(
    download.file(url, destino, method = "libcurl", mode = "wb", quiet = TRUE),
    warning = function(w) { avisos <<- c(avisos, conditionMessage(w)); invokeRestart("muffleWarning") }),
    error = function(e) stop(paste(c(avisos, conditionMessage(e)), collapse = "; "), call. = FALSE))
  if (!identical(status, 0L) && !identical(status, 0)) stop("Falha no download: ", paste(avisos, collapse = "; "))
  paste(readLines(destino, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

.extrair_serie_av2 <- function(html, nome, coluna) {
  padrao <- paste0("name:\\s*'", nome, "'[\\s\\S]*?data:\\s*(\\[\\[[\\s\\S]*?\\]\\])")
  trecho <- regmatches(html, regexec(padrao, html, perl = TRUE))[[1]]
  if (length(trecho) != 2L) stop("Serie nao encontrada: ", nome)
  pares <- jsonlite::fromJSON(trecho[2], simplifyVector = FALSE)
  if (!length(pares)) stop("Serie vazia: ", nome)
  horarios <- vapply(pares, function(x) {
    if (length(x) != 2L || !is.character(x[[1]]) || length(x[[1]]) != 1L) stop("Par de serie invalido.")
    x[[1]]
  }, character(1))
  valores <- vapply(pares, function(x) {
    if (is.null(x[[2]])) return(NA_real_)
    if (!is.numeric(x[[2]]) || length(x[[2]]) != 1L) stop("Valor de serie invalido.")
    as.numeric(x[[2]])
  }, numeric(1))
  if (anyDuplicated(horarios)) stop("Horario duplicado na serie ", nome)
  dados <- data.frame(datahora = horarios, valor = valores, stringsAsFactors = FALSE)
  names(dados)[2] <- coluna
  dados
}

coletar_estacoes_av2 <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite nao esta disponivel.")
  estacoes <- .estacoes_av2()
  bases <- vector("list", nrow(estacoes))
  for (i in seq_len(nrow(estacoes))) {
    id <- estacoes$estacao_id[i]
    html <- .baixar_pagina_av2(paste0("https://www.simepar.br/simepar/dados_estacoes/", id))
    padrao <- paste0('<option value="', id, '" selected="selected">([^<]+)</option>')
    selecionada <- regmatches(html, regexec(padrao, html, perl = TRUE))[[1]]
    if (length(selecionada) != 2L) stop("ID selecionado inesperado: ", id)
    nome <- gsub("&aacute;", "á", gsub("&ccedil;", "ç", selecionada[2], fixed = TRUE), fixed = TRUE)
    if (!identical(trimws(nome), estacoes$estacao[i])) stop("Nome da estacao inesperado: ", id)
    series <- list(.extrair_serie_av2(html, "Temperatura Média", "temperatura_c"),
                   .extrair_serie_av2(html, "Umidade Relativa", "umidade_pct"),
                   .extrair_serie_av2(html, "Velocidade do Vento", "vento_kmh"))
    dados <- Reduce(function(x, y) merge(x, y, by = "datahora", all = TRUE), series)
    dados$estacao_id <- id
    dados$estacao <- estacoes$estacao[i]
    bases[[i]] <- dados
  }
  .validar_dados_av2(do.call(rbind, bases), Sys.time())
}

atualizar_base_av2 <- function(base, raiz, buscar = coletar_estacoes_av2, agora = Sys.time()) {
  tryCatch({
    if (!.data_valida_av2(agora) || as.numeric(agora) < as.numeric(base$coletado_em) ||
        as.numeric(agora) > as.numeric(Sys.time())) stop("Data da tentativa invalida.")
    dados <- .validar_dados_av2(buscar(), agora)
    .validar_avanco_av2(dados, base$dados)
    nova <- list(dados = dados, origem = "Coleta atual do SIMEPAR", coletado_em = agora,
                 tentativa_em = agora, erro = NULL)
    pasta <- file.path(raiz, "av2", "cache")
    dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
    provisoria <- tempfile("ultima-", tmpdir = pasta, fileext = ".rds")
    on.exit(unlink(provisoria), add = TRUE)
    saveRDS(nova, provisoria)
    if (!file.rename(provisoria, file.path(pasta, "ultima_coleta.rds"))) stop("Nao foi possivel publicar o cache.")
    nova
  }, error = function(e) {
    base$tentativa_em <- agora
    base$erro <- conditionMessage(e)
    base
  })
}
