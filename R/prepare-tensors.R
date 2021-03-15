#' Prepare tensors
#'
#' @param x
#' @param key
#' @param index
#' @param categorical_features
#'
#' @export
resolve_data <- function(x, key, index, categorical_features = NULL){
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
  } else {
    X_tensor_cat <- NULL
  }

  X_tensor_numeric <-
    new_data %>%
    select(-!!categorical_features) %>%
    arrange(!!key, !!index) %>%
    as_tensor(!!key, !!index, dtype = torch_float())

  return(list(X_tensor_numeric, X_tensor_cat))
}
