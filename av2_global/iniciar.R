arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz_global <- if (length(arquivo)) {
  dirname(normalizePath(sub("^--file=", "", arquivo[1]), winslash = "/"))
} else if (file.exists("av2_global/app.R")) {
  normalizePath("av2_global", winslash = "/")
} else normalizePath(getwd(), winslash = "/")
.libPaths(c(file.path(dirname(raiz_global), ".biblioteca"), .libPaths()))
if (!requireNamespace("shiny", quietly = TRUE)) stop("Instale shiny na biblioteca .biblioteca do projeto.")
porta <- as.integer(Sys.getenv("AV2_GLOBAL_PORTA", "7446"))
shiny::runApp(raiz_global, host = "127.0.0.1", port = porta, launch.browser = FALSE)
