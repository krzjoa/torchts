#' A recurrent neural network model
#'
#' @param layer A recurrent `torch` layer
#' @param input_size (integer) Input size
#' @param output_size (integer) Output size (number of target variables)
#' @param hidden_size (integer) Hidden layer size
#' @param h (integer) Horizon size
#' @param dropout (logical) Use dropout
#' @param batch_first (logical) Channel order
#'
#' @importFrom torch nn_gru nn_linear
#'
#' @export
model_rnn <- torch::nn_module(

  "model_rnn",

  initialize = function(layer = nn_gru,
                        input_size, output_size,
                        hidden_size, h,
                        dropout = 0, batch_first = TRUE){

    self$rnn <-
      layer(
        input_size  = input_size,
        hidden_size = hidden_size,
        num_layers  = 1,
        dropout     = dropout,
        batch_first = batch_first
      )

    self$output <- nn_linear(hidden_size, output_size)
    self$hidden_state <- NULL

  },

  forward = function(x) {

    # list of [output, hidden]
    # we use the output, which is of size (batch_size, n_timesteps, hidden_size)
    x1 <- self$rnn(x)
    x <- x1[[1]]
    self$hidden_state <- x1[[2]]

    # Final timestep with size (batch_size, hidden_size)
    x <- x[ , dim(x)[2], ]

    # feed this to a single output neuron
    # final shape then is (batch_size, 1)
    self$output(x)[,newaxis,]
  }
)
