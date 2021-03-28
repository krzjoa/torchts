#' General interface to recurrent neural netowrk models
#'
#' @param mode (character) Model mode, default: 'regression'
#' @param learn_rate (numeric or dials::learn_rate) Learning rate
#' @param epochs (integer or dials::epochs) Number of epochs
#' @param batch_size (integer) Batch size
#'
#' @export
recurrent_network <- function(mode = "regression",
                              learn_rate = 0.01, epochs = 50,
                              batch_size = 32){

  args <- list(
    learn_rate = rlang::enquo(learn_rate),
    epochs     = rlang::enquo(epochs)
  )

  parsnip::new_model_spec(
    "recurrent_network",
    args     = args,
    eng_args = NULL,
    mode     = mode,
    method   = NULL,
    engine   = NULL
  )
}

# nocov start

make_recurrent_network <- function(){
  #See: https://tidymodels.github.io/model-implementation-principles/standardized-argument-names.html#data-arguments
  parsnip::set_new_model("recurrent_network")
  parsnip::set_model_mode("recurrent_network", "regression")

  #' torchts engine
  parsnip::set_model_engine("recurrent_network", mode = "regression", eng = "torchts")
  parsnip::set_dependency("recurrent_network", "torchts", "torch")
  parsnip::set_dependency("recurrent_network", "torchts", "torchts")

  # Args
  parsnip::set_model_arg(
    model        = "recurrent_network",
    eng          = "torchts",
    parsnip      = "learn_rate",
    original     = "learn_rate",
    func         = list(pkg = "dials", fun = "learn_rate"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "recurrent_network",
    eng = "torchts",
    parsnip = "epochs",
    original = "epochs",
    func = list(pkg = "dials", fun = "epochs"),
    has_submodel = FALSE
  )

  # Fit
  parsnip::set_fit(
    model = "recurrent_network",
    eng   = "torchts",
    mode  = "regression",
    value = list(
      interface = "data.frame",
      protect   = c("x", "y"),
      func      = c(fun = "recurrent_fit"),
      defaults  = NULL
    )
  )

  # Predict
  parsnip::set_pred(
    model         = "recurrent_network",
    eng           = "torchts",
    mode          = "regression",
    type          = "numeric",
    value         = list(
      pre       = NULL,
      post      = NULL,
      func      = c(fun = "predict_recurrent"),
      args      =
        list(
          object   = rlang::expr(object),
          new_data = rlang::expr(new_data)
        )
    )
  )
}


# nocov end
