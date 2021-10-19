#' RNN model for time series forecasting - `torchts` engine for `parsnip` API
#'
#' @param formula (`formula`) A formula describing, how to use the data
#' @param data (`data.frame`) A input data.frame.
#' @param learn_rate (`numeric`) Learning rate.
#' @param hidden_units (`integer`) Number of hidden units.
#' @param dropout (`logical`) Use dropout (default = FALSE).
#' @param timesteps (`integer`) Number of timesteps used to produce a forecast.
#' @param horizon (`integer`) Forecast horizon.
#' @param recurrent_layer (`nn_rnn_base`) A `torch` recurrent layer.
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
#' @export
rnn_fit <- function(formula,
                    data,
                    learn_rate,
                    hidden_units,
                    dropout = FALSE,
                    timesteps = 20,
                    horizon = 1,
                    recurrent_layer = nn_gru,
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
  key        <- vars_with_role(parsed_formula, "key")
  index      <- vars_with_role(parsed_formula, "index")
  outcome    <- vars_with_role(parsed_formula, "outcome")
  predictors <- vars_with_role(parsed_formula, "predictor")

  optim <- rlang::enquo(optim)

  # Validation if defined
  if (!is.null(validation)) {
    if(!is.numeric(validation)) {

      data_split <-
        timetk::time_series_split(
          data     = data,
          date_var = index,
          lag      = timesteps,
          initial  = floor(nrow(data) * (1 - validation)),
          assess   = floor(nrow(data) * validation)
        )

      data       <- rsample::training(data_split)
      validation <- rsample::testing(data_split)

    }

    # TODO: simplify
    valid_dl <-
      as_ts_dataloader(
        data        = validation,
        formula     = formula,
        timesteps   = timesteps,
        horizon     = horizon,
        scale       = scale,
        batch_size  = batch_size
      )

  }

  train_dl <-
    as_ts_dataloader(
      data        = data,
      formula     = formula,
      timesteps   = timesteps,
      h           = horizon,
      scale       = scale,
      batch_size  = batch_size
    )

  input_size <-
    tail(dim(train_dl$dataset$data), 1)

  output_size <- length(outcome)

  # Creating a model
  net <-
    model_rnn(
        layer       = recurrent_layer,
        input_size  = input_size,
        output_size = output_size,
        hidden_size = hidden_units,
        horizon     = horizon,
        dropout     = dropout
    )

  # Preparing optimizer
  optimizer <- call_optim(optim, net$parameters)

  # Training
  # Info in Keras
  # 938/938 [==============================] - 1s 1ms/step - loss: 0.0563 - acc: 0.9829 - val_loss: 0.1041 - val_acc: 0.9692
  for (epoch in seq_len(epochs)) {

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
      "\nEpoch %d/%d | training: %3.5f %s \n",
      epoch, epochs, mean(train_loss), valid_loss_info
    ))

  }

  # Return neural network structure
  structure(
    class = "torchts_rnn",
    list(
      net        = net,
      index      = index,
      key        = key,
      outcome    = outcome,
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
  n_outcomes     <- length(object$outcome)
  batch_size     <- 1

  recursive_mode <- check_recursion(object, new_data)

  # Preparing dataloader
  new_data_dl <-
     as_ts_dataloader(
       new_data,
       index       = object$index,
       key         = object$key,
       predictors  = object$predictors,
       target      = object$outcome,
       timesteps   = object$timesteps,
       h           = object$horizon,
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
      cols  <- unlist(new_data_dl$dataset$target_columns)
      new_data_dl$dataset$data[start:end, cols] <- output
    }

    iter <- iter + 1

  })

  # Adding colnames if more than one outcome
  if (ncol(preds) > 1)
    colnames(preds) <- object$outcome

  preds
}

#
