#' Create a tensor to handle time series data
#'
#' @export
as_dataset <- function(.data, formula, sample_frac){
  UseMethod("as_dataset")
}


as_dataset.data.frame <- function(.data, formula, sample_frac){
  .data
}
