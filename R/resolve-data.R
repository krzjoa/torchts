#'
#'
#' @param formula Formula, how to interpret data
#' @param n_timesteps Number of timesteps for the input data
#' @param h Forecast horizon
#' @param prop Dataset proportions
resolve_ts_datasets <- function(.data, formula, n_timesteps, h, prop){
  training_and_validation <- initial_time_split(.data, prop)
}
