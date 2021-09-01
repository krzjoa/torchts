#' Basic RNN model for time series forecasting
#'
#' @param x Input features
#' @param y Targets
#' @param categorical_features List of categorical feature columns from data.frame x
#' @param optim An optimizer with arguments
#'
#' If using simple fix_xy, we do not any assumption about time and number of items.
#'
#' data <- filter(experiment_data, item_id == "FOODS_1_001")
#'
#' x <- filter(experiment_data, item_id == "FOODS_1_001")
#' x <- select(x, -value)
#' y <- select(filter(experiment_data, item_id == "FOODS_1_001"), value, item_id, date)
#' key <- "item_id"
#' index <- "date"
#' categorical_features <- c("wday", "month", "snap_CA")
#'
#' catch <- function(optim){browser()}
#' catch(optim_adam(lr = 0.001))
#'
#' model <- recurrent_fit(x, y, key = "item_id", index = "date", epochs = 1000)
#' fcast <- predict_basic_rnn_impl(model, x, key = "item_id", index = "date")
#' View(bind_cols(y, fcast))
#'
#' recurrent_network_fit_formula(value ~ key(item_id) + index(date) + . + categ(wday, month, fbwd(snap_CA)),
#' data = data)
#'
#' Idea:
#' - rnn_reg for parsnip
#' - ts_rnn for fable (ts prefix for fable)
#'
#' Po dniu można grupować. Co, jeśli możemy te wiedzę przekazać bezpośrednio do sieci?
#' Może nie musiałaby się tego uczyć?
#'
#' @export
rnn_fit <- function(formula, data,
                    learn_rate, hidden_units, dropout,
                    n_timesteps = 20, h = 1,
                    n_layers = 1, optim = optim_adam(),
                    batch_size = 1, epochs = 10,
                    loss_fn = nnf_mse_loss){


  # Parse formula
  # TODO: optimize - double
  parsed_formula <- torchts_parse_formula(formula, data)

  # Extract column roles from formula
  # Use torchts_constants
  key     <- filter(parsed_formula, .type == "key")$.var
  index   <- filter(parsed_formula, .type == "index")$.var
  outcome <- filter(parsed_formula, .type == "outcome")$.var

  # forward_categorical   <- filter(parsed_formula, .type == "categ")$.var
  # double_way_cateorical <- filter(parsed_formula,
  #   purrr::map_lgl(.type, ~ all(.x == c("categ", "fbwd")))
  #   )$.var
  #
  # any_categorical <- filter(parsed_formula,
  #   purrr::map_lgl(.type, ~ "categ" %in% .x)
  # )$.var
  #
  # X_tensors <- resolve_data(select(data, -!!outcome),
  #                           key = key, index = index,
  #                           categorical_features = any_categorical)

  optim <- rlang::enquo(optim)

  train_dataset <-
    as_ts_dataset(
      data       = data,
      formula     = formula,
      n_timesteps = n_timesteps,
      h           = h
    )

  train_dl <-
    dataloader(train_dataset, batch_size = batch_size)

  input_size <-
    tail(dim(train_dataset$data), 1)

  # Creating a model
  net <-
    model_rnn(
        layer             = nn_gru,
        input_size        = input_size,
        hidden_size       = hidden_units,
        h                 = h,
        num_layers        = n_layers,
        dropout           = 0,
        output_activation = nn_linear(hidden_units, 1)
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

    cat(sprintf("\nEpoch %d, training: loss: %3.5f \n", epoch, mean(train_loss)))

    net$eval()
    valid_loss <- c()

    # coro::loop(for (b in valid_dl) {
    #   loss <- valid_batch(b)
    #   valid_loss <- c(valid_loss, loss)
    # })
    #
    # cat(sprintf("\nEpoch %d, validation: loss: %3.5f \n", epoch, mean(valid_loss)))
  }

  # Return neural network structure
  structure(
    class = "torchts_rnn",
    list(
      net   = net,
      index = index,
      key   = key,
      optim = optimizer,
      n_timesteps = n_timesteps,
      h = h
    )
  )

}

#' @param y Can be NULL
#' @param key Can be NULL
recurrent_network_fit_xy <- function(x, y = NULL, key = NULL, index = NULL, categorical = NULL,
                          backward = NULL, optim = optim_adam(), batch_size = 1,
                          epochs = 10, loss_fn = nnf_mse_loss, plugins = NULL){

  input_tensors    <- resolve_data(x, key, index, categorical)
  X_tensor_numeric <- input_tensors[[1]]
  X_tensor_cat     <- input_tensors[[2]]

  # Input size
  n_features <-
    tail(dim(X_tensor_cat), 1) +
    tail(dim(X_tensor_numeric), 1)

  dict_sizes <-
    x %>%
    select(!!categorical_features) %>%
    dict_size()

  embedding_sizes <-
    ceiling(dict_sizes ** 0.25)

  # Creating a neural network
  neural_network <- model_recurrent(
    fwd_input_size  = n_features,
    fwd_numeric_input =  tail(dim(X_tensor_numeric), 1),
    fwd_output_size = 3,
    output_size     = 1,
    num_embeddings  = dict_sizes,
    embedding_dim   = embedding_sizes
  )

  # Creating an optimizer object
  optim <- call_optim(rlang::enquo(optim),
                      neural_network$parameters)

  # Train neural network
  # TODO: prepare plugins
  for (epoch in seq(epochs)) {
    neural_network$zero_grad()
    fcast <- neural_network(X_tensor_cat, X_tensor_numeric)
    loss  <- loss_fn(fcast, y_tensor)
    loss$backward()
    print(loss)
    optim$step()
  }

  # Return neural network structure
  structure(
    class = "recurrent_network_fit",
    list(
      neural_network       = neural_network,
      numerical_features   = numerical_features,
      categorical_features = categorical_features,
      all_features         = c(numerical_features, categorical_features),
      index                = index,
      key                  = key,
      optim                = optim
    )
  )
}

#' @export
predict.torchts_rnn <- function(object, new_data){

  # Preparing
 new_data_ds <- as_ts_dataset(
    new_data,
    index       = object$fit$index,
    key         = object$fit$key,
    target      = object$fit$target,
    n_timesteps = object$fit$n_timesteps,
    h           = object$fit$h
  )

 new_data_dl  <- dataloader(new_data_ds, batch_size = 5)

  net <- object$fit$net
  net$eval()

  preds <- rep(NA, 20)

  coro::loop(for (b in new_data_dl) {
    output <- net(b$x)
    preds  <- c(preds, as.numeric(output))
  })

  preds
}
