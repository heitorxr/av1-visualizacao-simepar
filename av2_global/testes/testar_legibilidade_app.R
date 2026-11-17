script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
source(file.path(raiz, "testes", "testar_servidor.R"), encoding = "UTF-8")
# Só fixtures em memória; nenhuma consulta ou escrita na base real.
shiny::testServer(servidor, {
  session$setInputs(cidades = cadastro$estacao, variavel = "vento_kmh", janela = as.numeric(range(t)),
    comuns = TRUE, automatico = FALSE, diaria = TRUE, frequencias = TRUE)
  session$flushReact()
  if (!exists("serie_visual")) stop("RED: série visual não integrada ao app")
  stopifnot(sum(serie_visual()$n) == nrow(serie()), nrow(serie_visual()) < nrow(serie()),
    sum(frequencias()$n) == nrow(comparaveis()), all(c(".x", ".y") %in% names(por_turno())))
  session$setInputs(click_associacao = list(x = 20.5, y = 82.5))
  if (!grepl("n = 1", output$detalhe_associacao, fixed = TRUE)) stop("RED: toque/clique deve revelar frequência no celular")
  session$setInputs(diaria = FALSE)
  stopifnot(identical(serie_visual()$.y, serie()$vento_kmh))
  # Sem horas comuns, os turnos ainda precisam renderizar a amostra disponível.
  session$setInputs(janela = rep(as.numeric(max(t)), 2))
  session$flushReact()
  stopifnot(nrow(analise()$comparaveis) == 0L, nrow(por_turno()) == 8L,
    sum(por_turno()$n) > 0L, length(output$turnos$src) == 1L,
    grepl("observações comparáveis", output$metricas$html, fixed = TRUE))
})
cat("Legibilidade app: diária/horária, frequências e turnos independentes de horas comuns OK.\n")
# As funções devolvem as mesmas coordenadas usadas pelo hover.
source(file.path(raiz, "testes", "testar_legibilidade.R"), encoding = "UTF-8")
png(tempfile(fileext = ".png"), width = 360, height = 300)
s <- plotar_serie(z, unique(z$estacao), "vento_kmh", diaria = TRUE)
f <- plotar_associacao(z, frequencias = TRUE)
p <- plotar_turnos(a$turnos, "temperatura_c")
dev.off()
stopifnot(is.data.frame(s), sum(s$n) == nrow(z), is.data.frame(f), sum(f$n) == nrow(z),
  identical(p$.y, a$turnos$.y), any(p$n == 0L), any(is.na(p$media)))
cat("Gráficos 360px: coordenadas, contagens e ausência preservadas.\n")
