# Observacoes reais METAR. Umidade e derivada (Magnus), nunca imputada.
estacoes_globais <- function() {
  data.frame(estacao_id = c("SBSP", "SBGR", "SBKP", "SBSJ", "SBST"),
             estacao = c("São Paulo", "Guarulhos", "Campinas", "São José dos Campos", "Guarujá"),
             aeroporto = c("Congonhas", "Guarulhos", "Viracopos", "Professor Urbano Ernesto Stumpf", "Base Aérea de Santos"),
             stringsAsFactors = FALSE)
}
.global_vazio <- function() {
  data.frame(estacao_id = character(), estacao = character(),
    observado_em = as.POSIXct(character(), tz = "UTC"),
    instante = as.POSIXct(character(), tz = "America/Sao_Paulo"), datahora = character(),
    temperatura_c = double(), ponto_orvalho_c = double(), umidade_pct = double(),
    vento_kmh = double(), fonte = character(), metar = character(), stringsAsFactors = FALSE)
}
.global_num <- function(x) {
  texto <- as.character(x)
  vazio <- is.na(texto) | texto %in% c("", "M", "NA", "null")
  y <- suppressWarnings(as.numeric(texto)); y[vazio] <- NA_real_
  if (any(!vazio & (!is.finite(y) | is.na(y)))) stop("Numero invalido na resposta")
  y
}
.global_normalizar <- function(ids, tempos, temp, dew, vento, fonte, metar) {
  if (anyNA(tempos)) stop("Data de observacao invalida")
  manter <- ids %in% estacoes_globais()$estacao_id & tempos <= Sys.time() + 300
  d <- .global_vazio()
  if (!any(manter)) return(d)
  ids <- ids[manter]; tempos <- tempos[manter]
  d <- data.frame(estacao_id = ids, estacao = estacoes_globais()$estacao[match(ids, estacoes_globais()$estacao_id)],
    observado_em = as.POSIXct(as.numeric(tempos), origin = "1970-01-01", tz = "UTC"),
    instante = as.POSIXct(as.numeric(tempos), origin = "1970-01-01", tz = "America/Sao_Paulo"),
    datahora = format(tempos, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo"),
    temperatura_c = temp[manter], ponto_orvalho_c = dew[manter],
    umidade_pct = 100 * exp(17.625 * dew[manter] / (243.04 + dew[manter]) - 17.625 * temp[manter] / (243.04 + temp[manter])),
    vento_kmh = vento[manter] * 1.852, fonte = fonte, metar = metar[manter], stringsAsFactors = FALSE)
  rownames(d) <- NULL
  d
}
.global_validar <- function(d) {
  if (!is.data.frame(d) || !all(names(.global_vazio()) %in% names(d)) || anyDuplicated(names(d))) stop("Esquema de observacoes invalido")
  if (!inherits(d$observado_em, "POSIXct") || !inherits(d$instante, "POSIXct") || anyNA(d$observado_em) || anyNA(d$instante)) stop("Instantes invalidos")
  if (anyNA(d$estacao_id) || any(!d$estacao_id %in% estacoes_globais()$estacao_id) || any(d$observado_em > Sys.time() + 300)) stop("Estacao ou data fora do escopo")
  if (anyNA(d$estacao) || any(d$estacao != estacoes_globais()$estacao[match(d$estacao_id, estacoes_globais()$estacao_id)])) stop("Nome de estacao invalido")
  for (nome in c("temperatura_c", "ponto_orvalho_c", "umidade_pct", "vento_kmh")) {
    if (!is.numeric(d[[nome]]) || any(!is.na(d[[nome]]) & !is.finite(d[[nome]]))) stop("Medida invalida")
  }
  invisible(d)
}
combinar_observacoes <- function(antigos, novos) {
  .global_validar(antigos); .global_validar(novos)
  d <- rbind(antigos, novos)
  if (!nrow(d)) return(.global_vazio())
  chave <- paste(d$estacao_id, as.numeric(d$observado_em), sep = "|")
  grupos <- split(seq_len(nrow(d)), chave)
  medidas <- c("temperatura_c", "ponto_orvalho_c", "vento_kmh")
  manter <- integer(length(grupos)); k <- 0L
  for (indices in grupos) {
    k <- k + 1L; i <- indices[1]; manter[k] <- i
    for (nome in medidas) {
      valores <- d[[nome]][indices]; conhecidos <- valores[!is.na(valores)]
      if (length(conhecidos) && max(conhecidos) - min(conhecidos) > 1e-6) stop(paste("Conflito ambiental:", chave[i], nome))
    }
    for (nome in names(d)) {
      if (is.na(d[[nome]][i])) {
        candidatos <- indices[!is.na(d[[nome]][indices])]
        if (length(candidatos)) d[[nome]][i] <- d[[nome]][candidatos[1]]
      }
    }
    # Recalcular RH se as duas medidas complementares so ficaram completas na uniao.
    if (is.na(d$umidade_pct[i]) && !is.na(d$temperatura_c[i]) && !is.na(d$ponto_orvalho_c[i])) {
      d$umidade_pct[i] <- 100 * exp(17.625*d$ponto_orvalho_c[i]/(243.04+d$ponto_orvalho_c[i]) - 17.625*d$temperatura_c[i]/(243.04+d$temperatura_c[i]))
    }
  }
  d <- d[manter, , drop = FALSE]
  d <- d[order(d$observado_em, d$estacao_id), , drop = FALSE]
  rownames(d) <- NULL
  d
}
agregar_horas_globais <- function(dados) {
  if (!nrow(dados)) return(dados)
  d <- dados[order(dados$observado_em, dados$estacao_id), , drop = FALSE]
  hora <- floor(as.numeric(d$observado_em) / 3600) * 3600
  ultimo <- !duplicated(paste(d$estacao_id, hora), fromLast = TRUE)
  d <- d[ultimo, , drop = FALSE]
  d$instante <- as.POSIXct(hora[ultimo], origin = "1970-01-01", tz = "America/Sao_Paulo")
  d$datahora <- format(d$instante, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
  d <- d[order(d$instante, d$estacao_id), , drop = FALSE]
  rownames(d) <- NULL
  d
}
normalizar_iem <- function(arquivo) {
  x <- read.csv(arquivo, colClasses = "character", check.names = FALSE, na.strings = c("", "M", "NA"))
  if (!nrow(x) || anyDuplicated(names(x)) || !all(c("station", "valid") %in% names(x))) stop("Resposta IEM vazia ou esquema invalido")
  campo <- function(nome, numero = TRUE) {
    valor <- if (nome %in% names(x)) x[[nome]] else rep(NA, nrow(x))
    if (numero) .global_num(valor) else as.character(valor)
  }
  if (any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}(:[0-9]{2})?$", x$valid))) stop("Data IEM invalida")
  .global_normalizar(x$station, as.POSIXct(x$valid, tz = "UTC"),
    (campo("tmpf") - 32) * 5/9, (campo("dwpf") - 32) * 5/9,
    campo("sknt"), "IEM ASOS/METAR", campo("metar", FALSE))
}
.global_estado <- function(dados = .global_vazio(), origem = "sem dados", erro = NULL) {
  ausente <- as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC")
  list(dados = dados, origem = origem, coletado_em = ausente, tentativa_em = ausente,
       historico_em = ausente, erro = erro)
}
carregar_global <- function(raiz) {
  cache <- file.path(raiz, "cache", "historico.rds")
  erro <- NULL
  if (file.exists(cache)) {
    estado <- tryCatch(suppressWarnings({
      e <- readRDS(cache)
      if (!is.list(e) || !identical(names(e), names(.global_estado()))) stop("Estado de cache invalido")
      .global_validar(e$dados)
      for (nome in c("coletado_em", "tentativa_em", "historico_em")) {
        if (!inherits(e[[nome]], "POSIXct") || length(e[[nome]]) != 1L) stop("Data de cache invalida")
      }
      e
    }), error = function(e) { erro <<- paste("Cache rejeitado:", conditionMessage(e)); NULL })
    if (!is.null(estado)) return(estado)
  }
  arquivo <- file.path(raiz, "dados", "entrada", "observacoes_iniciais.csv")
  if (!file.exists(arquivo)) return(.global_estado(erro = erro))
  tryCatch({
    d <- read.csv(arquivo, colClasses = "character", stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
    for (nome in c("observado_em", "instante")) {
      if (!nome %in% names(d) || any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", d[[nome]]))) stop("Timestamp inicial requer ISO UTC Z")
      d[[nome]] <- as.POSIXct(d[[nome]], format = "%Y-%m-%dT%H:%M:%SZ", tz = if (nome == "observado_em") "UTC" else "UTC")
      if (nome == "instante") attr(d[[nome]], "tzone") <- "America/Sao_Paulo"
    }
    for (nome in c("temperatura_c", "ponto_orvalho_c", "umidade_pct", "vento_kmh")) d[[nome]] <- .global_num(d[[nome]])
    d <- combinar_observacoes(.global_vazio(), d)
    .global_estado(d, "snapshot inicial", erro)
  }, error = function(e) .global_estado(erro = paste(c(erro, paste("Entrada rejeitada:", conditionMessage(e))), collapse = "; ")))
}
# Transporte isolado para testes locais; a producao usa somente libcurl do R.
.global_baixar <- function(url, arquivo, timeout) {
  op <- options(timeout = timeout, HTTPUserAgent = "AV2-meteorologia-academica/1.0")
  on.exit(options(op), add = TRUE)
  resultado <- utils::download.file(url, arquivo, method = "libcurl", mode = "wb", quiet = TRUE)
  if (resultado != 0L || !file.exists(arquivo) || file.info(arquivo)$size == 0) stop("Download vazio ou incompleto")
  invisible(arquivo)
}
.global_salvar <- function(estado, arquivo) {
  temporario <- tempfile("historico-", tmpdir = dirname(arquivo))
  on.exit(unlink(temporario), add = TRUE)
  saveRDS(estado, temporario)
  if (!file.rename(temporario, arquivo)) stop("Nao foi possivel substituir cache atomicamente; cache anterior preservado")
  invisible(estado)
}
.global_adquirir <- function(raiz, url, provedor, normalizar, timeout) {
  pasta <- file.path(raiz, "dados", "coletas")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  arquivo <- tempfile(paste0(provedor, "-", format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "-"),
    tmpdir = pasta, fileext = if (provedor == "NOAA") ".json" else ".csv")
  inicio <- Sys.time()
  erro <- NULL
  dados <- tryCatch({
    .global_baixar(url, arquivo, timeout)
    normalizar(arquivo)
  }, error = function(e) { erro <<- conditionMessage(e); NULL })
  saveRDS(list(url = url, provedor = provedor, tentativa_em = inicio, concluido_em = Sys.time(),
               arquivo = basename(arquivo), erro = erro), paste0(arquivo, ".metadados.rds"))
  if (!is.null(erro)) stop(erro)
  if (!nrow(dados)) stop("Resposta sem observacoes das estacoes solicitadas")
  dados
}
atualizar_global <- function(raiz, forcar = FALSE) {
  estado <- carregar_global(raiz)
  recente <- function(t, limite) length(t) == 1L && !is.na(t) && as.numeric(difftime(Sys.time(), t, units = "secs")) < limite
  if (!forcar && recente(estado$tentativa_em, 300)) return(estado)
  pasta <- file.path(raiz, "cache")
  if (!dir.exists(pasta) && !dir.create(pasta, recursive = TRUE, showWarnings = FALSE)) {
    estado$erro <- "Diretorio de cache indisponivel"; return(estado)
  }
  trava <- file.path(pasta, "coleta.lock")
  if (dir.exists(trava) && as.numeric(difftime(Sys.time(), file.info(trava)$mtime, units = "secs")) > 180) unlink(trava, recursive = TRUE)
  if (!dir.create(trava, showWarnings = FALSE)) return(estado)
  on.exit(unlink(trava, recursive = TRUE), add = TRUE)
  estado <- carregar_global(raiz)
  if (!forcar && recente(estado$tentativa_em, 300)) return(estado)
  dados_anteriores <- estado$dados
  agora <- as.POSIXct(as.numeric(Sys.time()), origin = "1970-01-01", tz = "UTC")
  estado$tentativa_em <- agora
  erros <- character(); sucesso <- FALSE
  ids <- paste(estacoes_globais()$estacao_id, collapse = ",")
  url <- paste0("https://aviationweather.gov/api/data/metar?ids=", ids, "&format=json")
  tryCatch({
    novos <- .global_adquirir(raiz, url, "NOAA", normalizar_noaa, 15)
    estado$dados <- combinar_observacoes(estado$dados, novos)
    sucesso <- TRUE
  }, error = function(e) erros <<- c(erros, paste("NOAA:", conditionMessage(e))))
  tentativa_historico <- attr(estado, "historico_tentativa_em")
  if (!recente(estado$historico_em, 3600) && !recente(tentativa_historico, 3600)) {
    attr(estado, "historico_tentativa_em") <- agora
    inicio <- as.POSIXct("2026-10-14 22:00:00", tz = "UTC")
    if (nrow(dados_anteriores)) inicio <- max(inicio, max(dados_anteriores$observado_em) - 86400)
    fmt <- function(t) format(t, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    parametros <- c(station = ids, data = "tmpf,dwpf,relh,sknt,metar", sts = fmt(inicio), ets = fmt(agora),
                    tz = "UTC", format = "onlycomma", report_type = "3,4", latlon = "yes")
    query <- paste(paste(names(parametros), vapply(parametros, utils::URLencode, character(1), reserved = TRUE), sep = "="), collapse = "&")
    url <- paste0("https://mesonet.agron.iastate.edu/cgi-bin/request/asos.py?", query)
    tryCatch({
      novos <- .global_adquirir(raiz, url, "IEM", normalizar_iem, 60)
      estado$dados <- combinar_observacoes(estado$dados, novos)
      estado$historico_em <- agora
      attr(estado, "historico_erro") <- NULL
      sucesso <- TRUE
    }, error = function(e) attr(estado, "historico_erro") <<- paste("IEM:", conditionMessage(e)))
  }
  erro_historico <- attr(estado, "historico_erro")
  if (length(erro_historico)) erros <- c(erros, erro_historico)
  if (sucesso) { estado$coletado_em <- agora; estado$origem <- "cache NOAA/IEM" }
  estado["erro"] <- list(if (length(erros)) paste(erros, collapse = "; ") else NULL)
  tryCatch(.global_salvar(estado, file.path(pasta, "historico.rds")),
    error = function(e) estado$erro <<- paste(c(estado$erro, conditionMessage(e)), collapse = "; "))
  estado
}
normalizar_noaa <- function(arquivo) {
  x <- jsonlite::fromJSON(arquivo, simplifyDataFrame = TRUE)
  if (!is.data.frame(x) || !nrow(x) || !all(c("icaoId", "obsTime") %in% names(x))) stop("Resposta NOAA vazia ou esquema invalido")
  campo <- function(nome, numero = TRUE) {
    valor <- if (nome %in% names(x)) x[[nome]] else rep(NA, nrow(x))
    if (numero) .global_num(valor) else as.character(valor)
  }
  .global_normalizar(as.character(x$icaoId), as.POSIXct(.global_num(x$obsTime), origin = "1970-01-01", tz = "UTC"),
    campo("temp"), campo("dewp"), campo("wspd"), "NOAA/AWC METAR", campo("rawOb", FALSE))
}
