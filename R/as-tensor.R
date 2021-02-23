#' @name as_tensor
#' @title Convert an object to tensor
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
#' # Transformation with column-wise data wrapping
#' library(dplyr)
#' library(torchts)
#'
#' # ts class - default
#' air_passengers <- as_tensor(AirPassengers)
#' class(air_passengers)
#' dim(air_passengers)
#'
#' # ts class using data frequency
#' air_passengers <-
#'   AirPassengers %>%
#'   as_tensor(frequency(.))
#' class(air_passengers)
#' dim(air_passengers)
#'
#' # ts class using arbitrary frequency
#'
#' euro_stock
#'
#' @export
as_tensor <- function(.data, ..., dtype = NULL,
                      device = NULL,
                      requires_grad = FALSE,
                      pin_memory = FALSE){
  UseMethod("as_tensor")
}

#' @export
#' @rdname as_tensor
as_tensor.default <- function(.data, dtype = NULL,
                              device = NULL,
                              requires_grad = FALSE,
                              pin_memory = FALSE){
  torch::torch_tensor(
    data = .data,
    dtype = dtype,
    device = device,
    requires_grad = requires_grad,
    pin_memory = pin_memory
  )
}

#' @export
#' @rdname as_tensor
as_tensor.data.frame <- function(.data, ...,
                      dtype = NULL,
                      device = NULL,
                      requires_grad = FALSE,
                      pin_memory = FALSE){

  #' TODO: a case when column name matches a torch_tensor arg
  #' TODO: number of all the elements in tensor vs
  #' case as_tensor(euro_stock, name)
  #' TODO: accept formulas?
  #' Something like value ~ wday + month
  #' but we need to handle shapes for such output tensors

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

#' @export
#' @rdname as_tensor
as_tensor.ts <- function(.data, by = NULL,
                         dtype = NULL,
                         device = NULL,
                         requires_grad = FALSE,
                         pin_memory = FALSE){

  # TODO: add natural language handling
  if (is.null(by)) {
    return(torch::torch_tensor(
      array(.data, dim = c(1, length(.data), 1)),
      dtype = dtype,
      device = device,
      requires_grad  = requires_grad,
      pin_memory = pin_memory
    ))
  }

  # .frequency <- frequency(.data)
  .array <-
    array(.data, dim = c(length(.data)/by, by, 1))

  torch::torch_tensor(
    .array,
    dtype = dtype,
    device = device,
    requires_grad  = requires_grad,
    pin_memory = pin_memory
  )
}

#' @export
#' @rdname as_tensor
as_tensor.mts <- function(.data, ...,
                          dtype = NULL,
                          device = NULL,
                          requires_grad = FALSE,
                          pin_memory = FALSE){
  .args <- rlang::exprs(...)

  .data <- EuStockMarkets
  .initial_colnames <- colnames(.data)

  # .frequency <- frequency(.data)
  .data <- tibble::as_tibble(.data)
  .data <- dplyr::mutate(.data, index = 1:n())
  .data <- tidyr::pivot_longer(.data, dplyr::all_of(.initial_colnames))

  if (length(.args) == 0) {
    return(as_tensor(.data, name, index, dtype = dtype, device = device,
              requires_grad = requires_grad, pin_memory = pin_memory))
  }

  as_tensor(
    .data, ..., dtype = dtype, device = device,
    requires_grad = requires_grad, pin_memory = pin_memory
  )
}

#' @export
#' @rdname as_tensor
as_tensor.tsibble <- function(.data, ...,
                              dtype = NULL,
                              device = NULL,
                              requires_grad = FALSE,
                              pin_memory = FALSE){
  NULL
}

