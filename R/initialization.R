#' Initialize gates to pass full information
#'
#' x <- list(rnn_layer = nn_lstm(2, 20))
#' init_gate_bias(x$rnn_layer)
#' x$rnn_layer$parameters$bias_ih_l1
#'
init_gate_bias <- function(rnn_layer){
  # rnn_layer <- nn_lstm(2, 20)

  # https://stackoverflow.com/questions/62198351/why-doesnt-pytorch-allow-inplace-operations-on-leaf-variables
  # https://danijar.com/tips-for-training-recurrent-neural-networks/

  # Forget gate bias.
  # It can take a while for a recurrent network to learn to remember information form the last time step.
  # Initialize biases for LSTM’s forget gate to 1 to remember more by default.
  # Similarly, initialize biases for GRU’s reset gate to -1.

  if (inherits(rnn_layer, 'nn_gru')) {

    # Initialize reset gate with -1

    segment_len <- dim(rnn_layer$parameters$bias_hh_l1) / 4
    indices <- (segment_len+1):(2*segment_len)

    # First part is reset gate
    # ~GRU.bias_ih_l[k] (b_ir|b_iz|b_in), of shape (3*hidden_size)
    #
    # ~GRU.bias_hh_l[k]  (b_hr|b_hz|b_hn), of shape (3*hidden_size)

    # Jeśli jest leaf, to nie można robić inplace
    rnn_layer$parameters$bias_hh_l1$requires_grad_(FALSE)
    rnn_layer$.__enclos_env__$private$parameters_$bias_hh_l1[indices] <- -1
    rnn_layer$parameters$bias_hh_l1$requires_grad_(TRUE)

    rnn_layer$parameters$bias_ih_l1$requires_grad_(FALSE)
    rnn_layer$.__enclos_env__$private$parameters_$bias_ih_l1[indices] <- -1
    rnn_layer$parameters$bias_ih_l1$requires_grad_(TRUE)
  }

  if (inherits(rnn_layer, 'nn_lstm')) {
    #' ~LSTM.bias_ih_l[k] – (b_ii|b_if|b_ig|b_io), of shape (4*hidden_size)
    #' ~LSTM.bias_hh_l[k] – (b_hi|b_hf|b_hg|b_ho), of shape (4*hidden_size)
    #'

    segment_len <- dim(rnn_layer$parameters$bias_ih_l1) / 4
    indices <- (segment_len+1):(2*segment_len)

    # Jeśli jest leaf, to nie można robić inplace
    rnn_layer$parameters$bias_hh_l1$requires_grad_(FALSE)
    rnn_layer$.__enclos_env__$private$parameters_$bias_hh_l1[indices] <- 1
    rnn_layer$parameters$bias_hh_l1$requires_grad_(TRUE)

    rnn_layer$parameters$bias_ih_l1$requires_grad_(FALSE)
    rnn_layer$.__enclos_env__$private$parameters_$bias_ih_l1[indices] <- 1
    rnn_layer$parameters$bias_ih_l1$requires_grad_(TRUE)

  }

  invisible()
}



