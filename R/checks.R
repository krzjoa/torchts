#' Check, if recursion should be used in forecasting
check_recursion <- function(object, new_data){

  # TODO: check, if this procedure is sufficient
  recursive_mode <- FALSE

  # Check, if outcome is predictor
  if (any(object$outcome %in% colnames(new_data))) {
    # Check, there are na values in predictor column
    if (any(is.na(new_data[object$outcome]))) {
      if (nrow(new_data) > object$horizon)
        recursive_mode <- TRUE
    }
  }

  recursive_mode
}

#' Check if input data contains no NAs.
#' Otherwise, return error.
check_is_complete <- function(data){

  complete_cases <- complete.cases(data)

  if (!all(complete_cases)) {
    sample_rows <-
      dplyr::slice_sample(data[!complete_cases,], n = 3)
    stop("Passed data contains incomplete rows, for example: \n",
         print_and_capture(sample_rows))
  }

}

#' Check if new data has NAs in columns others than predicted outcome
check_is_new_data_complete <- function(object, new_data){

  only_predictors <- setdiff(
    object$predictors, object$outcomes
  )

  complete_cases <- complete.cases(new_data[only_predictors])

  if (!all(complete_cases)) {
    sample_rows <-
      dplyr::slice_sample(new_data[!complete_cases,], n = 3)
    stop("Only the outcome variable column is allowed to contains NAs (on its beginning).
          NA values in other columns detected.
          Passed new data contains incomplete rows, for example: \n",
          print_and_capture(sample_rows))
  }

}

check_length_vs_horizon <- function(object, new_data){
  # TODO: adapt to multiple keys

  len <- nrow(new_data)
  modulo <- len %% object$horizon

  if (modulo != 0)
    message(glue(
      "new_data length ({len}) is not a multiple of horizon {object$horizon}.
       Forecast output will be shorter by {modulo} timesteps."
    ))

}


check_stateful_vs_jump <- function(horizon, jump, stateful){
  if ((horizon != jump) & stateful)
    message(glue(
      "Horizon is not equal to jump, while stateful flag is TRUE.
       horizon = {horizon}, jump = {jump}.
       It is not recommended, but it will be performed as Your Majesty wishes."
    ))
}



