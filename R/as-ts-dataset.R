#' Create a torch dataset for time series data from a `data.frame`-like object
#'
#' @param data (`data.frame`) An input data.frame object with.
#' For now only **single** data frames are handled with no categorical features.
#' @param formula (`formula`) A formula describing, how to use the data
#' @param index (`character`) The index column name.
#' @param key (`character`) The key column name(s). Use only if formula was not specified.
#' @param predictors (`character`) Input variable names. Use only if formula was not specified.
#' @param outcomes (`character`) Target variable names. Use only if formula was not specified.
#' @param categorical (`character`) Categorical features.
#' @param timesteps (`integer`) The time series chunk length.
#' @param horizon (`integer`) Forecast horizon.
#' @param sample_frac (`numeric`) Sample a fraction of rows (default: 1, i.e.: all the rows).
#' @param scale (`logical` or `list`) Scale feature columns. Logical value or two-element list.
#' with values (mean, std)
#'
#' @importFrom recipes recipe step_integer step_scale bake prep
#'
#' @note
#' If `scale` is TRUE, only the input variables are scale and not the outcome ones.
#'
#' See: [Is it necessary to scale the target value in addition to scaling features for regression analysis? (Cross Validated)](https://stats.stackexchange.com/questions/111467/is-it-necessary-to-scale-the-target-value-in-addition-to-scaling-features-for-re)
#'
#' @examples
#' library(rsample)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' suwalki_temp <-
#'    weather_pl %>%
#'    filter(station == "SWK")
#'
#' debugonce(as_ts_dataset.data.frame)
#'
#' # Splitting on training and test
#' data_split <- initial_time_split(suwalki_temp)
#'
#' train_ds <-
#'  training(data_split) %>%
#'  as_ts_dataset(tmax_daily ~ date + tmax_daily + rr_type,
#'                timesteps = 20, horizon = 1)
#'
#' train_ds[1]
#'
#' train_ds <-
#'  training(data_split) %>%
#'  as_ts_dataset(tmax_daily ~ date + tmax_daily + rr_type + lead(rr_type),
#'                timesteps = 20, horizon = 1)
#'
#' train_ds[1]
#'
#' train_ds <-
#'  training(data_split) %>%
#'  as_ts_dataset(tmax_daily ~ date + tmax_daily + rr_type + lead(tmin_daily),
#'                timesteps = 20, horizon = 1)
#'
#' train_ds[1]
#'
#' @export
as_ts_dataset <- function(data, formula,
                          timesteps, horizon = 1, sample_frac = 1,
                          scale = TRUE, jump = 1, ...){
  UseMethod("as_ts_dataset")
}


#'@export
as_ts_dataset.default <- function(data, formula,
                                  timesteps, horizon = 1, sample_frac = 1,
                                  scale = TRUE, jump = 1, ...){
  stop(sprintf(
    "Object of class %s in not handled for now.", class(data)
  ))
}

#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL,
                                     timesteps, horizon = 1, sample_frac = 1,
                                     scale = TRUE, jump = 1, ...){

  # TODO: remove key, index, outcomes etc.
  # (define only with formula or parsed formula)?
  extra_args <- list(...)

  if (nrow(data) == 0) {
    stop("The data object is empty!")
  }

  if (is.null(extra_args$parsed_formula))
    parsed_formula <- torchts_parse_formula(formula, data = data)
  else
    parsed_formula <- extra_args$parsed_formula

  # Parsing formula
  # TODO: key is not used for now
  .past_spec <- list(

    # Numeric time-varying variables
    x_num = get_vars(parsed_formula, "predictor", "numeric"),

    # Categorical time-varying variables
    x_cat = get_vars(parsed_formula, "predictor", "categorical")
  )

  # Future spec: outcomes + predictors
  .future_spec <- list(
    y = vars_with_role(parsed_formula, "outcome"),
    # Possible predictors from the future (e.g. coming holidays)
    x_fut_num = get_vars2(parsed_formula, "predictor", "numeric", "lead"),
    x_fut_cat = get_vars2(parsed_formula, "predictor", "categorical", "lead")
  )

  .index_columns <-
    parsed_formula[parsed_formula$.role == "index", ]$.var

  # Removing NULLs
  .past_spec   <- remove_nulls(.past_spec)
  .future_spec <- remove_nulls(.future_spec)

  categorical <-
    parsed_formula %>%
    filter(.type == 'categorical') %>%
    pull(.var)

  data <-
    data %>%
    arrange(!!.index_columns)

  ts_recipe <-
    recipe(data) %>%
    step_integer(all_of(categorical)) %>%
    step_scale(all_numeric()) %>%
    prep()

  data <-
    ts_recipe %>%
    bake(new_data = data)

  if (is.null(.index_columns) | length(.index_columns) == 0)
    stop("No time index column defined! Add at least one time-based variable.")

  ts_dataset(
    data         = data,
    timesteps    = timesteps,
    horizon      = horizon,
    past_spec    = .past_spec,
    future_spec  = .future_spec,
    categorical  = c("x_cat", "x_fut_cat"),
    sample_frac  = sample_frac,
    scale        = scale,
    jump         = jump,
    extras       = list(recipe = ts_recipe)
  )
}

remove_nulls <- function(x) {
  Filter(function(var) !is.null(var) & length(var) != 0, x)
}


#' Predictors specification
#' It facilitates to keep the same variables in all the specification list
#' and avoid typos
# past_spec <- function(x_num = NULL, x_cat = NULL){
#   output <- list(x_num = x_num, x_cat = x_cat)
#   Filter(function(var) !is.null(var) & length(var) != 0, output)
# }
#
# future_spec <- function(y, x_fut_num = NULL, x_fut_cat = NULL){
#   output <- list(
#     y         = y,
#     x_fut_num = x_fut_num,
#     x_fut_cat = x_fut_cat
#   )
#   Filter(function(var) !is.null(var) & length(var) != 0, output)
# }

