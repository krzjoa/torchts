# Metrics

#' Mean Absolute Percentage Error
#'
#' @param input tensor (N,*) where ** means, any number of additional dimensions
#' @param target tensor (N,*) , same shape as the input
#'
#' @details
#'
#' Computed according to the formula:
#' \deqn{MAPE = \frac{1}{n}\displaystyle\sum_{t=1}^{n} \abs{\frac{target - input}{target}}}
#'
#' @seealso
#' \code{\link[yardstick]{mape}}
#'
#' @export
nnf_mape <- function(input, target){
  mean(abs((target - input) / target))
}

#' Mean Absolute Scaled Error
#'
#' @param input tensor (N,*) where ** means, any number of additional dimensions
#' @param target tensor (N,*) , same shape as the input
#'
#' @details
#'
#' Computed according to the formula:
#' \deqn{MAE = \frac{1}{n}\displaystyle\sum_{t=1}^{n}\abs{target - input}}
#'
#' @seealso
#' \code{\link[yardstick]{mae}}
#'
#' @export
nnf_mae <- function(input, target){
  mean(abs(target - input))
}


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




