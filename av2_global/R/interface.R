pasta_interface <- if (exists("raiz_global")) file.path(raiz_global, "R") else {
  arquivos_fonte <- Filter(Negate(is.null), lapply(sys.frames(), function(quadro) quadro$ofile))
  dirname(normalizePath(tail(arquivos_fonte, 1)[[1]], winslash = "/"))
}
css_global <- file.path(dirname(pasta_interface), "estilo.css")

`%||%` <- function(x, y) if (is.null(x)) y else x

hora_global <- function(x) {
  if (!length(x) || all(is.na(x))) return("não disponível")
  format(x, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
}
numero_global <- function(x, casas = 1) {
  if (!length(x) || !is.finite(x[1])) return("—")
  formatC(x[1], format = "f", digits = casas, decimal.mark = ",")
}

criar_ui_global <- function(inicial, cadastro) {
  horas <- as.POSIXct(floor(as.numeric(inicial$dados$observado_em) / 3600) * 3600, origin = "1970-01-01", tz = "America/Sao_Paulo")
  limites <- range(horas)
  fluidPage(
    tags$head(includeCSS(css_global)),
    div(id = "aviso-conexao", role = "alert", div(strong("Conexão com o painel interrompida"), p("Recarregue para reconectar ao servidor.")),
        tags$button(type = "button", class = "btn btn-primary", onclick = "window.location.reload()", "Recarregar painel")),
    h1("São Paulo em observação"),
    p(class = "subtitulo", "Cinco cidades próximas · observações METAR em aeroportos · NOAA/AWC e arquivo IEM · R + Shiny"),
    uiOutput("situacao"),
    div(class = "barra-filtros",
      div(class = "controles",
        div(checkboxGroupInput("cidades", "Cidades / estações", choices = cadastro$estacao, selected = cadastro$estacao, inline = TRUE)),
        div(selectInput("variavel", "Variável para comparar", choices = setNames(names(rotulos_av2), unname(rotulos_av2)))),
        div(sliderInput("janela", "Período das horas de referência · Brasília", min = limites[1], max = limites[2], value = limites,
                        step = 3600, ticks = FALSE, timeFormat = "%d/%m %H:%M", timezone = "-0300"))),
      div(class = "acoes",
        checkboxInput("comuns", "Comparar somente horas completas comuns", TRUE),
        checkboxInput("automatico", "Consultar atualizações a cada 5 minutos", TRUE),
        actionButton("atualizar", "Atualizar agora", class = "btn-primary"), downloadButton("baixar", "Baixar recorte CSV")),
      tags$details(class = "ajuda-filtros", tags$summary("O que significa próximo do tempo real?"),
        p("O painel consulta a NOAA a cada cinco minutos enquanto estiver aberto. Isso não cria novas medições: os boletins são geralmente horários e algumas estações têm operação limitada. O histórico IEM é verificado no máximo uma vez por hora; sua ingestão também tem atraso."),
        p("As leituras são de aeroportos, não médias de toda a cidade. Umidade relativa é derivada da temperatura e do ponto de orvalho. Sem observação válida, o valor permanece ausente; não usamos previsões nem interpolação."))),
    div(class = "conteudo", uiOutput("metricas"), uiOutput("legenda"),
      tabsetPanel(
        tabPanel("Explorar", div(class = "grade-graficos",
          div(class = "painel", h3(textOutput("titulo_serie")), checkboxInput("diaria", "Resumir por dia (média das horas disponíveis)", TRUE), plotOutput("serie", height = "300px", click = "click_serie", hover = hoverOpts("hover_serie", delay = 80)),
              div(class = "detalhe", textOutput("detalhe_serie")), p(class = "nota", "Média diária por cidade; o hover informa n e mínimo–máximo. Desmarque para ver cada hora original. Dias/horas sem observações interrompem as linhas; dias parciais não representam 24 horas. Tabela e CSV mantêm as horas originais.")),
          div(class = "painel", h3("Medianas e dispersão"), plotOutput("comparacao", height = "300px", hover = hoverOpts("hover_comparacao", delay = 80)),
              div(class = "detalhe", textOutput("detalhe_comparacao")), p(class = "nota", "Ponto: mediana. Faixa grossa: Q1–Q3. Linha fina: mínimo e máximo; não é intervalo de confiança.")),
          div(class = "painel", h3("Temperatura e umidade derivada"), checkboxInput("frequencias", "Agrupar em células de frequência", TRUE), plotOutput("associacao", height = "360px", click = "click_associacao", hover = hoverOpts("hover_associacao", delay = 80)),
              div(class = "detalhe", textOutput("detalhe_associacao")), p(class = "nota", "Células de 1 °C × 5 pontos percentuais: azul mais escuro = maior frequência (escala log). Branco = nenhuma. Números aparecem quando cabem. Toque/clique ou passe o mouse para ver n, faixas e cidades. Desmarque para ver os pontos originais, sem deslocamento. Correlação descreve associação, não causalidade. A umidade deriva de temperatura e ponto de orvalho; há dependência matemática entre as variáveis.")),
          div(class = "painel", h3(textOutput("titulo_turnos")), plotOutput("turnos", height = "280px", click = "click_turnos", hover = hoverOpts("hover_turnos", delay = 80)),
              div(class = "detalhe", textOutput("detalhe_turnos")), p(class = "nota", "Cada célula mostra média e n das horas disponíveis da variável, independentemente do filtro de horas comuns. Madrugada 00–05h; manhã 06–11h; tarde 12–17h; noite 18–23h (Brasília). Sem obs., n=0: média ausente (NA), nunca zero. Vento zero é uma leitura válida.")))),
        tabPanel("Atualização e fontes", div(class = "painel", h3("Último boletim por estação · Brasília"), div(class = "dados-tabela", tableOutput("ultimos")),
            p(class = "nota", "Recente: boletim com até duas horas de idade. A data da consulta não substitui a data da observação. Uma estação pode deixar de emitir boletins à noite.")),
          div(class = "painel", h3("Fontes e transformações"),
            p("Observações recentes: NOAA / National Weather Service / Aviation Weather Center. Histórico dos mesmos códigos ICAO: Iowa Environmental Mesonet, Iowa State University. Os boletins brasileiros são emitidos pela rede meteorológica aeronáutica; não são dados SIMEPAR."),
            tags$a(href = "https://aviationweather.gov/data/api/", target = "_blank", rel = "noopener", "Documentação da API NOAA/AWC"), tags$br(),
            tags$a(href = "https://mesonet.agron.iastate.edu/request/download.phtml", target = "_blank", rel = "noopener", "Arquivo histórico e limitações do IEM"),
            p("Temperatura: °C; arquivo IEM convertido de °F. Vento: nós × 1,852 = km/h. Umidade: 100 × exp[17,625 Td/(243,04 + Td) − 17,625 T/(243,04 + T)], com T e Td em °C; é uma estimativa derivada, não uma terceira leitura independente."),
            tags$a(href = "https://qed.epa.gov/hms/meteorology/humidity/algorithms", target = "_blank", rel = "noopener", "Referência da fórmula de umidade — US EPA"),
            p("A análise escolhe o último boletim por estação e hora, mantendo o horário original no CSV. Horas comuns são janelas comparáveis, não observações necessariamente simultâneas. Selecionar somente horas comuns pode privilegiar o período diurno de estações com operação limitada."),
            p("O IEM redistribui observações com controle de qualidade limitado. Este painel descreve o período disponível, não o clima nem a média espacial das cidades. Horas sucessivas não são independentes."),
            p(class = "nota", "Construído em R e Shiny com assistência de IA; cálculos e código disponíveis para revisão e compreensão do autor."))),
        tabPanel("Dados e análise", div(class = "painel", h3("Cobertura do recorte"), textOutput("qualidade")),
          div(class = "painel", h3("Correlação global e por estação"), tableOutput("correlacoes")),
          div(class = "painel", h3("Último boletim em cada hora de referência"), div(class = "dados-tabela", tableOutput("tabela")))))))
}

criar_servidor_global <- function(raiz, inicial, buscar, agrupar, cadastro, intervalo = 300000) {
  function(input, output, session) {
    base <- reactiveVal(inicial)
    limites <- range(agrupar(inicial$dados)$instante)
    limites_anteriores <- reactiveVal(limites)
    observe({
      req(isTRUE(input$automatico))
      invalidateLater(intervalo, session)
      # O coletor compartilha o cache e limita a frequência mesmo com várias sessões.
      base(buscar(raiz, forcar = FALSE))
    })
    observeEvent(input$atualizar, {
      withProgress(message = "Consultando observações METAR", value = 0.5, base(buscar(raiz, forcar = TRUE)))
    }, ignoreInit = TRUE)
    observeEvent(base(), {
      novos <- range(agrupar(base()$dados)$instante)
      antigos <- isolate(limites_anteriores())
      if (!identical(novos, antigos)) {
        # Se o filtro seguia o fim do histórico, acompanha a nova hora sem ampliar um recorte histórico escolhido.
        atual <- isolate(input$janela)
        valor <- if (length(atual) == 2L) as.POSIXct(atual, origin = "1970-01-01", tz = "America/Sao_Paulo") else novos
        if (length(atual) == 2L && as.numeric(valor[2]) == as.numeric(antigos[2])) valor[2] <- novos[2]
        updateSliderInput(session, "janela", min = novos[1], max = novos[2], value = valor,
                          timeFormat = "%d/%m %H:%M", timezone = "-0300")
        limites_anteriores(novos)
      }
    })
    analise <- reactive({
      validate(need(length(input$cidades) > 0, "Selecione pelo menos uma cidade."))
      req(length(input$janela) == 2L, input$variavel)
      preparar_analise_global(agrupar(base()$dados), input$cidades,
        as.POSIXct(input$janela[1], origin = "1970-01-01", tz = "America/Sao_Paulo"),
        as.POSIXct(input$janela[2], origin = "1970-01-01", tz = "America/Sao_Paulo"), isTRUE(input$comuns), input$variavel)
    })
    serie <- reactive({ z <- analise()$serie; validate(need(nrow(z) > 0, "Sem observações nesse período.")); z })
    comparaveis <- reactive({ z <- analise()$comparaveis; validate(need(nrow(z) > 0, "Sem horas comuns completas; amplie o período ou desmarque a comparação por horas comuns.")); z })
    serie_visual <- reactive(preparar_serie_visual(serie(), input$variavel, isTRUE(input$diaria)))
    frequencias <- reactive(preparar_frequencias(comparaveis()))
    por_turno <- reactive({ serie(); analise()$turnos })
    output$situacao <- renderUI({
      b <- base(); s <- situacao_estacoes(b$dados, cadastro$estacao)
      recentes <- sum(s$status == "Recente")
      div(class = if (recentes == nrow(cadastro) && is.null(b$erro)) "situacao recente" else "situacao",
        div(strong(paste(recentes, "de", nrow(cadastro), "estações com boletim recente")),
            p(paste("Último boletim:", hora_global(max(b$dados$observado_em)), "· Brasília ·", b$origem))),
        tags$details(tags$summary(if (is.null(b$erro)) "Datas das consultas" else "Atualização com ressalva — detalhes"),
          p(paste("Última coleta:", hora_global(b$coletado_em), "· tentativa:", hora_global(b$tentativa_em))),
          p(paste("Arquivo histórico consultado:", hora_global(b$historico_em))),
          if (!is.null(b$erro)) p(b$erro)))
    })
    output$metricas <- renderUI({
      z <- serie(); c <- analise()$comparaveis
      div(class = "metricas",
        div(class = "metrica", strong(nrow(z)), span("boletins selecionados na série horária")),
        div(class = "metrica", strong(nrow(c)), span("observações comparáveis"), tags$small(paste(length(unique(c$instante)), "horas de referência"))),
        div(class = "metrica", strong(numero_global(correlacao_segura(c$temperatura_c, c$umidade_pct), 3)), span("correlação global de Spearman"), tags$small("temperatura × umidade derivada")))
    })
    output$legenda <- renderUI(div(class = "legenda", lapply(input$cidades, function(cidade)
      tags$span(class = "legenda-item", tags$span(class = "simbolo", style = paste0("color:", cores_av2[[cidade]]), simbolos_av2[[cidade]]), cidade))))
    output$titulo_serie <- renderText(paste(rotulos_av2[[input$variavel]], if (isTRUE(input$diaria)) "· médias diárias" else "· último boletim por hora"))
    output$titulo_turnos <- renderText(paste("Médias por turno ·", rotulos_av2[[input$variavel]]))
    largura <- function(id) max(320, session$clientData[[paste0("output_", id, "_width")]], na.rm = TRUE)
    output$serie <- renderPlot(plotar_serie(serie(), input$cidades, input$variavel, isTRUE(input$diaria)), width = function() largura("serie"), res = 100, execOnResize = TRUE)
    output$comparacao <- renderPlot({ comparaveis(); plotar_comparacao(analise()$resumo, input$variavel) }, width = function() largura("comparacao"), res = 100, execOnResize = TRUE)
    output$associacao <- renderPlot(plotar_associacao(comparaveis(), isTRUE(input$frequencias)), width = function() largura("associacao"), res = 100, execOnResize = TRUE)
    output$turnos <- renderPlot(plotar_turnos(por_turno(), input$variavel), width = function() largura("turnos"), res = 100, execOnResize = TRUE)
    leitura <- function(z) {
      if (!nrow(z)) return("Passe o mouse perto de um ponto.")
      paste(z$estacao[1], "· boletim", hora_global(z$observado_em[1]), "·",
        numero_global(z$temperatura_c), "°C ·", numero_global(z$umidade_pct), "% (derivada) ·", numero_global(z$vento_kmh), "km/h")
    }
    output$detalhe_serie <- renderText({
      z <- nearPoints(serie_visual(), input$hover_serie %||% input$click_serie, xvar = ".x", yvar = ".y", threshold = 15, maxpoints = 1)
      if (!isTRUE(input$diaria)) return(leitura(z))
      if (!nrow(z)) return("Médias diárias · passe o mouse perto de um ponto; horas originais na tabela e no CSV.")
      paste(z$estacao[1], "·", format(z$instante[1], "%d/%m/%Y", tz = "America/Sao_Paulo"),
        "· média", numero_global(z$.y), "· n =", z$n[1], "· mín–máx", numero_global(z$minimo), "a", numero_global(z$maximo))
    })
    output$detalhe_associacao <- renderText({
      if (!isTRUE(input$frequencias)) return(leitura(nearPoints(comparaveis(), input$hover_associacao %||% input$click_associacao, xvar = "temperatura_c", yvar = "umidade_pct", threshold = 15, maxpoints = 1)))
      z <- frequencias(); h <- input$hover_associacao %||% input$click_associacao
      if (is.null(h)) return(paste(sum(z$n), "observações em", nrow(z), "células ocupadas · toque/clique ou passe o mouse sobre uma célula."))
      z <- z[h$x >= z$t_min & h$x < z$t_max & h$y >= z$u_min & (h$y < z$u_max | (h$y == 100 & z$u_max == 100)), , drop = FALSE]
      if (!nrow(z)) return("Nenhuma observação nesta faixa.")
      paste("n =", z$n[1], "· temperatura [", z$t_min[1], ",", z$t_max[1], ") °C · umidade [", z$u_min[1], ",", z$u_max[1], if (z$u_max[1] == 100) "] % ·" else ") % ·", z$cidades[1])
    })
    output$detalhe_comparacao <- renderText({
      comparaveis(); z <- nearPoints(analise()$resumo, input$hover_comparacao, xvar = ".x", yvar = ".y", threshold = 18, maxpoints = 1)
      if (!nrow(z)) return("Passe o mouse perto de uma mediana.")
      paste(z$estacao[1], "· mediana", numero_global(z$mediana), "· Q1", numero_global(z$q1), "· Q3", numero_global(z$q3), "· n =", z$n[1])
    })
    output$detalhe_turnos <- renderText({
      z <- nearPoints(por_turno(), input$hover_turnos %||% input$click_turnos, xvar = ".x", yvar = ".y", threshold = 18, maxpoints = 1)
      if (!nrow(z)) return("Média e n em cada célula · sem obs. = NA, n=0. Passe o mouse para identificar a cidade e o turno.")
      paste(z$estacao[1], "·", z$turno[1], "· média", if (z$n[1] == 0) "NA (sem observações)" else numero_global(z$media), "· n =", z$n[1])
    })
    output$qualidade <- renderText({
      z <- serie()
      esperados <- length(seq(input$janela[1], input$janela[2], by = 3600)) * length(input$cidades)
      paste(nrow(z), "registros em", esperados, "posições estação-hora;", esperados - nrow(z), "posições sem boletim;",
        sum(!complete.cases(z[c("temperatura_c", "umidade_pct", "vento_kmh")])), "boletins incompletos. Horas comuns podem concentrar a comparação no período diurno; não há imputação.")
    })
    output$correlacoes <- renderTable({ comparaveis(); analise()$correlacoes }, digits = 3, striped = TRUE, rownames = FALSE)
    output$tabela <- renderTable({
      z <- serie()
      data.frame(Cidade = z$estacao, ICAO = z$estacao_id, "Hora de referência" = format(z$instante, "%d/%m %H:%M", tz = "America/Sao_Paulo"),
        "Boletim observado" = format(z$observado_em, "%d/%m %H:%M", tz = "America/Sao_Paulo"), "Temperatura °C" = z$temperatura_c,
        "Umidade derivada %" = z$umidade_pct, "Vento km/h" = z$vento_kmh, check.names = FALSE)
    }, striped = TRUE, rownames = FALSE, digits = 1)
    output$ultimos <- renderTable({
      d <- base()$dados; s <- situacao_estacoes(d, cadastro$estacao)
      s <- merge(s, cadastro, by = "estacao", all.x = TRUE, sort = FALSE)
      data.frame(Cidade = s$estacao, ICAO = s$estacao_id, Aeroporto = s$aeroporto,
        "Último boletim" = format(s$observado_em, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo"),
        "Idade (min)" = round(s$atraso_min), Estado = s$status, check.names = FALSE)
    }, striped = TRUE, rownames = FALSE)
    output$baixar <- downloadHandler(filename = function() "metar_cinco_cidades_recorte.csv", content = function(arquivo) {
      z <- serie()
      z$instante <- format(z$instante, "%Y-%m-%dT%H:%M:%S%z", tz = "America/Sao_Paulo")
      z$observado_em <- format(z$observado_em, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      write.csv(z, arquivo, row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
    })
  }
}
