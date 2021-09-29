#' Create a time series dataset object
#'
#' @param data (torch_tensor) An input data object
#' @param timesteps (integer) Number of timesteps for input tensor
#' @param h (integer) Forecast horizon: number of timesteps for output tensor
#' @param jump (integer) Jump length. By default: horizon length
#' @param input_columns (list) Output specification
#' @param target_columns (list) Output specification
#' @param sample_fram (numeric) A numeric value > 0. and <= 1 to sample a subset of data
#' @param scale (logical) Scale feature columns
#'
#' @note
#' If `scale` is TRUE, only the input vaiables are scale and not the outcome ones.
#' See: [Is it necessary to scale the target value in addition to scaling features for regression analysis? (Cross Validated)](https://stats.stackexchange.com/questions/111467/is-it-necessary-to-scale-the-target-value-in-addition-to-scaling-features-for-re)
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
#'     ts_dataset(ibm_tensor, timesteps = 7, h = 7)
#'
#' ibm_dataset$.getitem(1)
#'
#' @export
ts_dataset <- torch::dataset(
  name = "ts_dataset",

  initialize = function(data, timesteps, h, jump = h,
                        input_columns  = list(x = NULL),
                        target_columns = list(y = NULL),
                        sample_frac = 1, scale = TRUE) {

    # TODO: check data types
    # TODO: check, if jump works correctly
    self$data           <- data
    self$margin         <- max(timesteps, h)
    self$timesteps      <- timesteps
    self$h              <- h
    self$jump           <- jump
    self$input_columns  <- input_columns
    self$target_columns <- target_columns

    n <- (nrow(self$data) - self$timesteps) / self$jump
    n <- floor(n)

    self$starts <- sort(sample.int(
      n = n,
      size = n * sample_frac
    ))

    #' WARNING: columns names are supposed to be in such order
    self$col_map <- unique(unlist(input_columns))

    # If scale is a list and contains two values: mean and std
    # TODO: unify naming - sd ather than std. See: recipes (https://recipes.tidymodels.org/reference/step_normalize.html)
    # Compare: https://easystats.github.io/datawizard/reference/standardize.html
    if (is.list(scale) & all(c("mean", "std") %in% names(scale))) {
      # TODO: additional check - length of scaling vector
      self$mean  <- scale$mean
      self$std   <- scale$std
      self$scale <- TRUE
    } else if (scale) {
    # Otherwise, if scale is logical and TRUE, comute scaling params from the data
      self$mean    <- torch::torch_mean(self$data[, self$col_map], dim = 1, keepdim = TRUE)
      self$std     <- torch::torch_std(self$data[, self$col_map], dim = 1, keepdim = TRUE)
      self$scale   <- TRUE
    }

  },

  .getitem = function(i) {

    # if (dev)
    #   browser()

    start <- self$starts[i * self$jump]
    end   <- start + self$timesteps - 1

    # Input columns
    # TODO: Dropping dimension in inputs and not in targets?
    # It seems to work in the simpliest case

    if (self$scale) {
      inputs <-
        purrr::map(
          self$input_columns,
          ~ (self$data[start:end, .x, drop = FALSE] - self$mean[.., match(.x, self$col_map)]) /
            self$std[.., match(.x, self$col_map)]
        )
    } else {
      inputs <-
        purrr::map(
          self$input_columns, ~ self$data[start:end, .x, drop = FALSE]
        )
    }

    targets <-
      purrr::map(self$target_columns, ~ self$data[(end + 1):(end + self$h), .x])

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
        list(mean = self$mean, std = self$std)
      else
        self$scale
    }
  )

)
