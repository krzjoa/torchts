#' A configurable feed forward network (Multi-Layer Perceptron)
#' with embedding
#'
#' @importFrom torch torch_cat
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
#' .init_layer_spec <-
#'    init_layer_spec(
#'      num_embeddings = n_unique_values,
#'      embedding_dim  = embedding_size_google(n_unique_values),
#'      numeric_in     = 4,
#'      numeric_out    = 2
#'    )
#'
#' net <- model_mlp(.init_layer_spec, 2, 1)
#'
#' net(x_num, x_cat)
#'
#' @export
model_mlp <- torch::nn_module(

  "model_mlp",

  initialize = function(..., horizon, output_size, embedding = NULL,
                        activation = nnf_relu){

    layers <- list(...)

    self$horizon     <- horizon
    self$output_size <- output_size

    # If first element is a list, it describes embedding + numerical features
    if (is.list(layers[[1]])) {

        first_layer <- layers[[1]]

        self$multiembedding <-
          nn_multi_embedding(
            num_embeddings = first_layer$num_embeddings,
            embedding_dim  = first_layer$embedding_dim
          )

        self$initial_layer <-
          nn_nonlinear(
            first_layer$numeric_in,
            first_layer$numeric_out
          )

      first_layer_output <-
        first_layer$numeric_out +
        sum(first_layer$embedding_dim)

      layers <- c(
        list(first_layer_output), layers[-1]
      )

    }

    self$mlp <- do.call(
      nn_mlp, c(layers, list(activation = activation))
    )

  },

  forward = function(x_num = NULL, x_cat = NULL, x_fut_num = NULL, x_fut_cat = NULL){

    if (!is.null(x_cat) & !is.null(x_fut_cat))
      x_cat <- torch_cat(list(x_cat, x_fut_cat))

    if (!is.null(x_num) & !is.null(x_fut_num))
      x_num <- torch_cat(list(x_num, x_fut_num))

    # Pass trough initial layer
    if (!is.null(x_cat)) {

      output <-
        torch_cat(list(
            self$multiembedding(x_cat),
            self$initial_layer(x_num)
        ), dim = -1)
    } else {
      output <- x_num
    }

    # Transform batch_size x (timesteps *  features)
    current_shape <- dim(output)

    # output <- output$reshape(c(
    #   current_shape[1], current_shape[2] * current_shape[3]
    # ))

    output <- self$mlp(output)

    # Reshape output
    # output <- output$reshape(c(
    #   current_shape[1], self$horizon, self$output_size
    # ))

    output
  }

)

init_layer_spec <- function(num_embeddings,
                            embedding_dim,
                            numeric_in,
                            numeric_out){
  list(
    num_embeddings = num_embeddings,
    embedding_dim  = embedding_dim,
    numeric_in     = numeric_in,
    numeric_out    = numeric_out
  )
}



