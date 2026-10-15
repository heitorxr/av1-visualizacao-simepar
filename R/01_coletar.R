# Coleta de dados REAIS embutidos nos graficos publicos do SIMEPAR.
# O HTML original e preservado; nao executamos JavaScript da pagina.
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Instale jsonlite: install.packages('jsonlite', repos='https://cloud.r-project.org')")
}
estacoes <- data.frame(
  estacao_id = c("25264916", "25534852", "23185109", "23275159", "25435458"),
  estacao = c("Curitiba", "Paranaguá", "Londrina", "Maringá", "Foz do Iguaçu")
)
base_url <- "https://stage.simepar.br/prognozweb/simepar/dados_estacoes/"
brutos <- file.path(raiz, "dados", "brutos")
entrada <- file.path(raiz, "dados", "entrada")
dir.create(brutos, recursive = TRUE, showWarnings = FALSE)
dir.create(entrada, recursive = TRUE, showWarnings = FALSE)
if (file.exists(file.path(entrada, "dados_publicados.csv"))) {
  stop("Coleta ja congelada. Preserve-a; use outro projeto/ramo para um novo recorte.")
}

extrair_serie <- function(html, nome, coluna) {
  padrao <- paste0("name:\\s*'", nome,
                   "'[\\s\\S]*?data:\\s*(\\[\\[[\\s\\S]*?\\]\\])")
  trecho <- regmatches(html, regexec(padrao, html, perl = TRUE))[[1]]
  if (length(trecho) != 2) stop("Serie nao encontrada: ", nome)
  pares <- jsonlite::fromJSON(trecho[2], simplifyVector = FALSE)
  dados <- data.frame(
    datahora = vapply(pares, function(x) x[[1]], character(1)),
    valor = vapply(pares, function(x) if (is.null(x[[2]])) NA_real_ else as.numeric(x[[2]]), numeric(1))
  )
  if (anyDuplicated(dados$datahora)) stop("Horario duplicado na serie ", nome)
  names(dados)[2] <- coluna
  dados
}

bases <- list()
fontes <- list()
for (i in seq_len(nrow(estacoes))) {
  id <- estacoes$estacao_id[i]
  url <- paste0(base_url, id)
  destino <- file.path(brutos, paste0(id, ".html"))
  if (!file.exists(destino)) {
    temporario <- paste0(destino, ".part")
    download.file(url, temporario, method = "libcurl", mode = "wb", quiet = TRUE)
    if (!file.rename(temporario, destino)) stop("Falha ao preservar HTML.")
  }
  html <- paste(readLines(destino, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  if (!grepl(paste0("Gráficos da Estação ", estacoes$estacao[i]), html, fixed = TRUE)) {
    stop("Estacao ou pagina inesperada: ", id)
  }
  temperatura <- extrair_serie(html, "Temperatura Média", "temperatura_c")
  umidade <- extrair_serie(html, "Umidade Relativa", "umidade_pct")
  vento <- extrair_serie(html, "Velocidade do Vento", "vento_kmh")
  dados <- Reduce(function(x, y) merge(x, y, by = "datahora", all = TRUE),
                  list(temperatura, umidade, vento))
  dados$estacao_id <- id
  dados$estacao <- estacoes$estacao[i]
  bases[[i]] <- dados
  fontes[[i]] <- data.frame(estacao_id = id, estacao = estacoes$estacao[i], url = url,
                           arquivo = paste0("dados/brutos/", id, ".html"),
                           md5 = unname(tools::md5sum(destino)),
                           coleta_utc = format(Sys.time(), tz = "UTC", usetz = TRUE))
}
dados <- do.call(rbind, bases)
dados$instante <- as.POSIXct(dados$datahora, format = "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
if (anyNA(dados$instante)) stop("Data nao reconhecida.")
dados <- dados[order(dados$estacao, dados$instante), ]
dados$instante <- NULL
write.csv(dados, file.path(entrada, "dados_publicados.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(do.call(rbind, fontes), file.path(entrada, "fontes.csv"), row.names = FALSE, fileEncoding = "UTF-8")
message("Observacoes publicadas: ", nrow(dados))
print(table(dados$estacao))
