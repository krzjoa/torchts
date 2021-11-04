# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                           set_device
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
  object$net
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                         show_devices
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



