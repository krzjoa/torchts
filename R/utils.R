#' Repeat element if it length == 1
rep_if_one_element <- function(x, output_length){
  if (length(x) == 1)
    return(rep(x), output_length)
  else
    return(x)
}

#' Convert `torch_tensor` to a vector
#' @export
as.vector.torch_tensor <- function(x, mode = 'any'){
  as.vector(as.array(x), mode = mode)
}
