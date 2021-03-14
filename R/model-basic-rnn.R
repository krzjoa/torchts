#' Basic RNN model for time series forecasting
#'
#' @param x Input features
#' @param y Targets
#' @param categorical_features List of categorical feature columns from data.frame x
#' @param optim An optimizer with arguments
#' @param plugins A list of additional objects to observe loss function values etc.
#'
#' If using simple fix_xy, we do not any assumption about time and number of items.
#'
#' @examples
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
#' model <- recurrent_fit(x, y, key = "item_id", index = "date", n_epochs = 1000)
#' fcast <- predict_basic_rnn_impl(model, x, key = "item_id", index = "date")
#' View(bind_cols(y, fcast))
#'
#' Idea:
#' - rnn_reg for parsnip
#' - ts_rnn for fable (ts prefix for fable)
recurrent_fit <- function(x, y, key, index, categorical_features = NULL,
                          backward = NULL, optim = optim_adam(), batch_size = 1,
                          n_epochs = 10, loss_fn = nnf_mse_loss, plugins = NULL){

  input_tensors    <- resolve_data(x, key, index, categorical_features)
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
  neural_network <- nn_recurrent(
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
  for (epoch in seq(n_epochs)) {
    neural_network$zero_grad()
    fcast <- neural_network(X_tensor_cat, X_tensor_numeric)
    loss  <- loss_fn(fcast, y_tensor)
    loss$backward()
    print(loss)
    optim$step()
  }

  # Return neural network structure
  structure(
    class = "basic_rnn_fit",
    list(
      neural_network = neural_network,
      categorical_features = categorical_features,
      index = index,
      key = key,
      optim = optim
    )
  )
}


predict_recurrent_impl <- function(obj, new_data, key, index, categorical_features = NULL){
  input_tensors <- resolve_data(new_data, key, index, categorical_features)
  X_tensor_numeric <- input_tensors[[1]]
  X_tensor_cat     <- input_tensors[[2]]
  tesnor_fcast  <- obj$neural_network(X_tensor_cat, X_tensor_numeric)
  as.vector(as.array(tesnor_fcast))
}
