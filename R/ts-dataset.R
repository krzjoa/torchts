#' Create a time series dataset from a `torch_tensor` matrix
#'
#' @param data (`torch_tensor`) An input data object. For now it only accepts two-dimensional tensor, i.e. matrices.
#' Each row is a timestep of a **single** time series.
#' @param timesteps (`integer`) Number of timesteps for input tensor.
#' @param horizon (`integer`) Forecast horizon: number of timesteps for output tensor.
#' @param jump (`integer`) Jump length. By default: horizon length.
#' @param predictors_spec (`list`) Input specification.
#' It should be a list with names representing names of tensors served by dataset, and values being feature indices.
#' @param outcomes_spec (`list`) Target specification.
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
#'      predictors_spec = list(x = 2:7),
#'      outcomes_spec   = list(y = 1),
#'      scale = TRUE
#'    )
#'
#' weather_pl_dataset$.getitem(1)
#'
#' @export
ts_dataset <- torch::dataset(
  name = "ts_dataset",

  initialize = function(data, timesteps, horizon, jump = horizon,
                        predictors_spec  = list(x = NULL),
                        outcomes_spec = list(y = NULL), categorical = NULL,
                        sample_frac = 1, scale = TRUE, extras = NULL, ...) {

    # Change unit test where non-tabular data handling is added
    if (length(dim(data)) > 2)
      stop("Data tensor has more than two dimensions.
            Handling of such objects in ts_dataset is not implemented yet.
            Provide a tabular-like tensor.")

    # TODO: check data types
    # TODO: check, if jump works correctly
    # TODO: consider adding margin to the last element if length %% horizon > 0
    # TODO: take into account last predicted values when computing scaling values?
    # Real life values, information leak

    # TODO: check col maps!!!!!

    # browser()

    self$data            <- data
    self$margin          <- max(timesteps, horizon)
    self$timesteps       <- timesteps
    self$horizon         <- horizon
    self$jump            <- jump
    self$predictors_spec <- predictors_spec
    self$outcomes_spec   <- outcomes_spec
    self$extras          <- extras

    # TODO: for now it doesn't handle keys
    n <- (nrow(self$data) - self$timesteps - self$horizon)
    n <- floor(n)

    # starts <- sample.int(
    #   n = n,
    #   size = n * sample_frac
    # )

    starts <- seq(1, n, jump)
    starts <- sample(starts, size = length(starts) * sample_frac)
    self$starts <- sort(starts)

    # WARNING: columns names are supposed to be in such order
    self$predictors_spec_num <- predictors_spec[
      !(names(predictors_spec) %in% categorical)
    ]

    self$predictors_spec_cat <- predictors_spec[
      names(predictors_spec) %in% categorical
    ]

    self$col_map     <- unique(unlist(predictors_spec))
    self$col_map_num <- unique(unlist(self$predictors_spec_num))
    self$col_map_cat <- unique(unlist(self$predictors_spec_cat))
    self$col_map_out <- unique(unlist(self$outcomes_spec))

    # If scale is a list and contains two values: mean and std
    # Compare: https://easystats.github.io/datawizard/reference/standardize.html
    if (is.list(scale) & all(c("mean", "sd") %in% names(scale))) {
      # TODO: additional check - length of scaling vector
      self$mean    <- as_tensor(scale$mean)
      self$sd      <- as_tensor(scale$sd)
      self$scale   <- TRUE
      self$scale_y <- TRUE
    } else if (scale) {
    # Otherwise, if scale is logical and TRUE, compute scaling params from the data
      self$mean    <- torch::torch_mean(self$data[, self$col_map_num], dim = 1, keepdim = TRUE)
      self$sd      <- torch::torch_std(self$data[, self$col_map_num], dim = 1, keepdim = TRUE)
      self$scale   <- TRUE
      self$scale_y <- TRUE
    } else {
      self$scale <- FALSE
    }

  },

  .getitem = function(i) {

    start <- self$starts[i]
    end   <- start + self$timesteps - 1 # - self$horizon?

    # Input columns
    # TODO: Dropping dimension in inputs and not in targets?
    # It seems to work in the simpliest case

    if (self$scale) {
      inputs_num <-
        purrr::map(
          self$predictors_spec_num,
          ~ (self$data[start:end, .x, drop = FALSE] - self$mean[.., match(.x, self$col_map_num)]) /
            self$sd[.., match(.x, self$col_map_num)]
        )
    } else {
      inputs_num <-
        purrr::map(
          self$predictors_spec_num, ~ self$data[start:end, .x, drop = FALSE]
        )
    }

    # Not scaled inputs
    if (length(unlist(self$predictors_spec_cat)) > 0)
      inputs_cat <-
        purrr::map(
          self$predictors_spec_cat, ~ self$data[start:end, .x, drop = FALSE]$to(torch_int())
        )
    else
      inputs_cat <- NULL

    inputs <- c(inputs_num, inputs_cat)

    if (self$scale_y) {
      targets <-
        purrr::map(
          self$outcomes_spec,
          ~ (self$data[(end + 1):(end + self$horizon), .x, drop = FALSE]
             - self$mean[.., match(.x, self$col_map_out)]) /
            self$sd[.., match(.x, self$col_map_out)]
        )
    } else {
      targets <-
        purrr::map(self$outcomes_spec,
                   ~ self$data[(end + 1):(end + self$horizon), .x, drop = FALSE])
    }



    c(inputs, targets)

  },

  .length = function() {
    length(self$starts)
  },

  # Active bindings
  # If there is no such params, returns list with two NULL values
  active = list(
    scale_params = function(){
      if (self$scale)
        list(mean = self$mean, sd = self$sd)
      else
        self$scale
    }
  )

)
