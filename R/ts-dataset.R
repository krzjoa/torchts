#' Create a time series dataset from a `torch_tensor` matrix
#'
#' @param data (`torch_tensor`) An input data object. For now it only accepts two-dimensional tensor, i.e. matrices.
#' Each row is a timestep of a **single** time series.
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
#' @param scale (`logical` or `list`) Scale feature columns. Boolean flag or list with `mean` and `sd` values.
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
#' weather_pl_tensor <-
#'   weather_pl %>%
#'   filter(station == "TRN") %>%
#'   select(-station, -rr_type) %>%
#'   as_tensor(date)
#'
#' # We obtained a matrix (i.e. tabular data in the form of 2-dimensional tensor)
#' dim(weather_pl_tensor)
#'
#' weather_pl_dataset <-
#'    ts_dataset(
#'      data = weather_pl_tensor,
#'      timesteps = 28,
#'      horizon = 7,
#'      past_spec = list(x = 2:7),
#'      future_spec   = list(y = 1),
#'      scale = TRUE
#'    )
#'
#' weather_pl_dataset$.getitem(1)
#'
#' @export
ts_dataset <- torch::dataset(
  name = "ts_dataset",

  initialize = function(data, timesteps, horizon, jump = horizon,
                        past_spec  = list(x = NULL),
                        future_spec = list(y = NULL), categorical = NULL,
                        sample_frac = 1, scale = TRUE, extras = NULL, ...) {

    # Change unit test where non-tabular data handling is added
    if (length(dim(data)) > 2)
      stop("Data tensor has more than two dimensions.
            Handling of such objects in ts_dataset is not implemented yet.
            Provide a tabular-like tensor.")

    # TODO: for now scaling system is simplified

    # TODO: check data types
    # TODO: check, if jump works correctly
    # TODO: consider adding margin to the last element if length %% horizon > 0
    # TODO: take into account last predicted values when computing scaling values?
    # Real life values, information leak

    # TODO: check col maps!!!!!
    self$data            <- data
    self$margin          <- max(timesteps, horizon)
    self$timesteps       <- timesteps
    self$horizon         <- horizon
    self$jump            <- jump
    self$past_spec <- past_spec
    self$future_spec   <- future_spec
    self$extras          <- extras

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

    # TODO: to be removed
    self$col_map     <- unique(unlist(past_spec))
    self$col_map_num <- unique(unlist(self$past_spec_num))
    self$col_map_cat <- unique(unlist(self$past_spec_cat))
    self$col_map_out <- unique(unlist(self$future_spec))

    # If scale is a list and contains two values: mean and std
    # Compare: https://easystats.github.io/datawizard/reference/standardize.html
    # For now, it always scale
    if (is.list(scale) & all(c("mean", "sd") %in% names(scale))) {
      # TODO: additional check - length of scaling vector
      self$mean    <- as_tensor(scale$mean)
      self$sd      <- as_tensor(scale$sd)
      self$scale   <- TRUE
      self$scale_y <- TRUE
    } else if (scale) {
    # Otherwise, if scale is logical and TRUE, compute scaling params from the data
      # self$mean    <- torch::torch_mean(self$data[, self$col_map_num], dim = 1, keepdim = TRUE)
      # self$sd      <- torch::torch_std(self$data[, self$col_map_num], dim = 1, keepdim = TRUE)
      self$mean    <- torch::torch_mean(self$data, dim = 1, keepdim = TRUE)
      self$sd      <- torch::torch_std(self$data, dim = 1, keepdim = TRUE)
      self$scale   <- TRUE
      self$scale_y <- TRUE
    } else {
      self$scale   <- FALSE
      self$scale_y <- FALSE
    }

  },

  .getitem = function(i) {

    start <- self$starts[i]
    end   <- start + self$timesteps - 1 # - self$horizon?

    # Input columns
    # TODO: Dropping dimension in past and not in future?
    # It seems to work in the simplest case

    if (self$scale) {
      past_num <-
        purrr::map(
          self$past_spec_num,
          ~ (self$data[start:end, .x, drop = FALSE] - self$mean[.., .x]) /
            self$sd[.., .x]
        )
    } else {
      past_num <-
        purrr::map(
          self$past_spec_num, ~ self$data[start:end, .x, drop = FALSE]
        )
    }

    # Not scaled past
    if (length(unlist(self$past_spec_cat)) > 0)
      past_cat <-
        purrr::map(
          self$past_spec_cat, ~ self$data[start:end, .x, drop = FALSE]$to(torch_int())
        )
    else
      past_cat <- NULL

    past <- c(past_num, past_cat)


    # Future values
    if (self$scale) {
      fut_num <-
        purrr::map(
          self$future_spec_num,
          ~ (self$data[(end + 1):(end + self$horizon), .x, drop = FALSE]
             - self$mean[.., .x]) / self$sd[.., .x]
        )
    } else {
      fut_num <-
        purrr::map(self$future_spec_num,
                   ~ self$data[(end + 1):(end + self$horizon), .x, drop = FALSE])
    }

    fut_cat <-
      purrr::map(self$future_spec_cat,
                 ~ self$data[(end + 1):(end + self$horizon), .x, drop = FALSE])


    if (self$scale_y) {
      y <-
        purrr::map(
          self$outcomes_spec,
          ~ (self$data[(end + 1):(end + self$horizon), .x, drop = FALSE]
             - self$mean[.., .x]) / self$sd[.., .x]
        )
    } else {
      y <-
        purrr::map(self$outcomes_spec,
                   ~ self$data[(end + 1):(end + self$horizon), .x, drop = FALSE])
    }


    future <- c(fut_num, fut_cat, y)

    output <- c(past, future)

    # Resahping for MLP
    output <- purrr::map(output, ~ .x$reshape(-1))

    output

  },

  .length = function() {
    length(self$starts)
  },

  # Active bindings
  # If there is no such params, returns list with two NULL values
  active = list(
    scale_params = function(){
      if (self$scale)
        list(mean = self$mean$cpu(), sd = self$sd$cpu())
      else
        self$scale
    }
  )

)
