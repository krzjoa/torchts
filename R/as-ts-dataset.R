#' Create a torch dataset for time series data
#'
#' @param data (data.frame)
#' @param formula A formula describing, how to use the data
#' @param index The index column
#' @param key The key column(s)
#' @param timesteps The time series chunk length
#' @param h Forecast horizon
#' @param sample_frac Sample a fraction of rows (default: 1, i.e.: all the rows)
#' @param scale (logical or list) Scale feature columns. Logical value or two-element list
#' with values (mean, std)
#'
#' @note
#' If `scale` is TRUE, only the input vaiables are scale and not the outcome ones.
#' See: [Is it necessary to scale the target value in addition to scaling features for regression analysis? (Cross Validated)](https://stats.stackexchange.com/questions/111467/is-it-necessary-to-scale-the-target-value-in-addition-to-scaling-features-for-re)
#'
#' @examples
#' library(rsample)
#'
#' suwalki_temp <-
#'    weather_pl %>%
#'    filter(station == "SWK") %>%
#'    select(date, temp = tmax_daily)
#'
#' # Splitting on training and test
#' data_split <- initial_time_split(suwalki_temp)
#'
#' train_ds <-
#'  training(data_split) %>%
#'  as_ts_dataset(temp ~ date, timesteps = 20, h = 1)
#'
#' train_ds[1]
#'
#' @export
as_ts_dataset <- function(data, formula, index = NULL, key = NULL, target = NULL,
                          timesteps, h = 1, sample_frac = 1,
                          scale = TRUE){
  UseMethod("as_ts_dataset")
}

#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, target = NULL, timesteps,
                                     h = 1, sample_frac = 1,
                                     scale = TRUE){


  if (nrow(data) == 0) {
    stop("The data object is empty!")
  }

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

  if (is.null(.index_columns) | length(.index_columns) == 0)
    stop("No time index column defined! Add at least one time-based variable.")

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
    data           = data_tensor,
    timesteps      = timesteps,
    h              = h,
    input_columns  = .input_column_idx,
    target_columns = .target_column_idx,
    sample_frac    = sample_frac,
    scale          = scale
  )
}
