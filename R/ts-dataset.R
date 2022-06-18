#' Create a time series dataset from a `torch_tensor` matrix
#'
#' @param data (`data.frame`) An data.frame-like input object.
#' @param timesteps (`integer`) Number of timesteps for input tensor.
#' @param horizon (`integer`) Forecast horizon: number of timesteps for output tensor.
#' @param index Time index
#' @param key Column or columns, which determine the key for the time series
#' @param jump (`integer`) Jump length. By default: horizon length.
#' @param past (`list`) Specification of the variables which values from the past will be available.
#' It should be a list with names representing names of tensors served by dataset, and values being feature indices.
#' @param future (`list`) Specification of the variables with known values from the future.
#' It should be a list with names representing names of tensors served b
#' @param categorical (`character`) Names of specified column subsets considered as categorical.
#' They will be provided as integer tensors.
#' @param sample_fram (`numeric`) A numeric value > 0. and <= 1 to sample a subset of data.
#' @param extras (`list`) List of extra object to be stored inside the ts_dataset object.
#'
#' @import data.table
#'
#' @note
#' If `scale` is TRUE, only the input variables are scale and not the outcome ones.
#'
#' See: [Is it necessary to scale the target value in addition to scaling features for regression analysis? (Cross Validated)](https://stats.stackexchange.com/questions/111467/is-it-necessary-to-scale-the-target-value-in-addition-to-scaling-features-for-re)
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' library(torchts)
#'
#' tarnow_temp <-
#'   weather_pl %>%
#'   filter(station == 'TRN') %>%
#'   arrange(date)
#'
#' weather_pl_dataset <-
#'    ts_dataset(
#'      data = tarnow_temp,
#'      timesteps = 28,
#'      horizon = 7,
#'      past = list(x_num = c('tmax_daily', 'tmin_daily')),
#'      future   = list(y = 'tmax_daily')
#'    )
#'
#' debugonce(weather_pl_dataset$.getitem)
#' weather_pl_dataset$.getitem(1)
#'
#' @export
ts_dataset <- torch::dataset(

  name = "ts_dataset",

  initialize = function(data, timesteps,
                        horizon, index,
                        id = NULL,
                        jump = horizon,
                        past  = list(x = NULL),
                        future = list(y = NULL),
                        static = NULL,
                        categorical = NULL,
                        sample_frac = 1,
                        device = 'cpu',
                        extras = NULL, ...) {

    # Change unit test where non-tabular data handling is added
    if (!inherits(data, "data.frame"))
      stop("Provided wrong data object - is should inherit the data.frame class")

    # TODO: check data types
    # TODO: check, if jump works correctly
    # TODO: consider adding margin to the last element if length %% horizon > 0
    # TODO: Real life values, information leak

    all_vars <- unique(unlist(c(
        past, future, static
    )))

    setDT(data)

    # TODO: replace with active binding
    self$data        <- data[, ..all_vars]
    self$margin      <- max(timesteps, horizon)
    self$timesteps   <- timesteps
    self$horizon     <- horizon
    self$jump        <- jump
    self$past        <- past
    self$future      <- future
    self$extras      <- extras
    self$device      <- device

    # Setting order
    # setorderv(data, index)

    # TODO: for now it doesn't handle keys
    # TODO: Proper length
    n <- (nrow(self$data) - self$timesteps - self$horizon) + 1
    n <- floor(n)

    starts <- seq(1, n, jump)
    starts <- sample(starts, size = length(starts) * sample_frac)
    self$starts <- sort(starts)

    # WARNING: columns names are supposed to be in such order

    # Past variables
    self$past_num <- past[
      !(names(past) %in% categorical)
    ]

    self$past_cat <- past[
      names(past) %in% categorical
    ]

    # Future variables
    self$future_cat <- future[
      names(future) %in% categorical &
      grepl("x", names(future))
    ]

    self$future_num <- future[
      !names(future) %in% categorical &
      grepl("x", names(future))
    ]

    # Static variables
    self$static_cat <- static[
      names(static) %in% categorical &
        grepl("x", names(static))
    ]

    self$static_num <- static[
      !names(static) %in% categorical &
        grepl("x", names(static))
    ]

    # Outcomes
    self$outcomes_spec<- future[
      grepl("y", names(future))
    ]

  },

  .getitem = function(i) {

    past_start <- self$starts[i]
    past_end   <- past_start + self$timesteps - 1 # - self$horizon?

    future_start <- past_end + 1
    future_end   <- past_end + self$horizon

    past_num <- purrr::map(
      self$past_num,
      ~ private$get_tensor(self$data, past_start:past_end, .x)
    )

    past_cat <- purrr::map(
      self$past_cat,
      ~ private$get_tensor(self$data, past_start:past_end, .x, is_cat = TRUE)
    )

    future_num <-purrr::map(
      self$future_num,
      ~ private$get_tensor(self$data, future_start:future_end, .x)
    )

    future_cat <-purrr::map(
      self$future_cat,
      ~ private$get_tensor(self$data, future_start:future_end, .x, is_cat = TRUE)
    )

    static_num <-purrr::map(
      self$static_num,
      ~ private$get_tensor(self$data, static_start:static_end, .x, is_static = TRUE)
    )

    static_cat <-purrr::map(
      self$static_cat,
      ~ private$get_tensor(self$data, static_start:static_end, .x,
                           is_cat = TRUE, is_static = TRUE)
    )

    outcomes <- purrr::map(
      self$outcomes_spec,
      ~ private$get_tensor(self$data, future_start:future_end, .x)
    )

    c(
      past_num,
      past_cat,
      future_num,
      future_cat,
      static_num,
      static_cat,
      outcomes
    )

  },

  .length = function() {
    length(self$starts)
  },

  private = list(
    get_tensor = function(data, idx, cols, is_cat = FALSE, is_static = FALSE){
      setDT(data)

      if (is_static)
        batch <- as.matrix(unique(data[, ..cols]))
      else
        batch <- as.matrix(data[idx, ..cols])

      if (is_cat)
        tensor <- torch_tensor(batch, dtype = torch_int())
      else
        tensor <- torch_tensor(batch, dtype = torch_float32())

      set_device(tensor, device = self$device)
    }

  )

)

