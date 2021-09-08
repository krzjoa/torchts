#' Create a torch dataset for time series data
#'
#' @param data (data.frame)
#' @param formula A formula describing, how to use the data
#' @param index The index column
#' @param key The key column(s)
#' @param n_timesteps The time seris chunk length
#' @param h Forecast horizon
#' @param sample_frac Sample a fraction of rows (default: 1, i.e.: all the rows)
#'
#' @examples
#' data_set <-
#'  read.csv("https://raw.githubusercontent.com/jbrownlee/Datasets/master/daily-min-temperatures.csv")
#'
# Splitting on training and test
#' data_split <- initial_time_split(data_set)
#'
#' train_ds <-
#'  training(data_split) %>%
#'  as_ts_dataset(Temp ~ Temp + index(Date), n_timesteps = 20, h = 1)
#'
#' @export
as_ts_dataset <- function(data, formula, index = NULL, key = NULL, target = NULL,
                          n_timesteps, h = 1, sample_frac = 1){
  UseMethod("as_ts_dataset")
}

#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, target = NULL, n_timesteps = 20,
                                     h = 1, sample_frac = 1){

  # Parsing formula
  # TODO: key is not used for now
  if (!is.null(formula)) {

    parsed_formula <- torchts_parse_formula(formula, data = data)

    .input_columns <- list(
      x = parsed_formula[parsed_formula$.role == "predictor", ]$.var
    )

    .target_columns <- list(
      y = parsed_formula[parsed_formula$.role == "outcome", ]$.var
    )

    .index_columns <-
      parsed_formula[parsed_formula$.role == "index", ]$.var

  } else {

    .input_columns <- list(
      x = setdiff(colnames(data), c(key, index))
    )

    .target_columns <- list(y = target)

    .index_columns <- index

  }

  # Transforming column names to column number
  column_order <-
    head(data, 1) %>%
    select(!!.index_columns, everything()) %>%
    select(-!!.index_columns) %>%
    colnames()

  .input_column_idx <-
    purrr::map(.input_columns, ~ match(.x, column_order))

  .target_column_idx <-
    purrr::map(.target_columns, ~ match(.x, column_order))

  # TODO: hardcoded!!!
  data_tensor <-
    as_tensor(data, !!.index_columns)

  ts_dataset(
    data          = data_tensor,
    n_timesteps    = n_timesteps,
    h              = h,
    input_columns  = .input_column_idx,
    target_columns = .target_column_idx,
    sample_frac    = sample_frac
  )
}
