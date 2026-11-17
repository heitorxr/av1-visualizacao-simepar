# O aplicativo pode ser aberto pela pasta av2 ou pela raiz do projeto.
raiz_av2 <- if (file.exists("R/analise.R") && file.exists("../executar.R")) {
  normalizePath(getwd(), winslash = "/")
} else if (file.exists("av2/R/analise.R")) {
  normalizePath("av2", winslash = "/")
} else stop("Execute av2/iniciar.R a partir da pasta do projeto.")
raiz_projeto <- dirname(raiz_av2)
.libPaths(c(file.path(raiz_projeto, ".biblioteca"), .libPaths()))
library(shiny)
source(file.path(raiz_av2, "R", "coleta.R"), local = TRUE, encoding = "UTF-8")
source(file.path(raiz_av2, "R", "analise.R"), local = TRUE, encoding = "UTF-8")
source(file.path(raiz_av2, "R", "graficos.R"), local = TRUE, encoding = "UTF-8")
base_inicial <- carregar_base_av2(raiz_projeto)
limites_iniciais <- range(base_inicial$dados$instante)

formatar_hora <- function(x) {
  if (!length(x) || all(is.na(x))) return("não realizada")
  format(x, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo")
}
formatar_numero <- function(x, casas = 1) {
  if (!length(x) || !is.finite(x[[1]])) return("não calculável")
  formatC(x[[1]], format = "f", digits = casas, decimal.mark = ",")
}

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body{background:#f5f7fa;color:#253342;font-family:Arial,sans-serif} .container-fluid{max-width:1500px;padding:22px}
    h1{font-size:30px;margin:0 0 6px} h3{font-size:19px;margin:0 0 12px}.subtitulo{color:#526071;margin-bottom:20px}
    .well{background:white;border:1px solid #dce2e8;box-shadow:none}.painel{background:white;border:1px solid #dce2e8;border-radius:5px;padding:17px;margin:14px 0}
    .metricas{display:flex;gap:12px;flex-wrap:wrap}.metrica{flex:1;min-width:155px;background:white;border:1px solid #dce2e8;padding:14px;border-radius:5px}.metrica strong{display:block;font-size:26px}.metrica small{color:#526071}
    .situacao{border-left:4px solid #aa6c00;background:#fff5dc;padding:12px 16px;margin:12px 0}.situacao.recente{border-color:#167054;background:#eaf6ef}
    .detalhe{min-height:46px;background:#f4f6f8;border-radius:3px;padding:10px;font-size:14px;color:#334155}
    .legenda{display:flex;flex-wrap:wrap;gap:12px;margin:10px 0}.nota{font-size:13px;color:#526071}.dados-tabela{overflow:auto;max-height:480px}
    .shiny-plot-output{max-width:100%}.nav-tabs{margin-top:14px}label{font-weight:600}pre{white-space:pre-wrap;font-size:13px}
    @media(max-width:760px){.container-fluid{padding:12px}h1{font-size:25px}.painel{padding:10px}.metrica{min-width:130px} .row{margin-right:-8px;margin-left:-8px}}
  "))),
  tags$h1("Paraná em observação"),
  tags$p(class = "subtitulo", "Temperatura, umidade e vento em cinco estações do SIMEPAR · Heitor Cardoso Fernandes · AV2 / CE303"),
  uiOutput("situacao"),
  sidebarLayout(
    sidebarPanel(width = 3,
      checkboxGroupInput("cidades", "Estações", choices = names(cores_av2), selected = names(cores_av2)),
      selectInput("variavel", "Variável para comparar", choices = setNames(names(rotulos_av2), unname(rotulos_av2))),
      sliderInput("janela", "Período das observações", min = limites_iniciais[[1]], max = limites_iniciais[[2]],
        value = limites_iniciais, step = 3600, timeFormat = "%d/%m %H:%M", timezone = "-0300"),
      checkboxInput("comuns", "Comparar somente horários comuns", value = TRUE),
      helpText("A série temporal mostra todas as medidas. As comparações usam, por padrão, horários completos compartilhados pelas estações selecionadas."),
      tags$hr(),
      checkboxInput("automatico", "Tentar atualizar a cada 5 minutos", value = isTRUE(getOption("av2.coleta_automatica", TRUE))),
      actionButton("atualizar", "Atualizar agora", class = "btn-primary"),
      tags$p(class = "nota", "A atualização depende do acesso público ao SIMEPAR. Se falhar, os gráficos mantêm a última coleta válida e sua data."),
      downloadButton("baixar", "Baixar o recorte em CSV")
    ),
    mainPanel(width = 9,
      uiOutput("metricas"),
      uiOutput("legenda"),
      tabsetPanel(
        tabPanel("Explorar",
          div(class = "painel", h3(textOutput("titulo_serie")),
            plotOutput("serie", height = "310px", hover = hoverOpts("hover_serie", delay = 80, delayType = "throttle")),
            div(class = "detalhe", textOutput("detalhe_serie")),
            p(class = "nota", "Passe o mouse perto de um ponto para ver a medida e o horário. Lacunas interrompem as linhas; não há interpolação.")),
          fluidRow(
            column(6, div(class = "painel", h3("Temperatura e umidade"),
              plotOutput("associacao", height = "290px", hover = hoverOpts("hover_associacao", delay = 80, delayType = "throttle")),
              div(class = "detalhe", textOutput("detalhe_associacao")),
              p(class = "nota", "A correlação resume associação por postos; não indica causalidade. As cores permitem reconhecer diferenças entre estações."))),
            column(6, div(class = "painel", h3("Medianas e dispersão"),
              plotOutput("comparacao", height = "290px", hover = hoverOpts("hover_comparacao", delay = 80, delayType = "throttle")),
              div(class = "detalhe", textOutput("detalhe_comparacao")),
              p(class = "nota", "Ponto: mediana. Faixa grossa: Q1–Q3, os 50% centrais. Linha fina: mínimo e máximo observados; não é intervalo de confiança.")))
          ),
          div(class = "painel", h3("Médias por turno"),
            plotOutput("turnos", height = "280px", hover = hoverOpts("hover_turnos", delay = 80, delayType = "throttle")),
            div(class = "detalhe", textOutput("detalhe_turnos")),
            p(class = "nota", "Turnos derivados do relógio: madrugada 00–05h; manhã 06–11h; tarde 12–17h; noite 18–23h."))
        ),
        tabPanel("Dados e método",
          div(class = "painel", h3("Disponibilidade do recorte"), textOutput("qualidade")),
          div(class = "painel", h3("Correlação de Spearman"), tableOutput("correlacoes")),
          div(class = "painel", h3("Observações publicadas"), div(class = "dados-tabela", tableOutput("tabela"))),
          div(class = "painel", h3("Como interpretar"),
            p("As observações são estação × horário. Horas sucessivas não são independentes. O recorte descreve o período exibido, não o clima das cidades."),
            p("O fuso de Brasília é adotado para manter a convenção da AV1; a página histórica não o declarava explicitamente."),
            tags$details(tags$summary("Ver o cálculo da correlação em R"), tags$pre(paste(deparse(correlacao_segura), collapse = "\n"))),
            p(class = "nota", "Construção: R e Shiny. Código desenvolvido com assistência de IA, sujeito à revisão e compreensão do autor."))
        )
      )
    )
  )
)

criar_servidor <- function(raiz, buscar = coletar_estacoes_av2) {
  function(input, output, session) {
    coleta_inicial <- carregar_base_av2(raiz)
    base <- reactiveVal(coleta_inicial)
    limites_atuais <- reactiveVal(range(coleta_inicial$dados$instante))

    # Falhas de rede atualizam o aviso, mas não apagam as medidas dos gráficos.
    tentar_atualizar <- function() {
      base(atualizar_base_av2(isolate(base()), raiz, buscar = buscar))
    }
    observeEvent(input$atualizar, {
      withProgress(message = "Consultando o SIMEPAR", value = 0.5, tentar_atualizar())
    }, ignoreInit = TRUE)
    observe({
      invalidateLater(300000, session)
      if (isTRUE(input$automatico)) isolate(tentar_atualizar())
    })
    observeEvent(base(), {
      novos <- range(base()$dados$instante)
      if (!identical(novos, isolate(limites_atuais()))) {
        updateSliderInput(session, "janela", min = novos[[1]], max = novos[[2]], value = novos)
        limites_atuais(novos)
      }
    })

    recorte <- reactive({
      validate(need(length(input$cidades) > 0, "Selecione pelo menos uma estação."))
      req(length(input$janela) == 2L)
      janela <- as.POSIXct(input$janela, origin = "1970-01-01", tz = "America/Sao_Paulo")
      z <- recortar_dados(base()$dados, input$cidades, janela[[1]], janela[[2]])
      validate(need(nrow(z) > 0, "Não há medidas neste recorte."))
      z
    })
    comparaveis <- reactive({
      z <- recorte()
      if (isTRUE(input$comuns)) z <- selecionar_horarios_comuns(z, input$cidades)
      else z <- z[complete.cases(z[c("temperatura_c", "umidade_pct", "vento_kmh")]), , drop = FALSE]
      validate(need(nrow(z) > 0, "Não há horários completos para comparar. Amplie o período ou selecione menos estações."))
      z
    })
    dados_serie <- reactive({
      z <- recorte()
      z$.x <- as.numeric(z$instante)
      z$.y <- z[[input$variavel]]
      z
    })
    resumo <- reactive(preparar_comparacao(comparaveis(), input$variavel))
    por_turno <- reactive({
      z <- resumir_turnos(comparaveis(), input$variavel)
      z$.x <- as.numeric(z$turno)
      z$.y <- z$media
      z
    })

    output$situacao <- renderUI({
      b <- base()
      recente <- difftime(Sys.time(), max(b$dados$instante), units = "hours") <= 6
      origem <- if (isTRUE(recente)) b$origem else if (identical(b$origem, "Coleta preservada da AV1")) {
        "Coleta preservada da AV1 — dados históricos"
      } else "Última coleta válida do SIMEPAR — dados antigos"
      div(class = if (isTRUE(recente) && is.null(b$erro)) "situacao recente" else "situacao",
        strong(origem),
        p(paste("Observações:", formatar_hora(min(b$dados$instante)), "a", formatar_hora(max(b$dados$instante)), "· horário de Brasília")),
        p(class = "nota", paste("Coleta:", formatar_hora(b$coletado_em), "· última tentativa:", formatar_hora(b$tentativa_em))),
        if (!is.null(b$erro) && nzchar(b$erro)) tags$details(tags$summary("Atualização indisponível: mantendo os dados preservados"), tags$p(b$erro))
      )
    })
    output$metricas <- renderUI({
      z <- recorte()
      c <- comparaveis()
      rho <- correlacao_segura(c$temperatura_c, c$umidade_pct)
      div(class = "metricas",
        div(class = "metrica", strong(nrow(z)), span("observações na série temporal")),
        div(class = "metrica", strong(nrow(c)), span("observações comparáveis"), tags$br(), tags$small(paste(length(unique(c$instante)), "horários no recorte comparativo"))),
        div(class = "metrica", strong(formatar_numero(rho, 3)), span("correlação de Spearman"), tags$br(), tags$small("conjunto selecionado: temperatura × umidade")))
    })
    output$legenda <- renderUI(div(class = "legenda", lapply(input$cidades, function(cidade) tags$span(style = paste0("color:", cores_av2[[cidade]]), paste("●", cidade)))))
    output$titulo_serie <- renderText(paste(rotulos_av2[[input$variavel]], "ao longo do tempo"))
    output$serie <- renderPlot({ req(input$variavel); plotar_serie(recorte(), input$cidades, input$variavel) }, res = 100)
    output$associacao <- renderPlot(plotar_associacao(comparaveis()), res = 100)
    output$comparacao <- renderPlot({ validate(need(nrow(resumo()) > 0, "Sem valores válidos.")); plotar_comparacao(resumo(), input$variavel) }, res = 100)
    output$turnos <- renderPlot(plotar_turnos(por_turno(), input$variavel), res = 100)

    # nearPoints encontra a observação realmente desenhada perto do cursor.
    leitura <- function(z) {
      if (!nrow(z)) return("Passe o mouse perto de um ponto.")
      paste(z$estacao[[1]], "·", formatar_hora(z$instante[[1]]), "·",
        formatar_numero(z$temperatura_c), "°C ·", formatar_numero(z$umidade_pct), "% ·", formatar_numero(z$vento_kmh), "km/h")
    }
    output$detalhe_serie <- renderText(leitura(nearPoints(dados_serie(), input$hover_serie, xvar = ".x", yvar = ".y", threshold = 15, maxpoints = 1)))
    output$detalhe_associacao <- renderText(leitura(nearPoints(comparaveis(), input$hover_associacao, xvar = "temperatura_c", yvar = "umidade_pct", threshold = 15, maxpoints = 1)))
    output$detalhe_comparacao <- renderText({
      z <- nearPoints(resumo(), input$hover_comparacao, xvar = ".x", yvar = ".y", threshold = 18, maxpoints = 1)
      if (!nrow(z)) return("Passe o mouse perto de uma mediana.")
      paste(z$estacao[[1]], "· mediana", formatar_numero(z$mediana), "· Q1", formatar_numero(z$q1), "· Q3", formatar_numero(z$q3), "· n =", z$n[[1]])
    })
    output$detalhe_turnos <- renderText({
      z <- nearPoints(por_turno(), input$hover_turnos, xvar = ".x", yvar = ".y", threshold = 15, maxpoints = 1)
      if (!nrow(z)) return("Passe o mouse perto de uma média.")
      paste(z$estacao[[1]], "·", z$turno[[1]], "· média", formatar_numero(z$media), "· n =", z$n[[1]])
    })

    output$qualidade <- renderText({
      z <- recorte()
      esperados <- length(seq(input$janela[[1]], input$janela[[2]], by = 3600)) * length(input$cidades)
      paste(nrow(z), "registros publicados em", esperados, "posições estação-hora possíveis;", esperados - nrow(z),
        "ausências de registro. Comparação:", if (isTRUE(input$comuns)) "horários completos em todas as estações selecionadas." else "todas as observações completas, sem igualar horários entre estações.")
    })
    output$correlacoes <- renderTable({
      z <- comparaveis()
      grupos <- c(list("Conjunto selecionado" = z), split(z, z$estacao))
      do.call(rbind, lapply(names(grupos), function(nome) {
        g <- grupos[[nome]]
        data.frame(Estação = nome, Pares = nrow(g), Spearman = formatar_numero(correlacao_segura(g$temperatura_c, g$umidade_pct), 3), check.names = FALSE)
      }))
    }, striped = TRUE, bordered = FALSE, rownames = FALSE)
    output$tabela <- renderTable({
      z <- recorte()
      data.frame(Estação = z$estacao, Horário = format(z$instante, "%d/%m/%Y %H:%M", tz = "America/Sao_Paulo"),
        "Temperatura (°C)" = z$temperatura_c, "Umidade (%)" = z$umidade_pct, "Vento (km/h)" = z$vento_kmh, check.names = FALSE)
    }, striped = TRUE, digits = 1, rownames = FALSE)
    output$baixar <- downloadHandler(filename = function() "simepar_recorte.csv", content = function(arquivo) {
      z <- recorte()
      z$instante <- format(z$instante, "%Y-%m-%dT%H:%M:%S%z", tz = "America/Sao_Paulo")
      write.csv2(z, arquivo, row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
    })
  }
}

shinyApp(ui, criar_servidor(raiz_projeto))
