arquivo <- grep("^--file=", commandArgs(FALSE), value = TRUE)
raiz_av2 <- if (length(arquivo)) {
  dirname(normalizePath(sub("^--file=", "", arquivo[[1]]), winslash = "/"))
} else if (file.exists("av2/app.R")) {
  normalizePath("av2", winslash = "/")
} else {
  normalizePath(getwd(), winslash = "/")
}
raiz <- dirname(raiz_av2)
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
if (!requireNamespace("shiny", quietly = TRUE)) stop("Instale shiny na biblioteca local do projeto antes de iniciar.")
porta <- as.integer(Sys.getenv("AV2_PORTA", "7442"))
shiny::runApp(raiz_av2, host = "127.0.0.1", port = porta, launch.browser = interactive())
