.onLoad <- function(libname, pkgname) {
  # Settings
  options(torchts_categoricals = c("logical", "factor", "character", "integer"))

  # Parsnip models
  remove_model("rnn")
  # make_rnn()
}
