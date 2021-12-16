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
#' @param embedding (`embedding_spec`) List with two values: num_embeddings and embedding_dim.
#' @param initial_layer (`nn_module`) A `torch` module to preprocess numeric features before the recurrent layer.
#' @param final_layer (`nn_module`) If not null, applied instead of default linear layer.
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
#' weather_data <-
#'   weather_pl %>%
#'   filter(station == "TRN") %>%
#'   select(date, tmax_daily, rr_type) %>%
#'   mutate(rr_type = ifelse(is.na(rr_type), "NA", rr_type))
#'
#' weather_dl <-
#'   weather_data %>%
#'   as_ts_dataloader(
#'     tmax_daily ~ date + tmax_daily + rr_type,
#'     timesteps = 30,
#'     categorical = "rr_type",
#'     batch_size = 32
#'   )
#'
#' unique(weather_data$rr_type)
#' n_unique_values <- n_distinct(weather_data$rr_type)
#'
#' .embedding_spec <-
#'    embedding_spec(
#'      num_embeddings = n_unique_values,
#'      embedding_dim  = embedding_size_google(n_unique_values)
#'    )
#'
#' input_size <- 1 + embedding_size_google(n_unique_values) # tmax_daily + rr_type embedding
#'
#' # Creating a model
#' rnn_net <-
#'   model_rnn(
#'     input_size  = input_size,
#'     output_size = 2,
#'     hidden_size = 10,
#'     horizon     = 10,
#'     embedding   = .embedding_spec
#'   )
#'
#' print(rnn_net)
#'
#' # Prediction example on non-trained neural network
#' batch <-
#'   dataloader_next(dataloader_make_iter(weather_dl))
#'
#' # debugonce(rnn_net$forward)
#' rnn_net(batch$x_num, batch$x_cat)
#'
#' @export
model_rnn <- torch::nn_module(

  "model_rnn",

  initialize = function(rnn_layer = nn_gru,
                        input_size, output_size,
                        hidden_size, horizon = 1,
                        embedding = NULL,
                        initial_layer = nn_nonlinear,
                        last_timesteps = 1,
                        final_layer = nn_linear,
                        dropout = 0, batch_first = TRUE){

    # TODO: Should rnn_input_size include categoricals (pereferably, yes)
    # TODO: simplify API -

    # browser()

    self$horizon        <- horizon
    self$output_size    <- output_size
    self$last_timesteps <- last_timesteps

    if (!is.null(embedding))
      self$multiembedding <-
        nn_multi_embedding(
          num_embeddings = embedding$num_embeddings,
          embedding_dim  = embedding$embedding_dim
        )
    else
      self$multiembedding <- NULL

    # Initial layer
    if (inherits(initial_layer, "nn_module_generator")) {
      input_size       <- input_size - length(embedding$num_embeddings)
      init_output_size <- geometric_pyramid(input_size, hidden_size)
      self$initial_layer <- initial_layer(
        input_size, init_output_size
      )
      rnn_input_size <- init_output_size + sum(embedding$embedding_dim)
    } else if (inherits(initial_layer, "nn_module")) {
      self$initial_layer <- initial_layer
      # TODO: here we suppose it's a linear layer!!!!
      rnn_input_size <- length(initial_layer$bias) + sum(embedding$embedding_dim)
    } else if (is.null(initial_layer)) {
      rnn_input_size <- input_size
    } else
      stop("Wrong type of the final_layer argument!")

    # Add "preprocessing" dense layer
    # if (is.null(initial_layer)) {
    #   self$initial_layer <- initial_layer
    #   rnn_input_size <- length(x$bias) + sum(embedding$embedding_dim)
    # } else {
    #   rnn_input_size <- input_size
    # }

    self$rnn <-
      rnn_layer(
        input_size  = rnn_input_size,
        hidden_size = hidden_size,
        num_layers  = 1,
        dropout     = dropout,
        batch_first = batch_first
      )

    # Final layer
    if (inherits(final_layer, "nn_module_generator"))
      self$final_layer <- final_layer(hidden_size * last_timesteps, output_size * horizon)
    else if (inherits(final_layer, "nn_module"))
      self$final_layer <- final_layer
    else
      stop("Wrong type of the final_layer argument!")

    self$hx           <- NULL

    # Statefulness
    self$is_stateful  <- FALSE

  },

  forward = function(x_num, x_cat) {

    # Transforming categorical features using multiembedding
    if (!missing(x_cat)) {

      if (is.null(self$multiembedding)) {
        message("x_cat argument was passed, but embedding was not defined")
        x_cat_transformed <- NULL
      } else {
        x_cat_transformed <- self$multiembedding(x_cat)
      }

    } else {
      x_cat_transformed <- NULL
    }

    # list of [output, hidden]
    # we use the output, which is of size (batch_size, timesteps, hidden_size)
    # Error when x_num is cuda and x_cat_transformed is null
    if (is.null(x_cat_transformed))
      x <- x_num
    else
      x <- torch_cat(list(x_num, x_cat_transformed), dim = 3)

    if (self$is_stateful)
      hx <- self$hx
    else
      hx <- NULL

    if (!is.null(self$initial_layer))
      x <- self$initial_layer(x)

    x1 <- self$rnn(x, hx)

    x <- x1[[1]]

    # TODO: hx for lstm is probably a list (because it returns two hidden state tensors)
    self$hx <- x1[[2]]$clone()$detach()
    # self$hx$requires_grad_(FALSE)

    # Final timesteps with size (batch_size, hidden_size)
    last_timesteps <- seq(dim(x)[2] - self$last_timesteps + 1, dim(x)[2] )

    x <- x[ , last_timesteps, ]

    # feed this to a single output neuron
    # final shape then is (batch_size, 1)
    self$final_layer(x)$reshape(c(-1, self$horizon, self$output_size))
  },

  stateful = function(flag = TRUE){
    # https://discuss.pytorch.org/t/stateful-rnn-example/10912
    #
    self$is_stateful <- flag
  },

  reset_state = function(){
    self$hx <- NULL
  }

)


embedding_spec <- function(num_embeddings, embedding_dim){
  structure(
    class = "embedding_spec",
    list(
      num_embeddings = num_embeddings,
      embedding_dim  = embedding_dim
  ))
}

# make_embedding_spec <- function(data, embeddig_size_fun = embedding_size_google){
#
#   .dict_size <- dict_size(data)
#   .embedding_size <- embeddig_size_fun(.dict_size)
#
#   embedding_spec(
#     num_embeddings = .dict_size,
#     embedding_dim  = .embedding_size
#   )
# }


