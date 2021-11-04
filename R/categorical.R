#' Check, if vector is categorical, i.e. 
#' if is logical, factor, character or integer
#' 
#' @param x A vector of arbitrary type
#' 
#' @return Logical value
#' 
#' @examples 
#' is_categorical(c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE))
#' is_categorical(1:10)
#' is_categorical((1:10) + 0.1)
#' is_categorical(as.factor(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg")))
#' is_categorical(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg"))
#' 
#' @export
is_categorical <- function(x){
  is.logical(x)   |
  is.factor(x)    |
  is.character(x) |
  is.integer(x)
}
