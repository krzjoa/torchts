#' Create a time series dataset from a `torch_tensor` matrix
#'
#' @param data (`data.frame`) An data.frame-like input object.
#' @param timesteps (`integer`) Number of timesteps for input tensor.
#' @param horizon (`integer`) Forecast horizon: number of timesteps for output tensor.
#' @param jump (`integer`) Jump length. By default: horizon length.
#' @param past_spec (`list`) Specification of the variables which values from the past will be available.
#' It should be a list with names representing names of tensors served by dataset, and values being feature indices.
#' @param future_spec (`list`) Specification of the variableswith known values from the future.
#' It should be a list with names representing names of tensors served b
#' @param categorical (`character`) Names of specified column subsets considered as categorical.
#' They will be provided as integer tensors.
#' @param sample_fram (`numeric`) A numeric value > 0. and <= 1 to sample a subset of data.
#' @param extras (`list`) List of extra object to be stored inside the ts_dataset object.
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
#'      past_spec = list(x_num = c('tmax_daily', 'tmin_daily')),
#'      future_spec   = list(y = 'tmax_daily')
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
                        jump = horizon,
                        past_spec  = list(x = NULL),
                        future_spec = list(y = NULL),
                        categorical = NULL,
                        sample_frac = 1,
                        extras = NULL, ...) {

    # Change unit test where non-tabular data handling is added
    if (!inherits(data, "data.frame"))
      stop("Provided wrong data object - is should inherit the data.frame class")

    # TODO: for now scaling system is simplified
    # TODO: check data types
    # TODO: check, if jump works correctly
    # TODO: consider adding margin to the last element if length %% horizon > 0
    # TODO: take into account last predicted values when computing scaling values?
    # Real life values, information leak

    all_vars <- unique(unlist(c(
        past_spec, future_spec
    )))

    data.table::setDT(data)

    self$data        <- data[, ..all_vars]
    self$margin      <- max(timesteps, horizon)
    self$timesteps   <- timesteps
    self$horizon     <- horizon
    self$jump        <- jump
    self$past_spec   <- past_spec
    self$future_spec <- future_spec
    self$extras      <- extras

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
    self$past_spec_num <- past_spec[
      !(names(past_spec) %in% categorical)
    ]

    self$past_spec_cat <- past_spec[
      names(past_spec) %in% categorical
    ]

    # Future variables
    self$future_spec_cat <- future_spec[
      names(future_spec) %in% categorical &
      grepl("x", names(future_spec))
    ]

    self$future_spec_num <- future_spec[
      !names(future_spec) %in% categorical &
      grepl("x", names(future_spec))
    ]

    self$outcomes_spec<- future_spec[
      grepl("y", names(future_spec))
    ]

  },

  .getitem = function(i) {

    past_start <- self$starts[i]
    past_end   <- past_start + self$timesteps - 1 # - self$horizon?

    future_start <- past_end + 1
    future_end   <- past_end + self$horizon

    past_num <- purrr::map(
      self$past_spec_num,
      ~ private$get_tensor(self$data, past_start:past_end, .x)
    )

    past_cat <- purrr::map(
      self$past_spec_cat,
      ~ private$get_tensor(self$data, past_start:past_end, .x, is_cat = TRUE)
    )

    future_num <-purrr::map(
      self$future_spec_num,
      ~ private$get_tensor(self$data, future_start:future_end, .x)
    )

    future_cat <-purrr::map(
      self$future_spec_cat,
      ~ private$get_tensor(self$data, future_start:future_end, .x, is_cat = TRUE)
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
      outcomes
    )

  },

  .length = function() {
    length(self$starts)
  },

  private = list(
    get_tensor = function(data, idx, cols, is_cat = FALSE){
      batch <- as.matrix(data[idx, ..cols])
      if (is_cat)
        return(torch_tensor(batch, dtype = torch_int()))
      else
        return(torch_tensor(batch, dtype = torch_float32()))
    }

  )

)

