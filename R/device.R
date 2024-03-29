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

  if (is.null(object))
    return(object)

  stop(sprintf(
    "Object of class %s has no devices defined!", class(object)
  ))
}

#' @export
set_device.torchts_model <- function(object, device, ...){
  set_device(object$net, device)
}

#' @export
set_device.model_spec <- function(object, device, ...){
  object$eng_args$device <- device #rlang::enquo(device)
  object
}

#' @export
set_device.dataloader <- function(object, device, ...){
  object$dataset$device <- device
  object
}


#' @export
set_device.nn_module <- function(object, device, ...){
  .set_device(object, device, ...)
}


set_device.torch_tensor <- function(object, device, ...){
  .set_device(object, device, ...)
}

.set_device <- function(object, device, ...){
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

#' Show available devices
#' @examples
#' torchts_show_devices()
#' @export
torchts_show_devices <- function(){
  if (cuda_is_available())
    return(c("cpu", "cuda"))
  else
    return("cpu")
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                         default device
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#' Set a torch device, which is treated as default for torchts models
#' in the current R session
#' @param device Device name
#' @examples
#' torchts_set_default_device("cuda")
#' @export
torchts_set_default_device <- function(device){
  options(torchts_default_device = device)
}

#' Get a torch device, which is treated as default for torchts models
#' in the current R session
#' @param device Device name
#' @examples
#' torchts_get_default_device()
#' @export
torchts_get_default_device <- function(device){
  getOption(torchts_default_device, "cpu")
}


