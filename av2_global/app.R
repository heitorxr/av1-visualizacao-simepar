raiz_global <- if (file.exists("R/interface.R") && file.exists("R/coleta.R")) {
  normalizePath(getwd(), winslash = "/")
} else if (file.exists("av2_global/R/interface.R")) {
  normalizePath("av2_global", winslash = "/")
} else {
  arquivo_app <- sys.frame(1)$ofile
  if (is.null(arquivo_app)) stop("Execute av2_global/iniciar.R a partir do projeto.")
  dirname(normalizePath(arquivo_app, winslash = "/"))
}
.libPaths(c(file.path(dirname(raiz_global), ".biblioteca"), .libPaths()))
library(shiny)
source(file.path(raiz_global, "R", "coleta.R"), local = TRUE, encoding = "UTF-8")
source(file.path(raiz_global, "R", "analise.R"), local = TRUE, encoding = "UTF-8")
source(file.path(raiz_global, "R", "interface.R"), local = TRUE, encoding = "UTF-8")
inicial_global <- carregar_global(raiz_global)
if (!nrow(inicial_global$dados)) inicial_global <- atualizar_global(raiz_global, forcar = TRUE)
if (!nrow(inicial_global$dados)) stop("Sem observações disponíveis. Confira a fonte ou restaure o snapshot real em dados/entrada.")
cadastro_global <- estacoes_globais()
ui_global <- criar_ui_global(inicial_global, cadastro_global)
servidor_global <- criar_servidor_global(raiz_global, inicial_global, atualizar_global, agregar_horas_globais, cadastro_global)
shinyApp(ui_global, servidor_global)
