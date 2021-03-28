#' Parse time series formula
#'
#' @examples
#' parsed   <- torchts_parse_formula(value ~ . + backward(cat(snap_CA)) + backward(sell_price) + categ(wday), experiment_data)
#' parsed_2 <- torchts_parse_formula(value ~ . + backward(cat(snap_CA, wday)) + backward(sell_price) + categ(wday), experiment_data)
#' View(parsed_2)
torchts_parse_formula <- function(formula, data){
  formula_terms <- terms(formula, data = data)

  lhs <- as.character(rlang::f_lhs(formula))

  # Working on characters
  all_variables <-
    attr(formula_terms, "variables")

  rhs <-
    Filter(function(x){!(as.character(x) %in% lhs)}, as.list(all_variables)) %>%
    Filter(function(x)!is.null(x), .)

  # Removing "list" from call
  rhs <- rhs[-1]

  parsed_rhs <-
    purrr::map_dfr(rhs, .recursive_parse)

  parsed_lhs <-tibble(
    .var  = lhs,
    .type = list("outcome")
  )

  bind_rows(
    parsed_lhs,
    parsed_rhs
  )
}

.recursive_parse <- function(object, .type = NULL){
  if (typeof(object) == 'symbol') {
    if (is.null(.type))
      .type <- "default"
     out <- tibble(
       .var  = as.character(object),
       .type = list(.type)
     )
  } else if (typeof(object) == "language") {
    .type  <- c(.type, rlang::call_name(object))
    object <- rlang::call_args(object)
    out    <- purrr::map_dfr(object, ~ .recursive_parse(.x, .type))
  }
  out
}
