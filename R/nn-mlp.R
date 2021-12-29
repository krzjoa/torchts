#' A shortcut to create a feed-forward block (MLP block)
#'
#' @param ... (`nn_module`, `function` `integer`, `character`)
#'             An arbitrary number of arguments, than can be:
#'            * `nn_module` - e.g. [`torch::nn_relu()`]
#'            * `function`  - e.g. [`torch::nnf_relu`]
#'            * `character` - e.g. `selu`, which is converted to `nnf_selu`
#'            * `integer`   -
#'
#' @param activation Used if only integers are specified. By default: `nnf_relu`
#'
#' @examples
#' nn_mlp(10, 1)
#' nn_mlp(30, 10, 1)
#'
#' # Simple forward pass
#' net <- nn_mlp(4, 2, 1)
#' x <- as_tensor(iris[, 1:4])
#' net(x)
#'
#' # Simple forward pass with identity function
#' net <- nn_mlp(4, 2, 1, activation = function (x) x)
#' x <- as_tensor(iris[, 1:4])
#' net(x)
#'
#' @export
nn_mlp <- torch::nn_module(

  # debugonce(net)

  "nn_mlp",

  initialize = function(..., activation = nnf_relu){
      layers <- list(...)

      if (!at_least_two_integers(layers))
        stop("Specified layers must contain at least two integer numerics,
              which describes at least one leayer (input and output)")

      # Check, if any activation was specified
      if (length(int_elements(layers)) < length(layers))
        activation <- NULL

      # browser()

      int_indices <- which(
        sapply(layers, is_int)
      )

      int_table <-
        data.frame(
          .curr = int_indices,
          .next = dplyr::lead(int_indices)
        )

      layer_names <- NULL

      for (i in seq_along(layers)) {

        layer <- layers[[i]]

        if (is_int(layer)) {
          if (!.is_last(i, int_table)) {
            layer <- nn_linear(layer, .next_int(i, layers, int_table))
          } else {
            next
          }
        } else if (is.character(layer)) {
          layer <- get(glue::glue("nnf_{layer}"),
                       envir = rlang::pkg_env("torch"))
        }

        layer_name <- glue::glue("layer_{i}")

        self[[layer_name]] <- layer

        layer_names <- c(layer_names, layer_name)

        if (!is.null(activation)) {
          activation_layer_name <- glue::glue("layer_{i}_activation")
          self[[activation_layer_name]] <- activation #clone_if_module(activation)
          layer_names <- c(layer_names, activation_layer_name)
        }


      }

      self$layer_names <- layer_names

  },

  forward = function(x){
    output <- x
    for (ln in self$layer_names) {
      # print(output)
      output <- self[[ln]](output)
    }
    output
  }

)

is_int <- function(x){
  if (is.numeric(x))
    if (x %% 1 == 0)
      return(TRUE)
  FALSE
}

.next_int <- function(i, lst, idx_table){
  idx <- idx_table[idx_table$.curr == i, ]$.next
  lst[[idx]]
}

.is_last <- function(i, idx_table){
  output <- is.na(idx_table[idx_table$.curr == i, ]$.next)
  if (length(output) == 0)
    return(FALSE)
  else
    return(output)
}

#'
#' @examples
#' at_least_two_integers(list(2, 'char'))
#' at_least_two_integers(list(2, 'char', 3))
at_least_two_integers <- function(l){
  length(int_elements(l)) >= 2
}

int_elements <- function(l){
  Filter(is_int, l)
}

clone_if_module <- function(object){
  if (inherits(object, 'nn_module'))
    return(object$clone())
  else
    object
}

