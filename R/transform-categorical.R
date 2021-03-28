#' Encode vector of categorical features
#'
#' @param x (character, factor or numeric) Vector of arbitrary length
#'
#' @return
#' A list containing two values:
#'
#' * transformed_x - vector of transformed categorical features
#' * dict - dictionary with category mapping
#'
#' @examples
#' data("gss_cat", package = "forcats")
#' encode_categorical(gss_cat$marital)
#'
#' @export
cat2idx <- function(x){

  # TODO: na_rm or something similar

  if (is.factor(x))
    unique_values <- levels(x)
  else
    unique_values <- sort(unique(x))

  dict <-
    tibble::tibble(
      .key   = unique_values,
      .value = seq_along(unique_values)
    )

  attr(dict, "original_type") <- class(x)

  class(dict) <-
    c("cat_dict", class(dict))

  transformed_x <-
    match(x, dict$.key)

  list(
    transformed_x = transformed_x,
    dict          = dict
  )

}

#' Invert `cat2idx` transformation
#'
#' @param x A vector with interger values from 1 to n
#' @param dict A dictionary with categorical variable mapping
#'
#' @examples
#' # Encode factor vector
#' data("gss_cat", package = "forcats")
#' output <- encode_categorical(gss_cat$marital)
#'
#' transformed_x <- output[[1]]
#' dict <- output[[2]]
#'
#' dict
#'
#' decode_categorical(transformed_x, dict)
#'
#' @export
idx2cat <- function(x, dict){
  inverted_x <- dict$.key[x]

  if (attr(dict, "original_type") == "factor")
    inverted_x <-
      factor(inverted_x, levels = dict$.key)

  inverted_x
}

# EXPERIMENTAL: invert recipes

#' Encode categorical variables as integer values from 1 to n (an index)
#'
#' @param recipe A recipe object. The step will be added to the
#'  sequence of operations for this recipe.
#' @param ... One or more selector functions to choose which
#'  variables are affected by the step. See [selections()]
#'  for more details. For the `tidy` method, these are not
#'  currently used.
#'
#' @keywords datagen
#' @concept preprocessing
#' @concept variable_encodings
#' @concept factors
#'
step_cat2idx<- function(recipe,
                        ...,
                        role = NA,
                        trained = FALSE,
                        columns = FALSE,
                        skip = FALSE,
                        id = rand_id("cat2int")){
  add_step(
    recipe,
    step_cat2idx_new(
      terms = ellipse_check(...),
      role = role,
      trained = trained,
      columns = columns,
      skip = skip,
      id = id
    )
  )
}

step_cat2idx_new <- function(terms, role, trained, columns, skip, id) {
  .step <-
    step(
      subclass = "cat2idx",
      terms = terms,
      role = role,
      trained = trained,
      columns = columns,
      skip = skip,
      id = id
    )

}


prep.cat2idx <- function(x, training, info = NULL, ...){
  col_names <- eval_select_recipes(x$terms, training, info)
}




