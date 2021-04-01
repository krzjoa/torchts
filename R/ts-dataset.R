#' Default time series dataset handler
#'
#' @param data (data.frame) An input
ts_dataset <- function(data, formula){
  dataset(
    name = "ts_dataset",

    initialize = function(x, n_timesteps, sample_frac = 1) {

      self$n_timesteps <- n_timesteps
      self$x <- torch_tensor((x - train_mean) / train_sd)

      n <- length(self$x) - self$n_timesteps

      self$starts <- sort(sample.int(
        n = n,
        size = n * sample_frac
      ))

    },

    .getitem = function(i) {

      start <- self$starts[i]
      end <- start + self$n_timesteps - 1

      list(
        x = self$x[start:end],
        y = self$x[end + 1]
      )

    },

    .length = function() {
      length(self$starts)
    }
  )
}
