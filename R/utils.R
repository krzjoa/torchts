#' RNN output size
#' @param module (nn_module) A torch `nn_module`
#' @examples
#' gru_layer <- nn_gru(15, 3)
#' rnn_output_size(gru_layer)
#' @export
rnn_output_size <- function(module){
  tail(dim(module$weight_hh_l1), 1)
}

#' Partially clear outcome variable
#' in new data by overriding with NA values
#'
#' @param data (`data.frame`) New data
#' @param index Date variable
#' @param outcome Outcome (target) variable
#' @param timesteps (`integer`) Number of timesteps used by RNN model
#' @param key A key (id) to group the data.frame (for panel data)
#'
#' @importFrom dplyr group_by
#'
#' @examples
#' tarnow_temp <-
#'   weather_pl %>%
#'   filter(station == "TRN") %>%
#'   select(date, tmax_daily, tmin_daily, press_mean_daily)
#'
#' TIMESTEPS <- 20
#' HORIZON   <- 1
#'
#' data_split <-
#'   time_series_split(
#'     tarnow_temp, date,
#'     initial = "18 years",
#'     assess  = "2 years",
#'     lag     = TIMESTEPS
#'   )
#'
#' cleared_new_data <-
#'   testing(data_split) %>%
#'   clear_outcome(date, tmax_daily, TIMESTEPS)
#'
#' head(cleared_new_data, TIMESTEPS + 10)
#'
#' @export
clear_outcome <- function(data, index, outcome, timesteps, key = NULL){

  index   <- as.character(substitute(index))
  outcome <- as.character(substitute(outcome))

  if (outcome[1] == "c")
    outcome <- outcome[-1]

  if (!is.null(key))
    key <- as.character(substitute(key))

  data %>%
    arrange(!!index) %>%
    group_by(!!key) %>%
    mutate(across(!!outcome, ~ c(.x[1:timesteps], rep(NA, n() - timesteps))))
}

inherits_any <- function(col, types){
  any(sapply(types, function(type) inherits(col, type)))
}

inherits_any_char <- function(class, desired_classes){
  output <- sapply(class, function(cls) any(cls[[1]] %in% desired_classes))
  names(output) <- NULL
  output
}

zeroable <- function(x){
  if (is.null(x))
    return(0)
  else
    return(x)
}

#' Colmap for outcome variable
col_map_out <- function(dataloader){
  unlist(dataloader$dataset$outcomes_spec)
}

# Remove NULLs from a list
remove_nulls <- function(x) {
  Filter(function(var) !is.null(var) & length(var) != 0, x)
}


preprend_empty <- function(df, n){
  empty_rows <- matrix(NA, nrow = n, ncol = ncol(df))
  colnames(empty_rows) <- colnames(df)
  empty_rows <- as_tibble(empty_rows)
  rbind(empty_rows, df)
}


# TODO: key_hierarchy




