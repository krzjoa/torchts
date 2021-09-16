#' A recurrent neural network model
#'
#' @param layer A recurrent `torch` layer
#' @param input_size (integer) Input size
#' @param hidden_size (integer) Hidden layer size
#' @param h (integer) Horizon size
#' @param dropout (logical) Use dropout
#'
#'
#' @export
model_rnn <- torch::nn_module(

  "model_rnn",

  initialize = function(layer = nn_gru,
                        input_size, hidden_size,
                        h, dropout = 0){

    # self$num_layers <- num_layers

    self$rnn <-
      layer(
        input_size  = input_size,
        hidden_size = hidden_size,
        num_layers  = 1,
        dropout     = dropout,
        batch_first = TRUE
      )

    self$output <- nn_linear(hidden_size, 1)

  },

  forward = function(x) {

    # list of [output, hidden]
    # we use the output, which is of size (batch_size, n_timesteps, hidden_size)
    x <- self$rnn(x)[[1]]

    # from the output, we only want the final timestep
    # shape now is (batch_size, hidden_size)
    x <- x[ , dim(x)[2], ]

    # feed this to a single output neuron
    # final shape then is (batch_size, 1)
    self$output(x)
  }
)
