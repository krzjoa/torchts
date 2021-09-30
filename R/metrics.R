# Metrics

#' Mean Absolute Percentage Error
#'
#' @param input tensor (N,*) where ** means, any number of additional dimensions
#' @param target tensor (N,*) , same shape as the input
#'
#' @export
nnf_mape <- function(input, target){
  abs(target - input) / abs(target)
}

#' Weighted Absolute Percentage Error
#'
#' Sometimes called WMAPE or wMAPE
#'
#'
#' @export
nnf_wape <- function(input, target, weight){
  abs(target - input) / abs(target)
}


