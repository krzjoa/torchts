#' Geometric pyramid rule
#'
#' @description A simple heuristics to choose hidden layer size
#'
#' @param input_size (`integer`) Input size
#' @param next_layer_size (`integer`) Next layer size
#'
#' @references
#' [Practical Neural Network Recipes in C++](https://books.google.de/books/about/Practical_Neural_Network_Recipes_in_C++.html?id=7Ez_Pq0sp2EC&redir_esc=y)
#'
geometric_pyramid <- function(input_size, next_layer_size){
  ceiling(sqrt(input_size * next_layer_size))
}
