# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                           set_device
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#' Set model device.
#'
#' @param object An neural network object.
#' @param device (`character`) Selected device.
#'
#' @return Object of the same class with device set.
#'
#' @examples
#' rnn_net <-
#'   model_rnn(
#'     input_size  = 1,
#'     output_size = 1,
#'     hidden_size = 10
#'   ) %>%
#'  set_device("cpu")
#'
#' rnn_net
#'
#' @export
set_device <- function(object, device, ...){
  UseMethod("set_device")
}

#' @export
set_device.default <- function(object, device, ...){
  stop(sprintf(
    "Object of class %s has no devices defined!", class(object)
  ))
}

#' @export
set_device.torchts_model <- function(object, device, ...){
  set_device(object$net, device)
}

#' @export
set_device.nn_module <- function(object, device, ...){
  AVAILABLE_DEVICES <- c("cuda", "cpu")

  if (!(device %in% AVAILABLE_DEVICES))
    stop(sprintf(
      "You cannot select %s device.
       Choose 'cpu' or 'cuda' instead.",
      device
    ))

  if (device == "cpu")
    return(object$cpu())

  if (device == "cuda")
    return(object$cuda())

}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                         show_devices
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



