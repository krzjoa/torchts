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
#' @importFrom recipes recipe step_integer bake prep
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
as_ts_dataset <- function(data, formula, index = NULL, key = NULL,
                          predictors = NULL, outcomes = NULL, categorical = NULL,
                          timesteps, horizon = 1, sample_frac = 1,
                          scale = TRUE, jump = 1, ...){
  UseMethod("as_ts_dataset")
}


#'@export
as_ts_dataset.default <- function(data, formula, index = NULL, key = NULL,
                                  predictors = NULL, outcomes = NULL, categorical = NULL,
                                  timesteps, horizon = 1, sample_frac = 1,
                                  scale = TRUE, jump = 1, ...){
  stop(sprintf(
    "Object of class %s in not handled for now.", class(data)
  ))
}

#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, predictors = NULL,
                                     outcomes = NULL,
                                     categorical = NULL,
                                     timesteps, horizon = 1, sample_frac = 1,
                                     scale = TRUE, jump = 1, ...){

  # TODO: remove key, index, outcomes etc. (define only with formula or parsed formula)?

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
  if (!is.null(parsed_formula)) {

    .predictors_columns <- past_spec(

      # Numeric time-varying variables
      x_num = get_vars(parsed_formula, "predictor", "numeric"),

      # Categorical time-varying variables
      x_cat = get_vars(parsed_formula, "predictor", "categorical")
    )

    # Future spec: outcomes + predictors
    .future_columns <- future_spec(
      y = vars_with_role(parsed_formula, "outcome"),
      # Possible predictors from the future (e.g. coming holidays)
      x_fut_num = get_vars2(parsed_formula, "predictor", "numeric", "lead"),
      x_fut_cat = get_vars2(parsed_formula, "predictor", "categorical", "lead")
    )

    .index_columns <-
      parsed_formula[parsed_formula$.role == "index", ]$.var

  } else {

    # Add future predictors or remove this option
    .predictors_columns  <- past_spec(
      x_num = setdiff(predictors, categorical),
      x_cat = categorical[categorical %in% predictors]
    )

    .outcomes_columns    <- list(y = outcomes)
    .index_columns       <- index

  }

  if (length(.predictors_columns$x_cat) != 0) {

    # Prep recipe in none is passed
    if (is.null(extra_args$cat_recipe)) {

      cat_columns <- c(.predictors_columns$x_cat,
                       .future_columns$x_fut_cat)

      cat_recipe <-
        recipe(data) %>%
        step_integer(all_of(cat_columns)) %>%
        prep()
    } else {
      cat_recipe <- extra_args$cat_recipe
    }

    data <-
      cat_recipe %>%
      bake(new_data = data)

  } else {
    cat_recipe <- NULL
  }

  if (is.null(.index_columns) | length(.index_columns) == 0)
    stop("No time index column defined! Add at least one time-based variable.")

  all_variables <-
    unique(c(
      unlist(.predictors_columns),
      unlist(.future_columns),
      unlist(.index_columns)
    ))

  # Filtering unused columns
  # This step keep also the proper column order
  data <- select(data, all_of(all_variables))

  # Transforming column names to column number
  column_order <-
    head(data, 1) %>%
    select(!!.index_columns, everything()) %>%
    select(-!!.index_columns) %>%
    colnames()

  .past_spec <-
    purrr::map(.predictors_columns, ~ match(.x, column_order))

  .future_spec <-
    purrr::map(.future_columns, ~ match(.x, column_order))

  data_tensor <-
    as_tensor(data, !!.index_columns)

  ts_dataset(
    data         = data_tensor,
    timesteps    = timesteps,
    horizon      = horizon,
    past_spec    = .past_spec,
    future_spec  = .future_spec,
    categorical  = c("x_cat", "x_fut_cat"),
    sample_frac  = sample_frac,
    scale        = scale,
    jump         = jump,
    extras       = list(cat_recipe = cat_recipe)
  )
}


#' Predictors specification
#' It facilitates to keep the same variables in all the specification list
#' and avoid typos
past_spec <- function(x_num = NULL, x_cat = NULL){
  output <- list(x_num = x_num, x_cat = x_cat)
  Filter(function(var) !is.null(var) & length(var) != 0, output)
}

future_spec <- function(y, x_fut_num = NULL, x_fut_cat = NULL){
  output <- list(
    y         = y,
    x_fut_num = x_fut_num,
    x_fut_cat = x_fut_cat
  )
  Filter(function(var) !is.null(var) & length(var) != 0, output)
}

