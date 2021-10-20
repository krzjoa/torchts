#' A configurable recurrent neural network model
#'
#' @description
#' New features will be added in near future, e.g. categorical feature handling and so on.
#'
#' @param rnn_layer (`nn_rnn_base`) A recurrent `torch` layer.
#' @param input_size (`integer`) Input size.
#' @param output_size (`integer`) Output size (number of target variables).
#' @param hidden_size (`integer`) A size of recurrent hidden layer.
#' @param horizon (`integer`) Horizon size. How many steps ahead produce from the last n steps?
#' @param final_module (`nn_module`) If not null, applied instead of default linear layer.
#' @param dropout (`logical`) Use dropout.
#' @param batch_first (`logical`) Channel order.
#'
#' @importFrom torch nn_gru nn_linear
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' library(torch)
#' library(torchts)
#'
#' # Preparing data
#' weather_dl <-
#'   weather_pl %>%
#'   filter(station == "TRN") %>%
#'   select(date, tmax_daily) %>%
#'   as_ts_dataloader(
#'     tmax_daily ~ date,
#'     timesteps = 30,
#'     batch_size = 32
#'   )
#'
#' # Creating a model
#' rnn_net <-
#'   model_rnn(
#'     input_size  = 1,
#'     output_size = 1,
#'     hidden_size = 10
#'   )
#'
#' print(rnn_net)
#'
#' # Prediction example on non-trained neural network
#' batch <-
#'   dataloader_next(dataloader_make_iter(weather_dl))
#'
#' rnn_net(batch$x)
#'
#' @export
model_rnn <- torch::nn_module(

  "model_rnn",

  initialize = function(rnn_layer = nn_gru,
                        input_size, output_size,
                        hidden_size, horizon = 1,
                        final_module = nn_linear(hidden_size, output_size * horizon),
                        dropout = 0, batch_first = TRUE){

    self$horizon <- horizon

    self$rnn <-
      rnn_layer(
        input_size  = input_size,
        hidden_size = hidden_size,
        num_layers  = 1,
        dropout     = dropout,
        batch_first = batch_first
      )

    self$final_module <- final_module
    self$hidden_state <- NULL

  },

  forward = function(x) {

    # list of [output, hidden]
    # we use the output, which is of size (batch_size, timesteps, hidden_size)
    x1 <- self$rnn(x)
    x <- x1[[1]]
    self$hidden_state <- x1[[2]]

    # Final timestep with size (batch_size, hidden_size)
    x <- x[ , dim(x)[2], ]

    # feed this to a single output neuron
    # final shape then is (batch_size, 1)
    self$final_module(x)[,newaxis,]
  }
)
