.onLoad <- function(libname, pkgname) {
  # Parsnip models
  remove_model("rnn")
  make_rnn()
}
