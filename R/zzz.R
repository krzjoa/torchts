.onLoad <- function(libname, pkgname) {

  # Settings
  options(
    torchts_categoricals = c("logical", "factor", "character", "integer"),

    # TODO: tochts_time and so on?
    torchts_dates        = c("Date", "POSIXt", "POSIXlt", "POSIXct")
  )

  # Parsnip models
  # remove_model("rnn")
  # make_rnn()
  # make_lagged_mlp()
}
