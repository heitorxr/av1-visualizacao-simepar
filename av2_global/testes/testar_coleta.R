# Fixtures artificiais somente no scratch; nenhuma requisicao de rede.
local({
  args <- commandArgs(FALSE)
  script <- sub("^--file=", "", args[grepl("^--file=", args)])
  raiz <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
  .libPaths(c(file.path(raiz, "..", ".biblioteca"), .libPaths()))
  env <- new.env(parent = globalenv())
  modulo <- file.path(raiz, "R", "coleta.R")
  if (file.exists(modulo)) sys.source(modulo, env)
  opcoes <- options(warn = 2)
  on.exit(options(opcoes), add = TRUE)
  scratch <- file.path(Sys.getenv("LOCALAPPDATA"), "hermes", "cache", "scratch")
  if (!dir.exists(scratch)) stop("Scratch do Hermes indisponivel")
  tmp <- tempfile("global-test-", tmpdir = scratch)
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  n <- 0L
  testar <- function(nome, codigo) { force(codigo); n <<- n + 1L; cat("OK:", nome, "\n") }
  falha <- function(expr) {
    erro <- tryCatch({ force(expr); NULL }, error = conditionMessage)
    stopifnot(is.character(erro), length(erro) == 1L, nzchar(erro))
  }
  json <- file.path(tmp, "noaa.json")
  writeLines('[{"icaoId":"SBSP","obsTime":1792404000,"temp":20,"dewp":10,"wspd":0,"rawOb":"TEST ONLY"},{"icaoId":"SBST","obsTime":1792404000,"temp":null,"dewp":null,"wspd":null},{"icaoId":"XXXX","obsTime":1792404000},{"icaoId":"SBGR","obsTime":9999999999}]', json)
  testar("NOAA normaliza unidades, ausencias, estacoes e umidade derivada", {
    stopifnot(is.function(env$normalizar_noaa))
    d <- env$normalizar_noaa(json)
    stopifnot(nrow(d) == 2L, all(c("observado_em", "ponto_orvalho_c", "metar") %in% names(d)),
              identical(d$estacao, c("São Paulo", "Guarujá")), d$vento_kmh[1] == 0,
              is.na(d$umidade_pct[2]), is.na(d$vento_kmh[2]),
              abs(d$umidade_pct[1] - 100 * exp(17.625*10/(243.04+10)-17.625*20/(243.04+20))) < 1e-10,
              inherits(d$observado_em, "POSIXct"), attr(d$observado_em, "tzone") == "UTC")
    stopifnot(identical(env$estacoes_globais()$estacao_id, c("SBSP", "SBGR", "SBKP", "SBSJ", "SBST")))
    writeLines('[]', json); falha(env$normalizar_noaa(json))
    writeLines('{"error":"bad"}', json); falha(env$normalizar_noaa(json))
  })
  csv <- file.path(tmp, "iem.csv")
  writeLines(c('station,valid,tmpf,dwpf,relh,sknt,metar', 'SBSP,2026-10-19 10:00,68,50,999,10,TEST ONLY', 'SBGR,2026-10-19 10:20,M,M,M,0,TEST ONLY'), csv)
  testar("IEM converte Fahrenheit e nos e recalcula RH sem relh", {
    stopifnot(is.function(env$normalizar_iem))
    iem <- env$normalizar_iem(csv)
    stopifnot(nrow(iem) == 2L, iem$temperatura_c[1] == 20,
      iem$ponto_orvalho_c[1] == 10, iem$vento_kmh[1] == 18.52,
      is.na(iem$umidade_pct[2]), iem$vento_kmh[2] == 0,
      abs(iem$umidade_pct[1] - 100*exp(17.625*10/253.04-17.625*20/263.04)) < 1e-10)
    writeLines('station,valid', csv); falha(env$normalizar_iem(csv))
    writeLines(c('station,valid,tmpf', 'SBSP,nonsense,wrong'), csv); falha(env$normalizar_iem(csv))
  })
  writeLines(c('station,valid,tmpf,dwpf,sknt', 'SBSP,2026-10-19 10:00,68,50,10', 'SBSP,2026-10-19 10:55,69.8,50,0', 'SBSP,2026-10-19 11:05,68,50,0'), csv)
  d <- env$normalizar_iem(csv)
  testar("agregacao escolhe ultima observacao real da hora UTC", {
    stopifnot(is.function(env$agregar_horas_globais))
    h <- env$agregar_horas_globais(d[c(3,1,2), ])
    stopifnot(nrow(h) == 2L, h$temperatura_c[1] == 21,
      identical(as.numeric(h$observado_em), as.numeric(d$observado_em[c(2,3)])),
      all(as.numeric(h$instante) %% 3600 == 0),
      h$datahora[1] == "19/10/2026 07:00", attr(h$instante, "tzone") == "America/Sao_Paulo")
  })
  testar("uniao imutavel idempotente completa NA rejeita conflitos ambientais", {
    stopifnot(is.function(env$combinar_observacoes))
    a <- d[1, ]; a$temperatura_c <- NA_real_; a$umidade_pct <- NA_real_
    b <- d[1, ]; b$fonte <- "outra origem"; b$metar <- "outro metadado"
    u <- env$combinar_observacoes(a, b)
    stopifnot(nrow(u) == 1L, u$temperatura_c == 20, u$fonte == a$fonte,
      identical(env$combinar_observacoes(u, b), u),
      nrow(env$combinar_observacoes(d, d)) == 3L)
    b$temperatura_c <- 30; falha(env$combinar_observacoes(d, b))
    b <- d[1, ]; b$vento_kmh <- b$vento_kmh + 1e-9
    stopifnot(identical(env$combinar_observacoes(d, b), d))
    b$estacao_id <- "XXXX"; falha(env$combinar_observacoes(d, b))
  })
  testar("carregar usa vazio tipado, CSV inicial e cache valido; cache corrompido recua", {
    stopifnot(is.function(env$carregar_global))
    estado <- env$carregar_global(tmp)
    stopifnot(nrow(estado$dados) == 0L, inherits(estado$dados$observado_em, "POSIXct"),
      identical(names(estado), c("dados", "origem", "coletado_em", "tentativa_em", "historico_em", "erro")))
    dir.create(file.path(tmp, "dados", "entrada"), recursive = TRUE)
    inicial <- d
    for (nome in c("observado_em", "instante")) inicial[[nome]] <- format(inicial[[nome]], "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    write.csv(inicial, file.path(tmp, "dados", "entrada", "observacoes_iniciais.csv"), row.names = FALSE)
    estado <- env$carregar_global(tmp)
    stopifnot(isTRUE(all.equal(estado$dados, d, tolerance = 1e-12)), estado$origem == "snapshot inicial")
    dir.create(file.path(tmp, "cache"))
    estado$origem <- "cache persistente"
    saveRDS(estado, file.path(tmp, "cache", "historico.rds"))
    stopifnot(env$carregar_global(tmp)$origem == "cache persistente")
    writeLines('corrupt', file.path(tmp, "cache", "historico.rds"))
    estado <- env$carregar_global(tmp)
    stopifnot(isTRUE(all.equal(estado$dados, d, tolerance = 1e-12)), nzchar(estado$erro))
    unlink(file.path(tmp, "cache", "historico.rds"))
  })
  testar("atualizar persiste respostas e status, limita chamadas e isola falha IEM", {
    stopifnot(is.function(env$atualizar_global))
    chamadas <- character()
    env$.global_baixar <- function(url, arquivo, timeout) {
      chamadas <<- c(chamadas, url)
      if (grepl('aviationweather', url)) {
        writeLines('[{"icaoId":"SBGR","obsTime":1792404000,"temp":20,"dewp":10,"wspd":0}]', arquivo)
      } else stop("IEM indisponivel (teste)")
      invisible(arquivo)
    }
    antes <- env$carregar_global(tmp)
    resultado <- env$atualizar_global(tmp)
    stopifnot(nrow(resultado$dados) == nrow(antes$dados) + 1L,
      !is.na(resultado$coletado_em), !is.na(resultado$tentativa_em),
      is.na(resultado$historico_em), grepl('IEM', resultado$erro), length(chamadas) == 2L,
      identical(env$carregar_global(tmp), resultado))
    bruto <- list.files(file.path(tmp, 'dados', 'coletas'), recursive = TRUE)
    stopifnot(any(grepl('json$', bruto)), any(grepl('rds$', bruto)))
    stopifnot(identical(env$atualizar_global(tmp), resultado), length(chamadas) == 2L)
    for (i in 1:2) resultado <- env$atualizar_global(tmp, forcar = TRUE)
    stopifnot(length(chamadas) == 4L, nrow(resultado$dados) == nrow(antes$dados) + 1L)
    env$.global_baixar <- function(url, arquivo, timeout) stop('sem rede (teste)')
    falhou <- env$atualizar_global(tmp, forcar = TRUE)
    stopifnot(identical(falhou$dados, resultado$dados),
      identical(falhou$coletado_em, resultado$coletado_em), grepl('sem rede', falhou$erro),
      identical(env$carregar_global(tmp), falhou))
    stopifnot(identical(env$atualizar_global(tmp), falhou))
  })
  testar("historico usa limite do cache anterior, confirma sucesso e preserva cache em falha de escrita", {
    fresco <- file.path(tmp, 'fresco'); dir.create(fresco)
    urls <- character()
    env$.global_baixar <- function(url, arquivo, timeout) {
      urls <<- c(urls, url)
      if (grepl('aviationweather', url)) {
        t <- floor(as.numeric(Sys.time()) - 60)
        writeLines(sprintf('[{"icaoId":"SBST","obsTime":%.0f,"temp":22,"dewp":20,"wspd":1}]', t), arquivo)
      } else writeLines(c('station,valid,tmpf,dwpf,sknt', 'SBSP,2026-10-15 10:00,68,50,0'), arquivo)
    }
    sucesso <- env$atualizar_global(fresco)
    stopifnot(is.null(sucesso$erro), !is.na(sucesso$historico_em), nrow(sucesso$dados) == 2L,
      grepl('sts=2026-10-14T22%3A00%3A00Z', urls[2], fixed = TRUE),
      identical(env$carregar_global(fresco), sucesso))
    salvo <- env$.global_salvar
    env$.global_salvar <- function(estado, arquivo) stop('disco indisponivel (teste)')
    resultado <- env$atualizar_global(fresco, forcar = TRUE)
    stopifnot(grepl('disco indisponivel', resultado$erro), identical(env$carregar_global(fresco), sucesso))
    env$.global_salvar <- salvo
    dir.create(file.path(fresco, 'cache', 'coleta.lock'))
    contagem <- length(urls)
    stopifnot(identical(env$atualizar_global(fresco, forcar = TRUE), sucesso), length(urls) == contagem)
    unlink(file.path(fresco, 'cache', 'coleta.lock'), recursive = TRUE)
  })
  testar("falha historica continua visivel ate sincronizacao bem sucedida", {
    pasta <- file.path(tmp, 'erro-persistente'); dir.create(pasta)
    env$.global_baixar <- function(url, arquivo, timeout) {
      if (!grepl('aviationweather', url)) stop('arquivo IEM indisponivel')
      writeLines('[{"icaoId":"SBGR","obsTime":1792404000,"temp":20,"dewp":10,"wspd":0}]', arquivo)
    }
    primeiro <- env$atualizar_global(pasta)
    segundo <- env$atualizar_global(pasta, forcar = TRUE)
    stopifnot(grepl('IEM', primeiro$erro), is.character(segundo$erro),
      length(segundo$erro) == 1L, grepl('IEM', segundo$erro))
  })
  cat("TOTAL:", n, "testes aprovados\n")
})
