#' Convert `torch_tensor` to a vector
#'
#' `as.vector.torch_tensor` attempts to coerce a `torch_tensor` into a vector of
#' mode `mode` (the default is to coerce to whichever vector mode is most convenient):
#' if the result is atomic all attributes are removed.
#'
#' @param x (`torch_tensor`) A `torch` tensor
#' @param mode (`character`) A character string with one of possible vector modes:
#'  "any", "list", "expression" or other basic types like "character", "integer" etc.
#'
#' @return
#' A vector of desired type.
#' All attributes are removed from the result if it is of an atomic mode,
#' but not in general for a list result.
#'
#' @seealso
#' [base::as.vector]
#'
#' @examples
#' library(torch)
#' library(torchts)
#'
#' x <- torch_tensor(array(10, dim = c(3, 3, 3)))
#' as.vector(x)
#' as.vector(x, mode = "logical)
#' as.vector(x, mode = "character")
#' as.vector(x, mode = "complex")
#' as.vector(x, mode = "list")
#'
#' @export
as.vector.torch_tensor <- function(x, mode = 'any'){
  # TODO: dim order, as_tibble, as.data.frame with dims order
  as.vector(as.array(x), mode = mode)
}
