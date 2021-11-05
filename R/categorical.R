#' Check, if vector is categorical, i.e.
#' if is logical, factor, character or integer
#'
#' @param x A vector of arbitrary type
#'
#' @return Logical value
#'
#' @examples
#' is_categorical(c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE))
#' is_categorical(1:10)
#' is_categorical((1:10) + 0.1)
#' is_categorical(as.factor(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg")))
#' is_categorical(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg"))
#'
#' @export
is_categorical <- function(x){
  is.logical(x)   |
  is.factor(x)    |
  is.character(x) |
  is.integer(x)
}


#' Return size of categorical variables in the data.frame
#'
#' @param data (`data.frame`) A data.frame containing categorical variables.
#' The function automatically finds categorical variables,
#' calling internally [is_categorical] function.
#'
#' @return Named logical vector
#'
#' @examples
#' glimpse(tiny_m5)
#' dict_size(tiny_m5)
#'
#' # We can choose only the features we want - otherwise it automatically
#' # selects logical, factor, character or integer vectors
#'
#' tiny_m5 %>%
#'   select(store_id, event_name_1) %>%
#'   dict_size()
#'
#' @export
dict_size <- function(data){
  cols <- sapply(data, is_categorical)
  sapply(as.data.frame(data)[cols], dplyr::n_distinct)
}

