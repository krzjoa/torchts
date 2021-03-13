#' Basic RNN model for time series forecasting
#'
#' @param x Input features
#' @param y Targets
#' @param categorical_features List of categorical feature columns from data.frame x
#' @param optim An optimizer with arguments
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
#' Idea:
#' - rnn_reg for parsnip
#' - ts_rnn for fable (ts prefix for fable)
basic_rnn_fit <- function(x, y, key, index, categorical_features = NULL){

  #' Search for factor or character variables
  #' TODO: add messages, when factors o character variables detected (not mentioned in categorical_features)
  features             <- base::setdiff(colnames(x), c(key, index))
  factor_features      <- features[sapply(x, is.factor)]
  character_features   <- features[sapply(x, is.character)]
  categorical_features <- c(categorical_features, factor_features, character_features)
  categorical_features <- unique(categorical_features)

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


  # Creating a neural network


}
