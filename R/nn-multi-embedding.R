#' Create multiple embeddings at once
#'
#' @description It is especially useful, for dealing with multiple
#' categorical features.
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
#' @details
#'
#' @importFrom torch nn_module
#' @importFrom glue glue
#'
#' @export
nn_multi_embedding <- nn_module(
  "nn_multi_embedding",

  initialize = function(num_embeddings, embedding_dim){
    self$num_embeddings <- num_embeddings
    self$embedding_dim  <- embedding_dim

    for (idx in seq_along(self$num_embeddings)){

      self[[glue("embedding_{idx}")]] <-
        nn_embedding(
          num_embeddings     = self$num_embeddings[[idx]],
          embedding_dim      = self$embedding_dim[[idx]]#,
          # padding_idx        = self$padding_idx[[idx]],
          # max_norm           = self$max_norm[[idx]],
          # norm_type          = self$norm_type[[idx]],
          # scale_grad_by_freq = self$scale_grad_by_freq[[idx]],
          # sparse             = self$sparse[[idx]],
          # .weight            = self$.weight[[idx]]
        )
    }

  },

  forward = function(input){
    embedded_features <- list()

    for (idx in seq_along(self$num_embeddings)) {
      embedded_features[[glue("embedding_{idx}")]] <-
        self[[glue("embedding_{idx}")]](input[.., idx])
    }

    torch_cat(embedded_features, dim = -1)
  }
)

# idx <- 1
# mdl <- self[[glue("embedding_{idx}")]]
# tns <- input[.., idx]
#
# input[.., 6] %>%
#   as_array() %>%
#   as.vector() %>%
#   unique()
#
# mdl$forward(tns)
#
# tns2 <- torch_tensor(rbind(c(1,2,4,5),c(4,3,2,4)), dtype = torch_long())
#
# mdl$forward(tns2)
#
# embedding <- nn_embedding(7, 2)
# embedding(tns2)
#
# mdl$weight



