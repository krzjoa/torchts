#' Convert an object to tensor
#
#' @param data A data.frame-like object, `array`, `ts` or `torch_tensor`
#' @param ... Column names to reshape the data.frame-like object into a n-dimensional tensor
#' @param by For `ts` objects only. The length of time series to reshape the time series into tensor.
#' @param dtype A torch_dtype instance
#' @param device A device created with torch_device()
#' @param requires_grad If autograd should record operations on the returned tensor.
#' @param pin_memory If set, returned tensor would be allocated in the pinned memory.
#'
#' @description
#'
#' The function converts an an object to `torch_tensor` instance.
#' Possible arguments differ a little bit depending on the input object class.
#'
#' * `torch_tensor`
#'
#'    Returns identical `torch_tensor`, but changes dtype or device if specified.
#'    Three dots arguments are ignored for now.
#'
#' * `data.frame`
#'
#'   If no column names are specified (as "three dots"), the function
#'   simply transforms the input data to `matrix` and then to `torch_tensor`.
#'
#'   The second scenario assumes that we need a `torch_tensor`,
#'   which has more than two dimensions and some columns contains
#'   indicators, how this wrapping should be performed.
#'
#'   It's especially useful when transforming a data.frame containing
#'   multiple (and, possibly, multivariate) time series.
#'   When passing optional column names, function:
#'
#'   * arranges a data.frame by the given columns
#'   * removes these columns from the data.frame
#'   * creates a n-dimensional tensor with the following shape
#'   (n_distinct(column_name_1), n_distinct(column_name_2), ..., number of other columns)
#'
#' * `ts`
#'
#'   If `by` is not specified, it returns a tensor of shape `(1, length(object), 1)`.
#'   If we use any `by`, the output shape is `(length(data)/by, by, 1)`
#'
#' @return
#' An object of `torch_tensor` class
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' library(torchts)
#'
#' # Simple data.frame-to-torch_tensor transformation
#' as_tensor(head(mtcars))
#'
#' # Transformation with column-wise data wrapping
#' weather_tensor <-
#'   weather_pl %>%
#'   select(-rr_type) %>%
#'   as_tensor(station, date)
#'
#' dim(weather_tensor)
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
#'
#' class(air_passengers)
#' dim(air_passengers)
#'
#' # ts class using arbitrary frequency
#' air_passengers <-
#'  as_tensor(AirPassengers, 6)
#'
#' class(air_passengers)
#' dim(air_passengers)
#'
#' @export
as_tensor <- function(data, ..., dtype = NULL,
                      device = NULL,
                      requires_grad = FALSE,
                      pin_memory = FALSE){
  UseMethod("as_tensor")
}

#' @export
#' @rdname as_tensor
as_tensor.default <- function(data, dtype = NULL,
                              device = NULL,
                              requires_grad = FALSE,
                              pin_memory = FALSE){
  torch::torch_tensor(
    data = data,
    dtype = dtype,
    device = device,
    requires_grad = requires_grad,
    pin_memory = pin_memory
  )
}

#' @export
#' @rdname as_tensor
as_tensor.torch_tensor <- function(data, ...,
                                   dtype = NULL,
                                   device = NULL,
                                   requires_grad = FALSE){
  data <- data$to(
    dtype  = dtype,
    device = device
  )

  # Inplace operation
  data$requires_grad_(requires_grad)

  # data$pin_memory()

  data
}

#' @export
#' @rdname as_tensor
as_tensor.data.frame <- function(data, ...,
                      dtype = NULL,
                      device = NULL,
                      requires_grad = FALSE,
                      pin_memory = FALSE){

  # TODO: a case when column name matches a torch_tensor arg
  # TODO: number of all the elements in tensor vs
  # case as_tensor(euro_stock, name)
  # TODO: accept formulas?
  # Something like value ~ wday + month
  # but we need to handle shapes for such output tensors

  # special_names <- c(
  #   "dtype", "device",
  #   "requires_grad", "pin_memory"
  # )
  #
  # if (any(special_names %in% colnames(data))) {
  #
  # }

  # TODO: check different types (for instance: numeric and integer)
  # TODO: add data.table (keys)
  # TODO: add tsibble

  ALLOWED_TYPES <- c("Date", "numeric", "inter")

  # Check column types
  col_types <- sapply(data, class)
  not_allowed <- !(col_types %in% ALLOWED_TYPES)

  exprs <- rlang::exprs(...)

  if (length(exprs) == 0) {

    if (length(unique(col_types)) > 1)
      stop(glue::glue(
        "Cannot convert this object to torch_tensor.
         Various column types found. If no colnames are specified
         in the as_tensor function, you have to convert all them to one,
         convertible numeric-like type.
         Date, character, list etc. cannot be correctly interpreted."
      ))

    return(torch::torch_tensor(
      as.matrix(data),
      dtype = dtype,
      device = device,
      requires_grad  = requires_grad,
      pin_memory = pin_memory
    ))
  }

  selected_cols <-
    Reduce(c, sapply(exprs, as.character))

  other_cols    <-
    colnames(data)[!(colnames(data) %in% selected_cols)]

  tensor_size <- c(
    purrr::map_int(selected_cols, ~ n_distinct(data[[.x]])),
    length(other_cols)
  )

  data <- dplyr::arrange(data, ...)
  data <- dplyr::select(data, -!!selected_cols)

  .array <-
    array(as.matrix(data), dim = tensor_size)

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
as_tensor.ts <- function(data, by = NULL,
                         dtype = NULL,
                         device = NULL,
                         requires_grad = FALSE,
                         pin_memory = FALSE){

  # TODO: add natural language handling
  if (is.null(by)) {
    return(torch::torch_tensor(
      array(data, dim = c(1, length(data), 1)),
      dtype = dtype,
      device = device,
      requires_grad  = requires_grad,
      pin_memory = pin_memory
    ))
  }

  # .frequency <- frequency(data)
  .array <-
    array(data, dim = c(length(data)/by, by, 1))

  torch::torch_tensor(
    .array,
    dtype = dtype,
    device = device,
    requires_grad  = requires_grad,
    pin_memory = pin_memory
  )

}


