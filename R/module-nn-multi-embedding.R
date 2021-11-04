#' Create multiple embeddings at once
#'
#' @description It is especially useful, for dealing with multiple categorical features.
#'
#' @param num_embeddings (`integer`): size of the dictionary of embeddings
#' @param embedding_dim	(`integer`): the size of each embedding vector
#' @param padding_idx (`integer`, optional): If given, pads the output with
#' the embedding vector at padding_idx (initialized to zeros) whenever it encounters the index.
#' @param max_norm (`numeric`, optional): If given, each embedding vector with norm larger
#' than max_norm is renormalized to have norm max_norm.
#' @param norm_type (`numeric`, optional): The p of the p-norm to compute for the max_norm option. Default 2.
#' @param scale_grad_by_freq (`logical`, optional): If given, this will scale gradients by
#' the inverse of frequency of the words in the mini-batch. Default FALSE
#' @param sparse (`logical`, optional): If True, gradient w.r.t. weight matrix will be a sparse tensor.
#' @param .weight (`torch_tensor` or `list` of `torch_tensor`) embeddings weights (in case you want to set it manually)
#'
#' @importFrom torch nn_module
#' @importFrom glue glue
#'
#' @examples
#' data("gss_cat", package = "forcats")
#'
#' gss_cat_transformed <-
#'   gss_cat %>%
#'   na.omit() %>%
#'   sapply(function(x) cat2idx(x)[[1]]) %>%
#'   as_tibble()
#'
#' gss_cat_tensor  <- as_tensor(gss_cat_transformed)
#' .dict_size      <- dict_size(gss_cat_transformed)
#' .embedding_size <- ceiling(.dict_size ** .25)
#'
#' embedding_module <-
#'   nn_multi_embedding(.dict_size, .embedding_size)
#'
#' # Expected output size
#' sum(.embedding_size)
#'
#' embedding_module(gss_cat_tensor)
#'
#' @export
nn_multi_embedding <- nn_module(

  #' See:
  #' "Optimal number of embeddings"
  #' See: https://developers.googleblog.com/2017/11/introducing-tensorflow-feature-columns.html

  "nn_multi_embedding",

  initialize = function(num_embeddings = 'auto', embedding_dim = 'auto',
                        padding_idx = NULL, max_norm = NULL, norm_type = 2,
                        scale_grad_by_freq = FALSE, sparse = FALSE,
                        .weight = NULL){

    # Check arguments
    if (length(num_embeddings) != length(embedding_dim) &
        !(length(num_embeddings) == 1 | length(embedding_dim) == 1)) {
      torch:::value_error("Values has not equal lengths")
    }

    if (length(num_embeddings) > 1 & length(embedding_dim) == 1)
      embedding_dim <- rep(embedding_dim, length(num_embeddings))

    if (length(embedding_dim) > 1 & length(num_embeddings) == 1)
      num_embeddings <- rep(num_embeddings, length(embedding_dim))

    required_len <- max(length(embedding_dim), length(num_embeddings))

    padding_idx         <- rep_if_one_element(padding_idx, required_len)
    max_norm            <- rep_if_one_element(max_norm, required_len)
    norm_type           <- rep_if_one_element(norm_type, required_len)
    scale_grad_by_freq  <- rep_if_one_element(scale_grad_by_freq, required_len)
    sparse              <- rep_if_one_element(sparse, required_len)

    if (length(.weight) == 1)
      .weight <- rep(list(.weight), required_len)

    for (idx in seq_along(self$num_embeddings)){

      self[[glue("embedding_{idx}")]] <-
        nn_embedding(
          num_embeddings     = num_embeddings[[idx]],
          embedding_dim      = embedding_dim[[idx]],
          padding_idx        = padding_idx[[idx]],
          max_norm           = max_norm[[idx]],
          norm_type          = norm_type[[idx]],
          scale_grad_by_freq = scale_grad_by_freq[[idx]],
          sparse             = sparse[[idx]],
          .weight            = .weight[[idx]]
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
