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
#' model <- basic_rnn_fit(x, y, key = "item_id", index = "date", n_epochs = 1000)
#' fcast <- predict_basic_rnn_impl(model, x, key = "item_id", index = "date")
#' View(bind_cols(y, fcast))
#'
#' Idea:
#' - rnn_reg for parsnip
#' - ts_rnn for fable (ts prefix for fable)
basic_rnn_fit <- function(x, y, key, index, categorical_features = NULL,
                          backward = NULL, optim = optim_adam(), batch_size = 1,
                          n_epochs = 10, loss_fn = nnf_mse_loss, plugins = NULL){

  #' Search for factor or character variables
  #' TODO: add messages, when factors o character variables detected (not mentioned in categorical_features)
  #' TOOD: use data.table?
  features             <- base::setdiff(colnames(x), c(key, index))
  factor_features      <- features[sapply(x, is.factor)]
  character_features   <- features[sapply(x, is.character)]
  categorical_features <- c(categorical_features, factor_features, character_features)
  categorical_features <- unique(categorical_features)

  if (!is.null(backward)) {
    warning("Backward is not implemented yet!")
  }

  #' Categorical features
  #' These features have to have integer values, so we choose `torch_long()`
  #' It's because module `nn_embedding` treats each categorical column as a vector
  #' of indices.
  if (!is.null(categorical_features)) {
    X_tensor_cat <-
      x %>%
      select(!!key, !!index, !!categorical_features) %>%
      arrange(!!key, !!index) %>%
      as_tensor(!!key, !!index, dtype = torch_long())
  }

  X_tensor_numeric <-
    x %>%
    select(-!!categorical_features) %>%
    arrange(!!key, !!index) %>%
    as_tensor(!!key, !!index, dtype = torch_float())

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
  neural_network <- basic_rnn(
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

predict_basic_rnn_impl <- function(obj, new_data, key, index, categorical_features = NULL){
  #' Search for factor or character variables
  #' TODO: add messages, when factors o character variables detected (not mentioned in categorical_features)
  #' TOOD: use data.table?
  features             <- base::setdiff(colnames(new_data), c(key, index))
  factor_features      <- features[sapply(new_data, is.factor)]
  character_features   <- features[sapply(new_data, is.character)]
  categorical_features <- c(categorical_features, factor_features, character_features)
  categorical_features <- unique(categorical_features)

  #' Categorical features
  #' These features have to have integer values, so we choose `torch_long()`
  #' It's because module `nn_embedding` treats each categorical column as a vector
  #' of indices.
  if (!is.null(categorical_features)) {
    X_tensor_cat <-
      new_data %>%
      select(!!key, !!index, !!categorical_features) %>%
      arrange(!!key, !!index) %>%
      as_tensor(!!key, !!index, dtype = torch_long())
  }

  X_tensor_numeric <-
    new_data %>%
    select(-!!categorical_features) %>%
    arrange(!!key, !!index) %>%
    as_tensor(!!key, !!index, dtype = torch_float())

  tesnor_fcast <- obj$neural_network(X_tensor_cat, X_tensor_numeric)
  as.vector(as.array(tesnor_fcast))
}
