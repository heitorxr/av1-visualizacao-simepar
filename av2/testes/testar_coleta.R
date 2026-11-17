# Testes offline: fixtures existem somente no scratch e na memoria.
local({
  args <- commandArgs(trailingOnly = FALSE)
  script <- sub("^--file=", "", args[grepl("^--file=", args)])
  raiz <- normalizePath(file.path(dirname(script), "..", ".."), mustWork = TRUE)
  .libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
  modulo <- file.path(raiz, "av2", "R", "coleta.R")
  if (!file.exists(modulo)) stop("RED: modulo de aquisicao ainda nao existe")
  env <- new.env(parent = globalenv())
  sys.source(modulo, envir = env)
  scratch <- file.path(Sys.getenv("LOCALAPPDATA"), "hermes", "cache", "scratch")
  dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
  temporario <- tempfile("av2-testes-", tmpdir = scratch)
  dir.create(file.path(temporario, "dados", "entrada"), recursive = TRUE)
  on.exit(unlink(temporario, recursive = TRUE), add = TRUE)
  arquivos <- file.path(raiz, "dados", "entrada", c("dados_publicados.csv", "fontes.csv"))
  hashes <- tools::md5sum(arquivos)
  file.copy(arquivos, file.path(temporario, "dados", "entrada"))
  n <- 0L
  testar <- function(nome, codigo) {
    force(codigo)
    n <<- n + 1L
    cat("OK:", nome, "\n")
  }
  testar("AV1 preservada com contrato e datas da fonte", {
    base <- env$carregar_base_av2(temporario)
    stopifnot(identical(names(base), c("dados", "origem", "coletado_em", "tentativa_em", "erro")),
              identical(names(base$dados), c("datahora", "temperatura_c", "umidade_pct", "vento_kmh", "estacao_id", "estacao", "instante")),
              identical(base$origem, "Coleta preservada da AV1"),
              inherits(base$dados$instante, "POSIXct"),
              identical(attr(base$dados$instante, "tzone"), "America/Sao_Paulo"),
              identical(format(base$coletado_em, tz = "UTC"), "2026-10-15 22:59:19"),
              is.na(base$tentativa_em), is.null(base$erro), nrow(base$dados) > 0L,
              identical(unname(tools::md5sum(arquivos)), unname(hashes)))
  })
  agora <- as.POSIXct("2026-10-16 12:00:00", tz = "UTC")
  igual_preservado <- function(x) {
    stopifnot(identical(x$dados, base$dados), identical(x$origem, base$origem),
              identical(x$coletado_em, base$coletado_em), identical(x$tentativa_em, agora),
              is.character(x$erro), length(x$erro) == 1L, nzchar(x$erro))
  }
  testar("falha de rede injetada preserva base", {
    x <- env$atualizar_base_av2(base, temporario, buscar = function() stop("rede de teste indisponivel"), agora = agora)
    igual_preservado(x)
    stopifnot(grepl("rede de teste", x$erro), !dir.exists(file.path(temporario, "av2", "cache")))
  })
  # Fixture sintetica apenas para testes, nunca representa coleta real.
  fixture <- base$dados
  fixture$instante <- fixture$instante + 3600
  fixture$datahora <- format(fixture$instante, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
  testar("sucesso com fixture exclusiva de teste grava cache", {
    atual <- env$atualizar_base_av2(base, temporario, buscar = function() fixture, agora = agora)
    stopifnot(is.null(atual$erro), identical(atual$dados, fixture),
              identical(atual$coletado_em, agora), identical(atual$tentativa_em, agora),
              !identical(atual$origem, base$origem))
    cache <- file.path(temporario, "av2", "cache", "ultima_coleta.rds")
    stopifnot(file.exists(cache), identical(readRDS(cache), atual),
              identical(env$carregar_base_av2(temporario), atual))
  })
  rejeitar <- function(dados) {
    antes <- readBin(cache, "raw", n = file.info(cache)$size)
    igual_preservado(env$atualizar_base_av2(base, temporario, buscar = function() dados, agora = agora))
    stopifnot(identical(antes, readBin(cache, "raw", n = file.info(cache)$size)))
  }
  testar("candidato parcial nao substitui base", {
    rejeitar(fixture[fixture$estacao != "Curitiba", ])
    d <- fixture; d$umidade_pct[d$estacao == "Curitiba"] <- NA_real_; rejeitar(d)
  })
  testar("validade de IDs nomes horarios duplicatas e limites", {
    d <- fixture; d$estacao_id[1] <- "00000000"; rejeitar(d)
    d <- fixture; d$estacao[1] <- "Nome errado"; rejeitar(d)
    d <- fixture; d$datahora[1] <- "31/02/2026 19:00"; rejeitar(d)
    d <- fixture; d$datahora[1] <- "15/10/2026 25:00"; rejeitar(d)
    d <- fixture; d$instante[1] <- d$instante[1] + 60; rejeitar(d)
    rejeitar(rbind(fixture, fixture[1, ]))
    for (valor in c(-1, 101, Inf, NaN)) { d <- fixture; d$umidade_pct[1] <- valor; rejeitar(d) }
    for (valor in c(-1, 401, Inf)) { d <- fixture; d$vento_kmh[1] <- valor; rejeitar(d) }
    d <- fixture; d$temperatura_c[1] <- Inf; rejeitar(d)
    d <- fixture; d$vento_kmh <- as.character(d$vento_kmh); rejeitar(d)
    d <- fixture; d$extra <- 1; rejeitar(d)
  })
  testar("regressao por estacao futuro e ausencia de novidade", {
    rejeitar(base$dados)
    d <- fixture; i <- d$estacao == "Curitiba"; d$instante[i] <- d$instante[i] - 7200
    d$datahora <- format(d$instante, "%d/%m/%Y %H:%M"); rejeitar(d)
    d <- fixture; d$instante <- d$instante + 10 * 86400
    d$datahora <- format(d$instante, "%d/%m/%Y %H:%M"); rejeitar(d)
  })
  testar("faltantes permanecem faltantes", {
    d <- fixture; d$vento_kmh[1] <- NA_real_
    x <- env$atualizar_base_av2(base, temporario, buscar = function() d, agora = agora)
    stopifnot(is.null(x$erro), is.na(x$dados$vento_kmh[1]), identical(d, x$dados))
  })
  testar("cache corrompido ou semanticamente invalido retorna AV1", {
    writeBin(charToRaw("nao e RDS"), cache)
    stopifnot(identical(env$carregar_base_av2(temporario), base))
    invalido <- atual; invalido$dados$estacao[1] <- "Intruso"; saveRDS(invalido, cache)
    stopifnot(identical(env$carregar_base_av2(temporario), base))
    invalido <- atual; invalido$coletado_em <- as.POSIXct("2100-01-01", tz = "UTC"); saveRDS(invalido, cache)
    stopifnot(identical(env$carregar_base_av2(temporario), base))
    invalido <- atual; invalido$dados <- base$dados; saveRDS(invalido, cache)
    stopifnot(identical(env$carregar_base_av2(temporario), base))
  })
  testar("CSV bruto e fontes nunca mudam", {
    stopifnot(identical(unname(tools::md5sum(arquivos)), unname(hashes)),
              identical(unname(tools::md5sum(file.path(temporario, "dados", "entrada", basename(arquivos)))), unname(hashes)))
  })
  testar("erro durante gravacao nao destroi ultimo cache valido", {
    saveRDS(atual, cache)
    antes <- readBin(cache, "raw", n = file.info(cache)$size)
    env$saveRDS <- function(object, file, ...) {
      writeBin(charToRaw("gravacao interrompida de teste"), file)
      stop("disco de teste indisponivel")
    }
    x <- env$atualizar_base_av2(base, temporario, buscar = function() fixture, agora = agora)
    igual_preservado(x)
    stopifnot(identical(antes, readBin(cache, "raw", n = file.info(cache)$size)))
    rm("saveRDS", envir = env)
  })
  testar("download usa timeout curto e limpa temporario ao falhar", {
    destino_visto <- NULL
    timeout_antes <- getOption("timeout")
    env$download.file <- function(url, destfile, method, mode, quiet) {
      destino_visto <<- destfile
      stopifnot(getOption("timeout") <= 8, identical(method, "libcurl"),
                identical(mode, "wb"), isTRUE(quiet),
                startsWith(normalizePath(dirname(destfile)), normalizePath(scratch)))
      writeLines("bloqueio de teste", destfile)
      stop("HTTP 403 simulado")
    }
    opcoes <- options(av2.pasta_temporaria = scratch)
    mensagem <- tryCatch(env$.baixar_pagina_av2("https://www.simepar.br/simepar/dados_estacoes/25264916"),
                         error = conditionMessage, finally = options(opcoes))
    stopifnot(grepl("403", mensagem), !is.null(destino_visto), !file.exists(destino_visto),
              identical(getOption("timeout"), timeout_antes))
    rm("download.file", envir = env)
  })
  testar("coletor para no primeiro bloqueio sem rede real", {
    chamadas <- character()
    env$.baixar_pagina_av2 <- function(url) { chamadas <<- c(chamadas, url); stop("HTTP 403: bloqueio de teste") }
    falha <- tryCatch(env$coletar_estacoes_av2(), error = conditionMessage)
    stopifnot(is.character(falha), grepl("403", falha), length(chamadas) == 1L,
              identical(chamadas, "https://www.simepar.br/simepar/dados_estacoes/25264916"))
  })
  html_fixture <- function(url) {
    id <- basename(url)
    d <- fixture[fixture$estacao_id == id, ][1:3, ]
    serie <- function(nome, valores, horarios = d$datahora[1:2]) {
      pares <- Map(function(h, v) list(h, if (is.na(v)) NULL else v), horarios, valores)
      paste0("name: '", nome, "', data: ", jsonlite::toJSON(unname(pares), auto_unbox = TRUE, null = "null"))
    }
    nome <- gsub("á", "&aacute;", gsub("ç", "&ccedil;", d$estacao[1], fixed = TRUE), fixed = TRUE)
    paste0('<option value="', id, '" selected="selected">', nome, '</option>',
           serie("Temperatura Média", c(20, 21)),
           serie("Umidade Relativa", c(80, 81, 82), d$datahora),
           serie("Velocidade do Vento", c(NA_real_, 3)))
  }
  testar("series HTML de teste preservam null e horarios desencontrados", {
    env$.baixar_pagina_av2 <- html_fixture
    d <- env$coletar_estacoes_av2()
    stopifnot(nrow(d) == 15L, length(unique(d$estacao_id)) == 5L,
              sum(is.na(d$vento_kmh)) == 10L, sum(is.na(d$temperatura_c)) == 5L,
              all(d$umidade_pct %in% c(80, 81, 82)))
  })
  testar("HTML com ID ou nome errado serie ausente e duplicata e rejeitado", {
    for (tipo in c("id", "nome", "serie", "duplicata")) {
      env$.baixar_pagina_av2 <- function(url) {
        h <- html_fixture(url)
        switch(tipo,
               id = sub("25264916", "00000000", h, fixed = TRUE),
               nome = sub("Curitiba", "Intruso", h, fixed = TRUE),
               serie = sub("Temperatura Média", "Outro", h, fixed = TRUE),
               duplicata = gsub(fixture$datahora[2], fixture$datahora[1], h, fixed = TRUE))
      }
      mensagem <- tryCatch({ env$coletar_estacoes_av2(); NULL }, error = conditionMessage)
      stopifnot(is.character(mensagem), length(mensagem) == 1L, nzchar(mensagem))
    }
  })
  testar("datas UTC e locais podem ser comparadas sem avisos", {
    opcoes <- options(warn = 2)
    tryCatch({
      local_agora <- as.POSIXct(format(agora, tz = "America/Sao_Paulo"), tz = "America/Sao_Paulo")
      x <- env$atualizar_base_av2(base, temporario, buscar = function() fixture, agora = local_agora)
      stopifnot(is.null(x$erro), identical(x$dados, fixture),
                identical(env$carregar_base_av2(temporario)$dados, fixture))
    }, finally = options(opcoes))
  })
  testar("HTMLs preservados da AV1 reproduzem CSV sem rede", {
    env$.baixar_pagina_av2 <- function(url) {
      paste(readLines(file.path(raiz, "dados", "brutos", paste0(basename(url), ".html")),
                      encoding = "UTF-8", warn = FALSE), collapse = "\n")
    }
    ordenar <- function(d) {
      d <- d[order(d$estacao_id, d$instante), ]
      rownames(d) <- NULL
      d
    }
    stopifnot(identical(ordenar(env$coletar_estacoes_av2()), ordenar(base$dados)))
  })
  testar("assinaturas publicas permanecem exatas", {
    stopifnot(identical(names(formals(env$carregar_base_av2)), "raiz"),
              identical(names(formals(env$atualizar_base_av2)), c("base", "raiz", "buscar", "agora")),
              identical(formals(env$atualizar_base_av2)$buscar, quote(coletar_estacoes_av2)),
              identical(formals(env$atualizar_base_av2)$agora, quote(Sys.time())),
              length(formals(env$coletar_estacoes_av2)) == 0L)
  })
  cat("PASS:", n, "testes offline\n")
})
