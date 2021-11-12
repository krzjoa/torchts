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