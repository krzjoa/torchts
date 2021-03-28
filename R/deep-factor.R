#' Deep Factor Model with RNN model
#'
#' @description
#' Deep Factor with RNN models is an instance of
#'
#' @param freq Time Series frequency
#' @param h Forecast horizon
#' @param num_hidden_global Number of units per hidden layer for the global RNN model (default: 50).
#' @param num_layers_global Number of hidden layers for the global RNN model (default: 1)
#' @param num_factors Number of global factors (default: 10).
#' @param num_hidden_local Number of units per hidden layer for the local RNN model (default: 5).
#' @param num_layers_local Number of hidden layers for the global local model (default: 1).
#' @param cell_type Type of recurrent cells to use (available: ‘lstm’ or ‘gru’; default: ‘lstm’).
#' @param optim A `torch` optimizer (default: torch::optim_adam)
#' @param context_length Training length (default: context_length = h)
#' @param num_parallel_samples Number of evaluation samples per time series to increase parallelism during inference.
#' This is a model optimization that does not affect the accuracy (default: 100).
#' @param cardinality List consisting of the number of time series (default: list([1]).
#' @param embedding_dimension Dimension of the embeddings for categorical features (the same dimension is used for all embeddings, default: 10).
#' @param distr_output Distribution to use to evaluate observations and sample predictions (default: StudentTOutput()).
#'
#' @note
#' [Deep Factors for Forecasting](https://arxiv.org/abs/1905.12417) by Wang Y. et al.
deep_factor_rnn <- function(freq, h, num_hidden_global = 50, num_layers_global = 1,
                        num_factors = 10, num_hidden_local = 5, num_layers_local = 1,
                        cell_type = c('lstm', 'gru'), optim = torch::optim_adam,
                        context_length = h, num_parallel_samples = 100,
                        cardinality, embedding_dimension = 10, distr_output){

}
