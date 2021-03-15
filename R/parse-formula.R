#' Parse time series formula
#'
#' @import formula.tools
#' # TODO: create own lhs.vars function
#'
#' @examples
#' library(formula.tools)
#' torchts_parse_formula(value ~ . + backward(tempeature))
torchts_parse_formula <- function(formula, data){
  predicted_variable   <- lhs.vars(formula)
  right_hand_variables <- as.list(rhs(formula))

  formula_terms <- terms(formula, data = data)
  right_s

  split_terms(right_hand_variables, recursive = TRUE)
}


