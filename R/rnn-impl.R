#' RNN model for time series forecasting
#'
#' @param formula (`formula`) A formula describing, how to use the data
#' @param data (`data.frame`) A input data.frame.
#' @param learn_rate (`numeric`) Learning rate.
#' @param hidden_units (`integer`) Number of hidden units.
#' @param dropout (`logical`) Use dropout (default = FALSE).
#' @param timesteps (`integer`) Number of timesteps used to produce a forecast.
#' @param horizon (`integer`) Forecast horizon.
#' @param jump (`integer`) Input window shift.
#' @param rnn_layer (`nn_rnn_base`) A `torch` recurrent layer.
#' @param optim (`function`) A function returning a `torch` optimizer (like `optim_adam`)
#' or R expression like `optim_adam(amsgrad = TRUE)`. Such expression will be handled and feed with
#' `params` and `lr` arguments.
#' @param validation (`data.frame` or `numeric`) Validation dataset or percent of TODO.
#' @param stateful (`logical` or `list`) Determine network behaviour: is stateful or not.
#' @param batch_size (`integer`) Batch size.
#' @param epochs (`integer`) Number of epochs to train the network.
#' @param shuffle (`logical`) A dataloader argument - shuffle rows or not?
#' @param sample_frac (`numeric`) A fraction of time series to be sampled.
#' @param loss_fn (`function`) A `torch` loss function.
#' @param device (`character`) A `torch` device.
#'
#' @importFrom torch nn_gru optim_adam
#' @importFrom rsample training testing
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' library(torch)
#' library(torchts)
#' library(timetk)
#'
#' # Preparing a dataset
#' tiny_m5_sample <-
#'   tiny_m5 %>%
#'   filter(item_id == "FOODS_3_586", store_id == "CA_1") %>%
#'   mutate(value = as.numeric(value))
#'
#' tk_summary_diagnostics(tiny_m5_sample)
#' glimpse(tiny_m5_sample)
#'
#' TIMESTEPS <- 20
#'
#' data_split <-
#'   time_series_split(
#'     tiny_m5_sample, date,
#'     initial = "4 years",
#'     assess  = "1 year",
#'     lag     = TIMESTEPS
#'   )
#'
#' # Training
#' rnn_model <-
#'   torchts_rnn(
#'     value ~ date + value + sell_price + wday,
#'     data = training(data_split),
#'     hidden_units = 10,
#'     timesteps = TIMESTEPS,
#'     horizon   = 1,
#'     epochs = 10,
#'     batch_size = 32
#'   )
#'
#' # Prediction
#' cleared_new_data <-
#'   testing(data_split) %>%
#'   clear_outcome(date, value, TIMESTEPS)
#'
#' forecast <-
#'   predict(rnn_model, cleared_new_data)
#'
#' @export
torchts_rnn <- function(formula,
                    data,
                    learn_rate = 0.001,
                    hidden_units,
                    dropout = FALSE,
                    timesteps = 20,
                    horizon = 1,
                    jump = horizon,
                    rnn_layer = nn_gru,
                    initial_layer_size = NULL,
                    optim = optim_adam(),
                    validation = NULL,
                    stateful = FALSE,
                    batch_size = 1,
                    epochs = 10,
                    shuffle = TRUE,
                    sample_frac = 0.5,
                    loss_fn = nnf_mae,
                    device = NULL, ...){

  # TODO: thumb rule for number of hidden units
  # TODO: jump vs shift

  # Po dniu można grupować. Co, jeśli możemy te wiedzę przekazać bezpośrednio do sieci?
  # Może nie musiałaby się tego uczyć?

  # Sieci można używać bez treningu, ale nie modele w parsnipie
  # Trik: zero epok

  # Checks
  check_is_complete(data)
  # check_stateful_vs_jump(horizon, jump, stateful)

  # Parse formula
  parsed_formula <- torchts_parse_formula(formula, data)

  # Extract column roles from formula
  # Use torchts_constants
  key         <- vars_with_role(parsed_formula, "key")
  index       <- vars_with_role(parsed_formula, "index")
  outcomes    <- vars_with_role(parsed_formula, "outcome")
  predictors  <- vars_with_role(parsed_formula, "predictor")
  categorical <- dplyr::filter(parsed_formula, .role == "predictor", .type == "categorical")
  numeric     <- dplyr::filter(parsed_formula, .role == "predictor", .type == "numeric")

  all_used_vars <- unique(c(key, index, outcomes, predictors))

  optim <- rlang::enquo(optim)

  # Selecting only those columns which are used
  data <-
    data %>%
    select(all_of(all_used_vars))

  # Categorical features
  embedding <-
    prepare_categorical(data, categorical)

  # TODO: consider step_integer here, with optional handling in dataset

  # Prepare dataloaders
  dls <-
    prepare_dl(
      data           = data,
      formula        = formula,
      index          = index,
      timesteps      = timesteps,
      horizon        = horizon,
      categorical    = categorical,
      validation     = validation,
      scale          = scale,
      sample_frac    = sample_frac,
      batch_size     = batch_size,
      shuffle        = shuffle,
      jump           = jump,
      parsed_formula = parsed_formula
    )

  train_dl <- dls[[1]]
  valid_dl <- dls[[2]]

  input_size <- nrow(numeric) + sum(embedding$embedding_dim)

  output_size <- length(outcomes)

  # Creating a model
  # initial_layer <-
  #   nn_linear(input_size - length(embedding$num_embeddings),
  #             geometric_pyramid(input_size - length(embedding$num_embeddings), hidden_size))

  net <-
    model_rnn(
        rnn_layer   = rnn_layer,
        input_size  = input_size,
        output_size = output_size,
        hidden_size = hidden_units,
        horizon     = horizon,
        embedding   = embedding,
        dropout     = dropout,
        batch_first = TRUE
    )

  if (!is.null(device)) {
    net      <- set_device(net, device)
    train_dl <- set_device(train_dl, device)
    valid_dl <- set_device(valid_dl, device)
  }

  # Preparing optimizer
  optimizer <- call_optim(optim, learn_rate, net$parameters)

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

  # Return torchts model
  torchts_model(
    class          = "torchts_rnn",
    net            = net,
    index          = index,
    key            = key,
    outcomes       = outcomes,
    predictors     = predictors,
    optim          = optimizer,
    timesteps      = timesteps,
    parsed_formula = parsed_formula,
    horizon        = horizon,
    device         = device,
    col_map_out    = col_map_out(train_dl),
    extras         = train_dl$ds$extras
  )

}

#' @export
predict.torchts_rnn <- torchts_predict
