#' MLP model for time series forecasting
#'
#' @param formula (`formula`) A formula describing, how to use the data
#' @param data (`data.frame`) A input data.frame.
#' @param learn_rate (`numeric`) Learning rate.
#' @param hidden_units (`integer`) Number of hidden units.
#' @param timesteps (`integer`) Number of timesteps used to produce a forecast.
#' @param horizon (`integer`) Forecast horizon.
#' @param jump (`integer`) Input window shift.
#' @param optim (`function`) A function returning a `torch` optimizer (like `optim_adam`)
#' or R expression like `optim_adam(amsgrad = TRUE)`. Such expression will be handled and feed with
#' `params` and `lr` arguments.
#' @param validation (`data.frame` or `numeric`) Validation dataset or percent of TODO.
#' @param batch_size (`integer`) Batch size.
#' @param epochs (`integer`) Number of epochs to train the network.
#' @param shuffle (`logical`) A dataloader argument - shuffle rows or not?
#' @param scale (`logical` or `list`)
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
#' mlp_model <-
#'   torchts_mlp(
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
torchts_mlp <- function(formula,
                        data,
                        learn_rate = 0.001,
                        hidden_units,
                        dropout = FALSE,
                        timesteps = 20,
                        horizon = 1,
                        jump = horizon,
                        optim = optim_adam(),
                        validation = NULL,
                        stateful = FALSE,
                        batch_size = 1,
                        epochs = 10,
                        shuffle = TRUE,
                        scale = TRUE,
                        sample_frac = 0.5,
                        loss_fn = nnf_mae,
                        device = NULL){

  # Checks
  check_is_complete(data)

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
      parsed_formula = parsed_formula,
      flatten        = TRUE
    )

  train_dl <- dls[[1]]
  valid_dl <- dls[[2]]

  input_size <- nrow(numeric) + sum(embedding$embedding_dim)

  output_size <- length(outcomes)

  layer_sizes <- c(hidden_units, output_size)

  if (is.null(embedding)) {
    model_args <- as.list(layer_sizes)
  } else {
    ils <- init_layer_spec(
      num_embeddings = embedding$num_embeddings,
      embedding_dim  = embedding$embedding_dim,
      numeric_in     = nrow(numeric),
      numeric_out    = layer_sizes[1]
    )
    model_args <- c(list(ils), as.list(layer_sizes[-1]))
  }

  # Creating a model
  net <-
    do.call(
      model_mlp,
      model_args
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
    scale          = scale_params(train_dl),
    col_map_out    = col_map_out(train_dl),
    extras         = train_dl$ds$extras
  )

}

#' @export
predict.torchts_mlp <- function(object, new_data){

  # WARNING: Cannot be used parallely for now

  # For now we suppose it's continuous
  # Check more conditions
  n_outcomes <- length(object$outcomes)
  batch_size <- 1

  # Checks
  check_is_new_data_complete(object, new_data)
  recursive_mode <- check_recursion(object, new_data)

  # Preparing dataloader
  new_data_dl <-
    as_ts_dataloader(
      new_data,
      timesteps      = object$timesteps,
      horizon        = object$horizon,
      batch_size     = batch_size,
      scale          = object$scale,
      # Extras
      parsed_formula = object$parsed_formula,
      cat_recipe     = object$extras$cat_recipe
    )

  net <- object$net

  if (!is.null(object$device)) {
    net         <- set_device(net, object$device)
    new_data_dl <- set_device(new_data_dl, object$device)
  }

  net$eval()

  preds <- matrix(nrow = object$timesteps,
                  ncol = length(object$outcomes))
  iter  <- 0

  net$is_stateful <- FALSE

  # b <- dataloader_next(dataloader_make_iter(new_data_dl))
  # net$stateful()

  coro::loop(for (b in new_data_dl) {

    output <- do.call(net, get_x(b))
    output <- output$reshape(c(-1, n_outcomes))
    preds  <- rbind(preds, as_array(output$cpu()))

    if (recursive_mode) {
      start <- object$timesteps + iter * object$horizon + 1
      end   <- object$timesteps + iter * object$horizon + object$horizon
      cols  <- unlist(new_data_dl$dataset$outcomes_spec)

      if (length(cols) == 1)
        output <- output$reshape(nrow(output))

      # TODO: insert do dataset even after last forecast for consistency?
      if (dim(new_data_dl$dataset$data[start:end, cols]) == dim(output))
        new_data_dl$dataset$data[start:end, cols] <- output
    }

    iter <- iter + 1

  })

  # net$stateful(FALSE)

  # Make sure that forecast has right length
  # TODO: keys!!!
  preds <- head(preds, nrow(new_data))

  # Adding colnames if more than one outcome
  if (ncol(preds) > 1)
    colnames(preds) <- object$outcomes
  else
    preds <- as.vector(preds)

  # browser()

  # Revert scaling if used for target
  preds <- invert_scaling(
    preds, object$scale, object$col_map_out
  )

  preds
}





#
