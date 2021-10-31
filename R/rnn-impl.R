#' RNN model for time series forecasting - `torchts` engine for `parsnip` API
#'
#' @param formula (`formula`) A formula describing, how to use the data
#' @param data (`data.frame`) A input data.frame.
#' @param learn_rate (`numeric`) Learning rate.
#' @param hidden_units (`integer`) Number of hidden units.
#' @param dropout (`logical`) Use dropout (default = FALSE).
#' @param timesteps (`integer`) Number of timesteps used to produce a forecast.
#' @param horizon (`integer`) Forecast horizon.
#' @param rnn_layer (`nn_rnn_base`) A `torch` recurrent layer.
#' @param optim (`function`) A function returning a `torch` optimizer (like `optim_adam`)
#' or R expression like `optim_adam(amsgrad = TRUE)`. Such expression will be handled and feed with
#' `params` and `lr` arguments.
#' @param validation (`data.frame` or `numeric`) Validation dataset or percent of TODO.
#' @param batch_size (`integer`) Batch size.
#' @param epochs (`integer`) Number of epochs to train the network.
#' @param loss_fn (`function`) A `torch` loss function.
#'
#' @importFrom torch nn_gru
#' @importFrom rsample training testing
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' library(torch)
#' library(torchts)
#' library(timetk)
#'
#' # Preparing a dataset
#' tarnow_temp <-
#'    weather_pl %>%
#'    filter(station == "TRN") %>%
#'    select(date, tmax_daily, tmin_daily, press_mean_daily)
#'
#' # Splitting dataset
#' data_split <-
#'    time_series_split(
#'       tarnow_temp, date,
#'       initial = "18 years",
#'       assess  = "2 years",
#'       lag     = 20
#'    )
#'
#' # Training a model
#' rnn_model <-
#'    rnn_fit(
#'      tmax_daily ~ date,
#'      data = training(data_split),
#'      hidden_units = 10,
#'      timesteps = 20,
#'      horizon   = 1,
#'      epochs = 1,
#'      batch_size = 32
#'    )
#'
#' # Prediction
#'
#'
#'
#'
#' @export
rnn_fit <- function(formula,
                    data,
                    learn_rate = 0.9,
                    hidden_units,
                    dropout = FALSE,
                    timesteps = 20,
                    horizon = 1,
                    rnn_layer = nn_gru,
                    optim = optim_adam(),
                    validation = NULL,
                    batch_size = 1,
                    epochs = 10,
                    scale = TRUE,
                    loss_fn = nnf_mse_loss){

  # TODO: thumb rule for number of hidden units

  # Po dniu można grupować. Co, jeśli możemy te wiedzę przekazać bezpośrednio do sieci?
  # Może nie musiałaby się tego uczyć?

  # Sieci można używać bez treningu, ale nie modele w parsnipie
  # Trik: zero epok

  # Parse formula
  parsed_formula <- torchts_parse_formula(formula, data)

  # Extract column roles from formula
  # Use torchts_constants
  key        <- vars_with_role(parsed_formula, "key")
  index      <- vars_with_role(parsed_formula, "index")
  outcomes   <- vars_with_role(parsed_formula, "outcome")
  predictors <- vars_with_role(parsed_formula, "predictor")

  all_used_vars <- unique(c(key, index, outcomes, predictors))

  optim <- rlang::enquo(optim)

  # Selectin only those columns which are used
  data <-
    data %>%
    select(all_of(all_used_vars))

  # Prepare dataloaders
  dls <-
    prepare_dl(
      data       = data,
      formula    = formula,
      index      = index,
      timesteps  = timesteps,
      horizon    = horizon,
      validation = validation,
      scale      = scale,
      batch_size = batch_size
    )

  train_dl <- dls[[1]]
  valid_dl <- dls[[2]]

  input_size <-
    tail(dim(train_dl$dataset$data), 1)

  output_size <- length(outcomes)

  # Creating a model
  net <-
    model_rnn(
        rnn_layer   = rnn_layer,
        input_size  = input_size,
        output_size = output_size,
        hidden_size = hidden_units,
        horizon     = horizon,
        dropout     = dropout,
        batch_first = TRUE
    )

  # Preparing optimizer
  optimizer <- call_optim(optim, net$parameters)

  # Training
  net <-
    fit_network(
      net       = net,
      train_dl  = train_dl,
      valid_dl  = valid_dl,
      epochs    = epochs,
      optimizer = optimizer,
      loss_fn   = loss_fn
    )

  # Return neural network structure
  structure(
    class = "torchts_rnn",
    list(
      net        = net,
      index      = index,
      key        = key,
      outcomes   = outcomes,
      predictors = predictors,
      optim      = optimizer,
      timesteps  = timesteps,
      horizon    = horizon,
      scale      = scale_params(train_dl)
    )
  )

}

#' @export
predict.torchts_rnn <- function(object, new_data){

  # WARNING: Cannot be used parallely for now

  # For now we suppose it's continuous
  # Check more conditions
  n_outcomes     <- length(object$outcomes)
  batch_size     <- 1

  recursive_mode <- check_recursion(object, new_data)

  # Preparing dataloader
  new_data_dl <-
     as_ts_dataloader(
       new_data,
       index       = object$index,
       key         = object$key,
       predictors  = object$predictors,
       outcomes    = object$outcomes,
       timesteps   = object$timesteps,
       horizon     = object$horizon,
       batch_size  = batch_size,
       scale       = object$scale
     )

  net <- object$net
  net$eval()

  preds <- NULL
  iter  <- 0

  coro::loop(for (b in new_data_dl) {

    output <- net(b$x)
    output <- output$reshape(c(-1, n_outcomes))
    preds  <- rbind(preds, as_array(output))

    if (recursive_mode) {
      start <- object$timesteps + iter * object$horizon + 1
      end   <- object$timesteps + iter * object$horizon + object$horizon
      cols  <- unlist(new_data_dl$dataset$outcomes_spec)
      new_data_dl$dataset$data[start:end, cols] <- output
    }

    iter <- iter + 1

  })

  # Adding colnames if more than one outcome
  if (ncol(preds) > 1)
    colnames(preds) <- object$outcomes

  preds
}

#
