.onLoad <- function(libname, pkgname) {

  # Settings
  options(
    torchts_categoricals = c("logical", "factor", "character", "integer"),
    torchts_dates        = c("Date", "POSIXt", "POSIXlt", "POSIXct")
  )

  # Parsnip models
  # remove_model("rnn")
  # make_rnn()
}
