# Metrics

#' Mean absolute percentage error
#'
#' @param input (`torch_tensor`) A tensor of actual values
#' @param target (`torch_tensor`) A tensor with the same shape as the input
#'
#' @details
#' Computed according to the formula:
#' \deqn{MAPE = \frac{1}{n}\displaystyle\sum_{t=1}^{n} \left\|\frac{target - input}{target}\right\|}
#'
#' @seealso
#' [yardstick::mape]
#'
#' @examples
#' input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27.8, 70.96)
#' input <- as_tensor(input)
#'
#' target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
#' target <- as_tensor(target)
#'
#' nnf_mape(input, target)
#'
#' @export
nnf_mape <- function(input, target){
  mean(abs((target - input) / target))
}


#' Symmetric mean absolute percentage error
#'
#' @param input (`torch_tensor`) A tensor of actual values
#' @param target (`torch_tensor`) A tensor with the same shape as the input
#'
#' @details
#' Computed according to the formula:
#' \deqn{SMAPE = \frac{1}{n}\displaystyle\sum_{t=1}^{n} \frac{\left\|input - target\right\|}{(\left\|target\right\| + \left\|input\right\|) *0.5}}
#'
#' @seealso
#' [yardstick::smape]
#'
#' @examples
#' input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27.8, 70.96)
#' input <- as_tensor(input)
#'
#' target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
#' target <- as_tensor(target)
#'
#' nnf_smape(input, target)
#'
#' @export
nnf_smape <- function(input, target){
    # Verify and change: input vs target
    # Target = actual values
    numerator   <- abs(input - target)
    denominator <- ((abs(target) + abs(input)) / 2)
    mean(numerator / denominator)
}


#' Mean absolute error
#'
#' @param input (`torch_tensor`) A tensor of actual values
#' @param target (`torch_tensor`) A tensor with the same shape as the input
#'
#' @details
#'
#' Computed according to the formula:
#' \deqn{MAE = \frac{1}{n}\displaystyle\sum_{t=1}^{n}\left\|target - input\right\|}
#'
#' @seealso
#' [yardstick::mae]
#'
#' @examples
#' input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27.8, 70.96)
#' input <- as_tensor(input)
#'
#' target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
#' target <- as_tensor(target)
#'
#' nnf_mae(input, target)
#'
#' @export
nnf_mae <- function(input, target){
  mean(abs(target - input))
}


#' Mean absolute scaled error
#'
#' @param input (`torch_tensor`) A tensor of actual values
#' @param target (`torch_tensor`) A tensor with the same shape as the input
#'
#' @details
#'
#' Computed according to the formula:
#' \deqn{MASE = \displaystyle\frac{MAE_{out-of-sample}}{\frac{1}{n-1}\sum_{i=2}^{n}\left\|a_i - a_{i-1}\right\|} }
#'
#' @seealso
#' [yardstick::mase]
#'
#' @references
#' [Rob J. Hyndman (2006). ANOTHER LOOK AT FORECAST-ACCURACY METRICS
#'  FOR INTERMITTENT DEMAND. _Foresight_, 4, 46.](https://robjhyndman.com/papers/foresight.pdf)
#'
#' @examples
#' input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27.8, 70.96)
#' input <- as_tensor(input)
#'
#' target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
#' target <- as_tensor(target)
#'
#' nnf_mae(input, target)
#'
# nnf_mase <- function(y_pred, target, in_sample_actual){
#   numerator   <- mean(abs(y_pred - target))
#   # In-sample naive forecast
#
#   denominator <- mean(diffs)
#   numerator / denominator
# }


#' Weighted Absolute Percentage Error
#'
#' @param input tensor (N,*) where ** means, any number of additional dimensions
#' @param target tensor (N,*) , same shape as the input
#'
#' @details
#' Known also as WMAPE or wMAPE (Weighted Mean Absolute Percentage Error)
#' However, sometimes WAPE and WMAPE metrics are [distinguished](https://www.baeldung.com/cs/mape-vs-wape-vs-wmape).
#'
#' Variant of [nnf_mape()], but weighted with target values.
#'
#' Computed according to the formula:
#' \deqn{MAPE = \frac{1}{n}\displaystyle\sum_{t=1}^{n} \abs{\frac{target - input}{target}}}
#'
# nnf_wape <- function(input, target){
#   mean(abs(target - input) / abs(target))
# }




