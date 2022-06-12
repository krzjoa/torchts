#' General interface to recurrent neural network models
#'
#' @param mode (`character`) Model mode, default: 'regression'.
#' @param timesteps (`integer`) Number of timesteps to look back.
#' @param horizon (`integer`) Forecast horizon.
#' @param learn_rate (`numeric` or [`dials::learn_rate`]) Learning rate.
#' @param epochs (`integer` or [`dials::epochs`]) Number of epochs.
#' @param hidden_units (`integer`) Number of hidden units.
#' @param dropout (`logical` or [`dials::dropout`]) Flag to use dropout.
#' @param batch_size (`integer`) Batch size.
#' @param scale (`logical`) Scale input features.
#' @param shuffle (`logical`) Shuffle examples during the training (default: FALSE).
#' @param jump (`integer`) Input window shift.
#' @param sample_frac (`numeric`) A percent of subsamples used for training.
#'
#' @details
#' This is a `parsnip` API to the recurent network models. For now the only
#' available engine is `torchts_rnn`.
#'
#' @section Categorical features:
#' Categorical features are detected automatically - if a column of your input data (defined in the formula)
#' is `logical`, `character`, `factor` or `integer`.
#'
#' @section Empty model:
#' Neural networks, unlike many other models (e.g. linear models) can return values
#' before any training epoch ended. It's because every neural networks model starts with
#' "random" parameters, which are gradually tuned in the following iterations according to the
#' Gradient Descent algorithm.
#'
#' If you'd like to get a non-trained model, simply set `epochs = 0`.
#' You still have to "fit" the model to stick the standard `parsnip`'s API procedure.
#'
#' @importFrom parsnip fit fit_xy translate
#'
#' @examples
#' library(torchts)
#' library(parsnip)
#' library(dplyr, warn.conflicts = FALSE)
#' library(rsample)
#'
#' # Univariate time series
#' tarnow_temp <-
#'  weather_pl %>%
#'  filter(station == "TARNÓW") %>%
#'  select(date, temp = tmax_daily)
#'
#' data_split <- initial_time_split(tarnow_temp)
#'
#' rnn_model <-
#'    rnn(
#'      timesteps = 20,
#'      horizon = 1,
#'      epochs = 10,
#'      hidden_units = 32
#'    )
#'
#' rnn_model <-
#'    rnn_model %>%
#'    fit(temp ~ date, data = training(data_split))
#'
#'
#' @export
rnn <- function(mode = "regression",
                timesteps = NULL,
                horizon = 1,
                learn_rate = 0.01,
                epochs = 50,
                hidden_units = NULL,
                dropout = NULL,
                batch_size = 32,
                shuffle = FALSE,
                jump = 1,
                sample_frac = 1.){

  # TODO: add variables
  # * init_layer (rnn_layer)
  # * cell_type
  # * validation?

  args <- list(
    timesteps     = rlang::enquo(timesteps),
    horizon       = rlang::enquo(horizon),
    learn_rate    = rlang::enquo(learn_rate),
    epochs        = rlang::enquo(epochs),
    hidden_units  = rlang::enquo(hidden_units),
    dropout       = rlang::enquo(dropout),
    batch_size    = rlang::enquo(batch_size),
    scale         = rlang::enquo(scale),
    shuffle       = rlang::enquo(shuffle),
    jump          = rlang::enquo(jump),
    sample_frac   = rlang::enquo(sample_frac)
  )

  parsnip::new_model_spec(
    cls      = "rnn",
    args     = args,
    eng_args = NULL,
    mode     = mode,
    method   = NULL,
    engine   = NULL
  )
}

# nocov start

make_rnn <- function(){

  #See: https://tidymodels.github.io/model-implementation-principles/standardized-argument-names.html#data-arguments
  parsnip::set_new_model("rnn")
  parsnip::set_model_mode("rnn", "regression")

  #' torchts engine
  parsnip::set_model_engine(
    model = "rnn",
    mode  = "regression",
    eng   = "torchts"
  )

  parsnip::set_dependency("rnn", "torchts", "torch")
  parsnip::set_dependency("rnn", "torchts", "torchts")

  # Args
  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "timesteps",
    original     = "timesteps",
    func         = list(pkg = "torchts", fun = "timesteps"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "horizon",
    original     = "horizon",
    func         = list(pkg = "torchts", fun = "horizon"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "learn_rate",
    original     = "learn_rate",
    func         = list(pkg = "dials", fun = "learn_rate"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "epochs",
    original     = "epochs",
    func         = list(pkg = "dials", fun = "epochs"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "hidden_units",
    original     = "hidden_units",
    func         = list(pkg = "dials", fun = "hidden_units"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "dropout",
    original     = "dropout",
    func         = list(pkg = "dials", fun = "dropout"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "batch_size",
    original     = "batch_size",
    func         = list(pkg = "dials", fun = "batch_size"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "shuffle",
    original     = "shuffle",
    func         = list(pkg = "torchts", fun = "shuffle"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "jump",
    original     = "jump",
    func         = list(pkg = "torchts", fun = "jump"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model        = "rnn",
    eng          = "torchts",
    parsnip      = "sample_frac",
    original     = "sample_frac",
    func         = list(pkg = "torchts", fun = "sample_frac"),
    has_submodel = FALSE
  )

  # Encoding
  parsnip::set_encoding(
    model = "rnn",
    eng   = "torchts",
    mode  = "regression",
    options = list(
      predictor_indicators = "none",
      compute_intercept    = FALSE,
      remove_intercept     = FALSE,
      allow_sparse_x       = FALSE
    )
  )

  # Fit
  parsnip::set_fit(
    model = "rnn",
    eng   = "torchts",
    mode  = "regression",
    value = list(
      interface = "formula",
      protect   = c("formula", "data"),
      func      = c(fun = "torchts_rnn"),
      defaults  = list()
    )
  )

  # Predict
  parsnip::set_pred(
    model         = "rnn",
    eng           = "torchts",
    mode          = "regression",
    type          = "numeric",
    value         = list(
      pre       = NULL,
      post      = NULL,
      func      = c(fun = "predict"),
      args      =
        list(
          object   = rlang::expr(object$fit),
          new_data = rlang::expr(new_data)
        )
    )
  )
}

# nocov end
