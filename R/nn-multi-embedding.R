
#' Create multiple embeddings at once
#'
#' @description It is especially useful, fo dealing with multiple
#' categorical features
#'
#' @param num_embeddings (int vector): size of the dictionary of embeddings
#' @param embedding_dim	(int): the size of each embedding vector
#' @param padding_idx (int, optional): If given, pads the output with
#' the embedding vector at padding_idx (initialized to zeros) whenever it encounters the index.
#' @param max_norm (float, optional): If given, each embedding vector with norm larger
#' than max_norm is renormalized to have norm max_norm.
#' @param norm_type (float, optional): The p of the p-norm to compute for the max_norm option. Default 2.
#' @param scale_grad_by_freq (boolean, optional): If given, this will scale gradients by
#' the inverse of frequency of the words in the mini-batch. Default FALSE
#' @param sparse (bool, optional): If True, gradient w.r.t. weight matrix will be a sparse tensor.
#' @param .weight (Tensor) embeddings weights (in case you want to set it manually)
#'
#' @export
nn_multi_embedding <- nn_module(
  "nn_multi_embedding",

  initialize = function(num_embeddings, embedding_dim){
    self$num_embeddings <- num_embeddings
    self$embedding_dim  <- embedding_dim

    for (n in 1:length(self$num_embeddings)){
      # n_embed   <- self$num_embeddings[[n]]
      # embed_dim <- self$embedding_dim[[n]]

      self[[glue("embedding_{n}")]] <-
        nn_embedding(
          num_embeddings     = self$num_embeddings[[n]],
          embedding_dim      = self$embedding_dim[[n]],
          padding_idx        = self$padding_idx[[n]],
          max_norm           = self$max_norm[[n]],
          norm_type          = self$norm_type[[n]],
          scale_grad_by_freq = self$scale_grad_by_freq[[n]],
          sparse             = self$sparse[[n]],
          .weight            = self$.weight[[n]]
        )
    }

  },

  forward = function(input){
    embedded_features <- list()

    torch_cat(embedded_features)
  }


)


?nn_embedding
