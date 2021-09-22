#' Basic RNN model for time series forecasting
#'
#' @param formula A formula describing, how to use the data
#' @param data (data.frame)
#' @param learn_rate (numeric) Learning rate
#' @param hidden_units (integer) Number of hidden units
#'
#' @export
rnn_fit <- function(formula, data,
                    learn_rate,
                    hidden_units,
                    dropout,
                    timesteps = 20,
                    horizon = 1,
                    optim = optim_adam(),
                    validation = NULL,
                    batch_size = 1,
                    epochs = 10,
                    scale = TRUE,
                    loss_fn = nnf_mse_loss){

  # Po dniu można grupować. Co, jeśli możemy te wiedzę przekazać bezpośrednio do sieci?
  # Może nie musiałaby się tego uczyć?

  # Parse formula
  parsed_formula <- torchts_parse_formula(formula, data)

  # Extract column roles from formula
  # Use torchts_constants
  key     <- filter(parsed_formula, .role == "key")$.var
  index   <- filter(parsed_formula, .role == "index")$.var
  outcome <- filter(parsed_formula, .role == "outcome")$.var

  optim <- rlang::enquo(optim)

  # Validation if defined
  if (!is.null(validation) &
      !is.data.frame(validation)) {

    # TODO: implement own ts_split? (optimization)

    browser()

    split <- timetk::time_series_split(

    )
    # split <-
    #   timetk::time_series_split(
    #     data     = data,
    #     date_var = index,
    #     initial  =
    #   )

    # TODO: simplify
    train_dl <-
      as_ts_dataset(
        data        = data,
        formula     = formula,
        timesteps   = timesteps,
        h           = horizon,
        scale       = scale
      )

    train_dl <-
      dataloader(train_dataset, batch_size = batch_size)
  }

  # TODO: simplify
  train_dataset <-
    as_ts_dataset(
      data        = data,
      formula     = formula,
      timesteps = timesteps,
      h           = horizon,
      scale       = scale
    )

  train_dl <-
    dataloader(train_dataset, batch_size = batch_size)

  input_size <-
    tail(dim(train_dataset$data), 1)

  output_size <- length(outcome)

  # Creating a model
  net <-
    model_rnn(
        layer             = nn_gru,
        input_size        = input_size,
        output_size       = output_size,
        hidden_size       = hidden_units,
        h                 = horizon,
        dropout           = 0
    )

  # Preparing optimizer
  optimizer <- call_optim(optim, net$parameters)

  # Training
  for (epoch in 1:epochs) {

    net$train()
    train_loss <- c()

    coro::loop(for (b in train_dl) {
      loss <- train_batch(
        input     = b$x,
        target    = b$y,
        net       = net,
        optimizer = optimizer,
        loss_fun  = nnf_mse_loss
      )
      train_loss <- c(train_loss, loss)
    })

    valid_loss_info <- ""

    if (!is.null(validation)) {

      net$eval()
      valid_loss <- c()

      coro::loop(for (b in valid_dl) {
        loss <- valid_batch(b)
        valid_loss <- c(valid_loss, loss)
      })

      valid_loss_info <- sprintf("validation: %3.5f", mean(valid_loss))
    }

    cat(sprintf(
      "\nEpoch %d | training: %3.5f %s \n",
      epoch, mean(train_loss), valid_loss_info
    ))

  }

  # Return neural network structure
  structure(
    class = "torchts_rnn",
    list(
      net       = net,
      index     = index,
      key       = key,
      outcome   = outcome,
      optim     = optimizer,
      timesteps = timesteps,
      horizon   = horizon
    )
  )

}

#' @export
predict.torchts_rnn <- function(object, new_data){

  # WARNING: Cannot be used parallely for now

  # For now we suppose it's continuous
  recursive_mode <- FALSE

  if (object$outcome %in% colnames(new_data)) {
    if (any(is.na(new_data[[object$outcome]]))) {
      recursive_mode <- TRUE
    }
  }

  # Preparing
 new_data_ds <- as_ts_dataset(
   new_data,
    index       = object$index,
    key         = object$key,
    target      = object$outcome,
    timesteps   = object$timesteps,
    h           = object$horizon
  )

 new_data_dl  <- dataloader(new_data_ds, batch_size = 5)

  net <- object$net
  net$eval()

  preds <- rep(NA, 20)
  iter  <- 1

  coro::loop(for (b in new_data_dl) {

    output <- net(b$x)
    preds  <- c(preds, as.numeric(output))

    if (recursive_mode) {
      start <- (object$timesteps * iter) + 1
      end   <- (object$timesteps * iter) + object$horizon
      cols  <- unlist(new_data_dl$dataset$target_columns)
      new_data_dl$dataset$data[start:end, cols] <- output
    }

    iter <- iter + 1

  })

  preds
}

#
