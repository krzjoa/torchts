as_tensor.default <- function(.data, ...){
  UseMethod("as_tensor")
}

#' Convert a data.frame-like object to tensor
#
#' @param .data A data.frame-like object
#' @param ... Column names to wrap the data.frame-like object
#' @param dtype A torch_dtype instance
#' @param device A device created with torch_device()
#' @param requires_grad If autograd should record operations on the returned tensor.
#' @param pin_memory If set, returned tensor would be allocated in the pinned memory.
#'
#' @description
#'
#' The function converts an a data.frame-like object to torch_tensor instance.
#' If no column names are specified (as "three dots"), the function
#' simply transforms the input data to `matrix` and then to `torch_tensor`.
#'
#' The second scenario assumes that we need a `torch_tensor`,
#' which has more than two dimensions and some columns contains
#' indicators, how this wrapping should be performed.
#'
#' It's especially useful when transforming a data.frame containing
#' multiple (and, possibly, multivariate) time series.
#' When passing optional column names, function:
#' * arranges a data.frame by the given columns
#' * removes these columns from the data.frame
#' * creates a n-dimensional tensor with the following shape
#' (n_distinct(column_name_1), n_distinct(column_name_2), ..., number of other columns)
#'
#' @examples
#' # Simple data.frame-to-torch_tensor transformation
#' as_tensor(mtcars)
#'
#' # Transformation with column-wise data wraping
#' library(dplyr)
#'
#' euro_stock <-
#'   as.data.frame(EuStockMarkets) %>%
#'   mutate(idx = 1:n()) %>%
#'   tidyr::pivot_longer(c(DAX, SMI, CAC, FTSE))
#'
#' euro_stock
#'
#' euro_stock %>%
#'   as_tensor(name, idx)
#'
#' @export
as_tensor <- function(.data, ...,
                      dtype = NULL,
                      device = NULL,
                      requires_grad = TRUE,
                      pin_memory = FALSE){

  # TODO: a case when colun name matches a torch_tensor arg
  # special_names <- c(
  #   "dtype", "device",
  #   "requires_grad", "pin_memory"
  # )
  #
  # if (any(special_names %in% colnames(.data))) {
  #
  # }

  exprs <- rlang::exprs(...)

  if (length(exprs) == 0) {
    return(torch::torch_tensor(
      as.matrix(.data),
      dtype = dtype,
      device = device,
      requires_grad  = requires_grad,
      pin_memory = pin_memory
    ))
  }

  selected_cols <-
    as.character(exprs)

  other_cols    <-
    colnames(.data)[!(colnames(.data) %in% selected_cols)]

  tensor_size <- c(
    purrr::map_int(selected_cols, ~ n_distinct(.data[[.x]])),
    length(other_cols)
  )

  .data <- dplyr::arrange(.data, ...)
  .data <- dplyr::select(.data, -!!selected_cols)

  .array <-
    array(as.matrix(.data), dim = tensor_size)

  torch::torch_tensor(
    .array,
    dtype = dtype,
    device = device,
    requires_grad  = requires_grad,
    pin_memory = pin_memory
  )
}

