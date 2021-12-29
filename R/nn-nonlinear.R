#' Shortcut to create linear layer with nonlinear activation function
#'
#' @param in_features (`integer`) size of each input sample
#' @param out_features (`integer`) size of each output sample
#' @param bias (`logical`) If set to `FALSE`, the layer will not learn an additive bias.
#'   Default: `TRUE`
#' @param activation (`nn_module`) A nonlinear activation function (default: [torch::nn_relu()])
#'
#' @examples
#' net <- nn_nonlinear(10, 1)
#' x   <- torch_tensor(matrix(1, nrow = 2, ncol = 10))
#' net(x)
#'
#' @export
nn_nonlinear <- torch::nn_module(

  "nn_nonlinear",

  initialize = function(in_features, out_features, bias = TRUE, activation = nn_relu()) {
    self$linear     <- nn_linear(in_features, out_features, bias = bias)
    self$activation <- activation
  },

  forward = function(input){
    self$activation(self$linear(input))
  }

)

