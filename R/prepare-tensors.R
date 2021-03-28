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
  features             <- base::setdiff(colnames(x), c(key, index))
  factor_features      <- features[sapply(x, is.factor)]
  character_features   <- features[sapply(x, is.character)]

  other_categorical   <- c(factor_features, character_features)

  not_mentioned_categorical <-
    other_categorical[!(other_categorical %in% categorical_features)]

  if (length(not_mentioned_categorical) > 0)
    warning(glue(
      "A number of features (factor or character) were found in the data," ,
      "but there were not listed as categorical.",
      "These features will be added automatically",
      "[{paste0(not_mentioned_categorical, collapse = ',')}]"
    ))

  categorical_features <- c(categorical_features, not_mentioned_categorical)

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
  } else {
    X_tensor_cat <- NULL
  }

  X_tensor_numeric <-
    x %>%
    select(-!!categorical_features) %>%
    arrange(!!key, !!index) %>%
    as_tensor(!!key, !!index, dtype = torch_float())

  return(list(X_tensor_numeric, X_tensor_cat))
}
