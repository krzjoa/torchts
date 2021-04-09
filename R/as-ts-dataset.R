#' Create a tensor to handle time series data
#'
#' @param .data (data.frame)
#' @param formula
#' @param index
#' @param key
#' @param n_timesteps
#' @param h
#' @param sample
#'
#' @export
as_ts_dataset <- function(.data, formula, index = NULL, key = NULL,
                          n_timesteps, h = 1, sample_frac = 1){
  UseMethod("as_ts_dataset")
}

#' @export
as_ts_dataset.data.frame <- function(.data, formula, index = NULL, key = NULL,
                                     n_timesteps, h = 1, sample_frac = 1){

  # Parsing formula
  parsed_formula <- torchts_parse_formula(formula, data = .data)

  .input_columns <- list(
    x = parsed_formula[parsed_formula$.type == "outcome", ]$.var
  )

  .target_columns <- list(
    y = parsed_formula[parsed_formula$.type == "outcome", ]$.var
  )

  .data_tensor <-
    as_tensor(.data, Date, Temp)

  ts_dataset(
    .data          = .data_tensor,
    n_timesteps    = n_timesteps,
    h              = h,
    input_columns  = .input_columns,
    target_columns = .target_columns,
    sample_frac    = sample_frac
  )
}
