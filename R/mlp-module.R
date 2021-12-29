#' A configurable feed forward network (Multi-Layer Perceptron)
#' with embedding
#'
#' @examples
#' net <- model_mlp(4, 2, 1)
#' x <- as_tensor(iris[, 1:4])
#' net(x)
#'
#' # With categorical features
#' library(recipes)
#' iris_prep <-
#'    recipe(iris) %>%
#'    step_integer(Species) %>%
#'    prep() %>%
#'    juice()
#'
#' iris_prep <- mutate(iris_prep, Species = as.integer(Species))
#'
#' x_num <- as_tensor(iris_prep[, 1:4])
#' x_cat <- as_tensor(dplyr::select(iris_prep, 5))
#'
#' n_unique_values <- dict_size(iris_prep)
#'
#' .embedding_spec <-
#'    embedding_spec(
#'      num_embeddings = n_unique_values,
#'      embedding_dim  = embedding_size_google(n_unique_values)
#'    )
#'
#' net <- model_mlp(list(embedding = .embedding_spec, 4), 2, 1)
#'
#' @export
model_mlp <- torch::nn_module(

  "model_mlp",

  initialize = function(..., embedding = NULL,
                        activation = nnf_relu){

    layers <- list(...)

    # If first element is a list, it describes embedding + numerical features
    if (is.list(layers[[1]])) {

        first_layer <- layers[[1]]
        # embedding_idx <- which(names(first_layer) == 'embedding')

        embedding <- first_layer$embedding

        self$multiembedding <-
          nn_multi_embedding(
            num_embeddings = embedding$num_embeddings,
            embedding_dim  = embedding$embedding_dim
          )

        self$initial_layer <-
          nn_nonlinear(
            first_layer[[2]],
            layers[[2]]
          )

      first_layer_output <-
        length(initial_layer$bias) + sum(embedding$embedding_dim)

      layers <- c(
        list(first_layer_output), layers[[-1]]
      )

    }

    self$mlp <- do.call(
      nn_mlp, c(layers, list(activation = activation))
    )

  },

  forward = function(x_num, x_cat){

    # Pass trough initial layer
    if (!is.null(x_cat)) {
      output <-
        torch_cat(
          self$multiembedding(x_cat),
          self$initial_layer(x_num)
        )
    }

    self$mlp(output)

  }

)



