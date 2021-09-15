#' Number of timesteps used to generate a forecast
#'
#' @export
timesteps <- function(range = c(1, 50L), trans = NULL){
  dials::new_quant_param(
    type      = "integer",
    range     = range,
    inclusive = c(TRUE, TRUE),
    trans     = trans,
    label     = c(changepoint_num = "Number of timesteps used to forecast"),
    finalize  = NULL
  )
}

#' Length of forecast horizon
#'
# horizon <- function(range = c(1, 50L), trans = NULL){
#   dials::new_quant_param(
#     type      = "integer",
#     range     = range,
#     inclusive = c(TRUE, TRUE),
#     trans     = trans,
#     label     = c(changepoint_num = "Length of forecast horizon"),
#     finalize  = NULL
#   )
# }
