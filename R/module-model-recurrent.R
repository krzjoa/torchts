#' A recurrent neural network model
#'
#' TODO: get rid off fwd_input_size etc.? Compare with other applications
#'
#' @param forward_layer (nn_module_generator or nn_module) A module with forward recurrent layer. Default: `nn_gru`
#' @param backward_layer (nn_module) A module with backward recurrent layer. Default: `NULL`
#' @param fwd_input_size (numeric) Input size for the forward recurrent layer
#' @param fwd_output_size (numeric) Forward layer size (in other words: the forward layer output size)
#' @param bwd_input_size (numeric) Input size for the backward recurrent layer
#' @param bwd_output_size (numeric) Backward layer size (in other words: the forward layer output size)
#' @param output_size (numeric) Output size of the whole neural network. Default: 1
#' @param final_activation The final activation function
#' @param num_embeddings Dictionary sizes for the particular features
#' @param embedding_dim
#'
#' Starting from the simpliest example
#'
#' @examples
#'
#' @export
model_recurrent <- nn_module(

  "model_recurrent",

  initialize = function(layer = nn_gru,
                        input_size, hidden_size,
                        h, num_layers = 1, dropout = 0,
                        output_activation = nn_linear(hidden_size, 1)){

    self$num_layers <- num_layers

    self$rnn <-
      layer(
        input_size  = input_size,
        hidden_size = hidden_size,
        num_layers  = num_layers,
        dropout     = dropout,
        batch_first = TRUE
      )

    self$output <- output_activation

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


#' model_recurrent <- nn_module(
#'   "model_recurrent",
#'   initialize = function(forward_layer = nn_gru,
#'                         backward_layer = NULL, fwd_numeric_input,
#'                         fwd_input_size = NULL, fwd_output_size = NULL,
#'                         bwd_input_size = NULL, bwd_output_size = NULL,
#'                         output_size = 1, final_activation = nn_linear(),
#'                         num_embeddings = NULL, embedding_dim = NULL){
#'
#'     self$embedding <- nn_multi_embedding(num_embeddings, embedding_dim)
#'
#'     n_features <- fwd_numeric_input + sum(embedding_dim)
#'     # print(n_features)
#'
#'     if (is_nn_module(forward_layer))
#'       self$forward_recurrent <- forward_layer
#'     else
#'       self$forward_recurrent <- forward_layer(n_features, fwd_output_size)
#'
#'     if (is_nn_module(backward_layer))
#'       self$backward_recurrent <- backward_layer
#'     else if (!is.null(backward_layer))
#'       self$backward_recurrent <- backward_layer(fwd_input_size, fwd_output_size)
#'
#'     #' Compute output size from both layers
#'     recurrent_output_size <-
#'       c(rnn_output_size(self$forward_recurrent),
#'         rnn_output_size(self$backward_recurrent))
#'
#'     self$linear           <- nn_linear(recurrent_output_size, output_size)
#'     self$final_activation <- final_activation
#'   },
#'
#'   forward = function(input_cat, input_rest){
#'     X_tensor_cat_processed <- self$embedding(input_cat)
#'     X_transformed <- torch_cat(
#'       list(input_rest, X_tensor_cat_processed), dim = -1
#'     )
#'     out <- self$forward_recurrent(X_transformed)
#'     self$final_activation(self$linear(nnf_relu(out[[1]])))
#'   }
#' )
