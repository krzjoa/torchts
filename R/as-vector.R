#' Convert `torch_tensor` to a vector
#'
#' @export
as.vector.torch_tensor <- function(x, mode = 'any'){
  as.vector(as.array(x), mode = mode)
}
