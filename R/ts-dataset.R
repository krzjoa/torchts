#' Create a time series dataset object
#'
#' @param data (torch_tensor) An input data object
#' @param n_timesteps (integer) Number of timesteps for input tensor
#' @param h (integer) Forecast horizon: number of timesteps for output tensor
#' @param input_columns (list) Output specification
#' @param target_columns (list) Output specification
#' @param sample_fram (numeric) A numeric value > 0. and <= 1 to sample a subset of data
#' @param scale (logical) Scale feature columns
#'
#' @examples
#' suppressMessages(library(dplyr))
#' library(torchts)
#' data("mts-examples", package="MTS")
#'
#' ibmspko <-
#'     ibmspko %>%
#'     select(date, ibm)
#'
#' ibm_tensor <- as_tensor(ibmspko, date)
#'
#' ibm_dataset <-
#'     ts_dataset(ibm_tensor, n_timesteps = 7, h = 7)
#'
#' ibm_dataset$.getitem(1)
#'
#' @export
ts_dataset <- torch::dataset(
  name = "ts_dataset",

  initialize = function(data, n_timesteps, h,
                        input_columns  = list(x = NULL),
                        target_columns = list(y = NULL),
                        sample_frac = 1, scale = TRUE) {

    # TODO: check data types
    self$data           <- data
    self$margin         <- max(n_timesteps, h)
    self$n_timesteps    <- n_timesteps
    self$h              <- h
    self$input_columns  <- input_columns
    self$target_columns <- target_columns

    n <- nrow(self$data) - self$n_timesteps

    self$starts <- sort(sample.int(
      n = n,
      size = n * sample_frac
    ))

    # How to keeo dimensions?
    if (scale) {
      self$mean <- torch::torch_mean(self$data[, unlist(input_columns)], dim = 1)
      self$std  <- torch::torch_std(self$data[, unlist(input_columns)], dim = 1)
    }

  },

  .getitem = function(i) {

    start <- self$starts[i]
    end   <- start + self$n_timesteps - 1

    # Input columns
    # TODO: Dropping dimension in inputs and not in targets?
    # It seems to work in the simpliest case
    inputs <-
      purrr::map(self$input_columns, ~ self$data[start:end, .x, drop = FALSE])

    targets <-
      purrr::map(self$target_columns, ~ self$data[(end + 1):(end + self$h), .x])

    c(
      inputs,
      targets
    )

  },

  .length = function() {
    length(self$starts)
  }

)
