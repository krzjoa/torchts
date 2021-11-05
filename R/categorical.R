#' Check, if vector is categorical, i.e.
#' if is logical, factor, character or integer
#'
#' @param x A vector of arbitrary type
#'
#' @return Logical value
#'
#' @examples
#' is_categorical(c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE))
#' is_categorical(1:10)
#' is_categorical((1:10) + 0.1)
#' is_categorical(as.factor(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg")))
#' is_categorical(c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg"))
#'
#' @export
is_categorical <- function(x){
  is.logical(x)   |
  is.factor(x)    |
  is.character(x) |
  is.integer(x)
}


#' Return size of categorical variables in the data.frame
#'
#' @param data (`data.frame`) A data.frame containing categorical variables.
#' The function automatically finds categorical variables,
#' calling internally [is_categorical] function.
#'
#' @return Named logical vector
#'
#' @examples
#' glimpse(tiny_m5)
#' dict_size(tiny_m5)
#'
#' # We can choose only the features we want - otherwise it automatically
#' # selects logical, factor, character or integer vectors
#'
#' tiny_m5 %>%
#'   select(store_id, event_name_1) %>%
#'   dict_size()
#'
#' @export
dict_size <- function(data){
  cols <- sapply(data, is_categorical)
  sapply(as.data.frame(data)[cols], dplyr::n_distinct)
}

#' @name embedding_size
#' 
#' Propose the length of embedding vector for each embedded feature.
#' 
#' @param x (`integer`) A vector with dictionary size for each feature
#' @param 
#' 
#' @description 
#' These functions returns proposed embedding sizes for each categorical feature.
#' They are "rule of thumbs", so the are based on empirical rather than theoretical conclusions, 
#' and their parameters can look like "magic numbers". Nevertheless, when you don't know what embedding size
#' will be "optimal", it's good to start with such kind of general rules.
#' 
#' * **google**
#' Proposed on the [Google Developer](https://developers.googleblog.com/2017/11/introducing-tensorflow-feature-columns.html) site
#' \deqn{x^0.25}
#' 
#' * **fastai**
#'  \deqn{1.6 * x^0.56}
#' 
#' 
#' @return Proposed embedding sizes. 
#' 
#' @examples 
#' dict_sizes <- dict_size(tiny_m5)
#' embedding_size_google(dict_sizes)
#' embedding_size_fastai(dict_sizes)
#' 
#' @references 
#' 
#' * [Introducing TensorFlow Feature Columns](https://developers.googleblog.com/2017/11/introducing-tensorflow-feature-columns.html)
#' * [fastai - embedding size rule of thumb](https://github.com/fastai/fastai/blob/master/fastai/tabular/model.py)
#' 
#' 
NULL

#' @rdname embedding_size
#' @export
embedding_size_google <- function(x, max_size = 100){
  pmin(ceiling(x ** 0.25), max_size)
}

#' @rdname embedding_size
#' @export
embedding_size_fastai <- function(x, max_size = 100){
  pmin(round(1.6 * x ** 0.56), max_size)
}

