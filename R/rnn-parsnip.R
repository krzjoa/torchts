#' General interface to recurrent neural netowrk models
#'
#' @param mode (character) Model mode, default: 'regression'
#' @param learn_rate (numeric or dials::learn_rate) Learning rate
#' @param epochs (integer or dials::epochs) Number of epochs
#' @param hidden_units Number of hidden units
#' @param dropout
#' @param batch_size (integer) Batch size
#'
#' @export
rnn <- function(mode = "regression",
                learn_rate = 0.01, epochs = 50,
                hidden_units = NULL, timesteps = NULL,
                horizon = 1, dropout = NULL,
                batch_size = 32){

  args <- list(
    learn_rate    = rlang::enquo(learn_rate),
    epochs        = rlang::enquo(epochs),
    hidden_units  = rlang::enquo(hidden_units),
    timesteps     = rlang::enquo(timesteps),
    horizon       = rlang::enquo(horizon),
    dropout       = rlang::enquo(dropout),
    batch_size    = rlang::enquo(batch_size)
  )

  parsnip::new_model_spec(
    "rnn",
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
      func      = c(fun = "rnn_fit"),
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
