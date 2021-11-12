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
#' @export
as_ts_dataset <- function(data, formula, index = NULL, key = NULL,
                          predictors = NULL, outcomes = NULL, categorical = NULL,
                          timesteps, horizon = 1, sample_frac = 1,
                          scale = TRUE, ...){
  UseMethod("as_ts_dataset")
}


#'@export
as_ts_dataset.default <- function(data, formula, index = NULL, key = NULL,
                                  predictors = NULL, outcomes = NULL, categorical = NULL,
                                  timesteps, horizon = 1, sample_frac = 1,
                                  scale = TRUE, ...){
  stop(sprintf(
    "Object of class %s in not handled for now.", class(data)
  ))
}

#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, predictors = NULL,
                                     outcomes = NULL, categorical = NULL,
                                     timesteps, horizon = 1, sample_frac = 1,
                                     scale = TRUE, ...){

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

    .predictors_columns <- predictors_spec(

      # Numeric time-varying variables
      x_num = parsed_formula[parsed_formula$.role == "predictor" &
                            parsed_formula$.type == "numeric", ]$.var,

      # Categorical time-varying variables
      x_cat = parsed_formula[parsed_formula$.role == "predictor" &
                             parsed_formula$.type == "categorical", ]$.var
    )

    .outcomes_columns <- list(
      y = parsed_formula[parsed_formula$.role == "outcome", ]$.var
    )

    .index_columns <-
      parsed_formula[parsed_formula$.role == "index", ]$.var

  } else {

    .predictors_columns  <- predictors_spec(
      x_num = setdiff(predictors, categorical),
      x_cat = categorical[categorical %in% predictors]
    )

    .outcomes_columns    <- list(y = outcomes)
    .index_columns       <- index

  }

  if (!is.null(.predictors_columns$x_cat)) {

    # Prep recipe in none is passed
    if (is.null(extra_args$cat_recipe)) {
      cat_recipe <-
        recipe(data) %>%
        step_integer(all_of(c(.predictors_columns$x_cat))) %>%
        prep()
    } else {
      cat_recipe <- extra_args$cat_recipe
    }

    data <-
      cat_recipe %>%
      bake(new_data = data)

  }

  if (is.null(.index_columns) | length(.index_columns) == 0)
    stop("No time index column defined! Add at least one time-based variable.")

  all_variables <-
    unique(c(
      unlist(.predictors_columns),
      unlist(.outcomes_columns),
      unlist(.index_columns)
    ))

  # Filtering unused columns
  data <- select(data, all_of(all_variables))

  # Transforming column names to column number
  column_order <-
    head(data, 1) %>%
    select(!!.index_columns, everything()) %>%
    select(-!!.index_columns) %>%
    colnames()

  .predictors_spec <-
    purrr::map(.predictors_columns, ~ match(.x, column_order))

  .outcomes_spec <-
    purrr::map(.outcomes_columns, ~ match(.x, column_order))

  # TODO: hardcoded!!!
  data_tensor <-
    as_tensor(data, !!.index_columns)

  # TODO: change ts_dataset
  ts_dataset(
    data            = data_tensor,
    timesteps       = timesteps,
    horizon         = horizon,
    predictors_spec = .predictors_spec,
    outcomes_spec   = .outcomes_spec,
    categorical     = "x_cat",
    sample_frac     = sample_frac,
    scale           = scale,
    extras          = list(cat_recipe = cat_recipe)
  )
}


#' Predictors specification
#' It facilitates to keep the same variables in all the specification list
#' and avoid typos
predictors_spec <- function(x_num = NULL, x_cat = NULL){
  output <- list(x_num = x_num, x_cat = x_cat)
  Filter(function(var) !is.null(var), output)
}


# prepare_categorical <- function(x, ...){
#
# }





