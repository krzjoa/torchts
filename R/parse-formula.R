#' Parse time series formula
#'
#' First version returns 3 types of variables:
#' * outcome
#' * predictor
#' * index
#'
#' If no predictor is defined, every outcome variable is treated as a predictor
#'
#' @examples
#' library(dplyr)
#' library(torchts)
#'
#' tarnow_temp <-
#'   weather_pl %>%
#'   filter(station == "TARNÓW") %>%
#'   select(date, max_temp = tmax_daily, min_temp = tmin_daily)
#'
#' View(torchts_parse_formula(max_temp ~ max_temp +index(date), tarnow_temp))
#' View(torchts_parse_formula(max_temp ~ date, tarnow_temp))
#'
#' debugonce(torchts_parse_formula)
#'
#' # This example is not working
#' View(torchts_parse_formula(max_temp + min_temp ~ max_temp + min_temp + index(date), tarnow_temp))
#' View(torchts_parse_formula(max_temp + min_temp ~ max_temp + index(date), tarnow_temp))
#' View(torchts_parse_formula(min_temp ~ max_temp + date, tarnow_temp))
torchts_parse_formula <- function(formula, data){

  #' TODO: simplify?

  date_types <- c("Date", "POSIXt", "POSIXlt", "POSIXct")

  formula_terms <- terms(formula, data = data)
  lhs <- as.character(rlang::f_lhs(formula))

  rhs_vars <-
    as.character(rlang::f_rhs(formula)) %>%
    .[. != "+"]

  variable_classes <-
    tibble(.var = colnames(data),
           .type = sapply(data, class))

  names(variable_classes$.type) <- NULL

  all_variables <-
    attr(formula_terms, "variables")

  filtered_variables <-
    Filter(function(x)!is.null(x), as.list(all_variables))

  selected_rhs <- match(rhs_vars, as.character(filtered_variables))
  selected_rhs <- selected_rhs[!is.na(selected_rhs)]

  rhs <- filtered_variables[selected_rhs]

  # Removing "list" from call
  if (length(lhs) > 1) {
    lhs <- filtered_variables[2][[1]]
    parsed_lhs <-
      purrr::map_dfr(lhs, ~ .recursive_parse(.x, .role = "outcome"))
  } else {
    parsed_lhs <-tibble(
      .var  = lhs,
      .role = list("outcome")
    )
  }

  parsed_rhs <-
    purrr::map_dfr(rhs, .recursive_parse)

  output <-
    bind_rows(
      parsed_lhs,
      parsed_rhs
    )

  output <-
    left_join(output, variable_classes, by = ".var")

  if (!("index" %in% output$.role)) {
    output <-
      output %>%
      mutate(.role = ifelse(.type %in% date_types,
                            "index", .role))
  }

  # If still no index
  if (!("index" %in% output$.role)) {
    message("Cannot indetify any index variable!")
  }

  if (!("predictor" %in% output$.role)) {

    .predictors <-
      filter(output, .role == "outcome") %>%
      mutate(.role = "predictor")

    class(.predictors$.role) <- "list"

    output <-
      bind_rows(output, .predictors)
  }

  output
}

.recursive_parse <- function(object, .role = NULL){

  if (typeof(object) == "symbol") {

    if (is.null(.role))
      .role <- "predictor"

    if (as.character(object) == "+")
      out <- tibble(.var = NULL, .role = NULL)
    else
      out <- tibble(
        .var  = as.character(object),
        .role = list(.role)
      )

  } else if (typeof(object) == "language") {
    .candidate_role <- rlang::call_name(object)
    if (as.character(.candidate_role) != "+")
      .role  <- c(.role, .candidate_role)
    object <- rlang::call_args(object)
    out    <- purrr::map_dfr(object, ~ .recursive_parse(.x, .role))
  }

  out
}
