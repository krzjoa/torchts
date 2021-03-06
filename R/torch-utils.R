#' RNN output size
#' @param module (nn_module) A torch `nn_module`
#' @examples
#' gru_layer <- nn_gru(15, 3)
#' rnn_output_size(gru_layer)
#' @export
rnn_output_size <- function(module){
  tail(dim(module$weight_hh_l1), 1)
}

#' An auxilliary function to call optimizer
call_optim <- function(optim, params){
  if (!is_quosure(optim))
    quosure <- rlang::enquo(optim)
  else
    quosure <- optim
  fun     <- rlang::call_fn(quosure)
  args <- c(
    list(params = params),
    rlang::call_args(quosure)
  )
  do.call({fun}, args)
}
