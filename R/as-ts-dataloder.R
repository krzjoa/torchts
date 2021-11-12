#' Quick shortcut to create a torch dataloader based on the given dataset
#'
#' @inheritParams as_ts_dataset
#' @param batch_size (`numeric`) Batch size.
#'
#' @importFrom torch dataloader
#'
#' @examples
#' library(rsample)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' suwalki_temp <-
#'    weather_pl %>%
#'    filter(station == "SWK") %>%
#'    select(date, temp = tmax_daily)
#'
#' # Splitting on training and test
#' data_split <- initial_time_split(suwalki_temp)
#'
#' train_dl <-
#'  training(data_split) %>%
#'  as_ts_dataloader(temp ~ date, timesteps = 20, horizon = 10, batch_size = 32)
#'
#' train_dl
#'
#' dataloader_next(dataloader_make_iter(train_dl))
#'
#' @export
as_ts_dataloader <- function(data, formula, index = NULL,
                             key = NULL,
                             predictors = NULL,
                             outcomes = NULL,
                             categorical = NULL,
                             timesteps, batch_size, horizon = 1,
                             sample_frac = 1, scale = TRUE,
                             ...){
  UseMethod("as_ts_dataloader")
}


#' @export
as_ts_dataloader.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, predictors = NULL,
                                     outcomes = NULL, categorical = NULL,
                                     timesteps, batch_size,
                                     horizon = 1, sample_frac = 1,
                                     scale = TRUE, ...){
  dataloader(
    as_ts_dataset(
      data        = data,
      formula     = formula,
      index       = index,
      key         = key,
      predictors  = predictors,
      outcomes    = outcomes,
      categorical = categorical,
      timesteps   = timesteps,
      horizon     = horizon,
      sample_frac = sample_frac,
      scale       = scale,
      # Extra args
      ...),
    batch_size = batch_size
    )
}

#' Accessor for `scale_params` values in a dataloader object
#' @export
scale_params <- function(dataloader, ...){
  # TODO: change name?
  UseMethod("scale_params")
}

#' @export
scale_params.dataloader <- function(dataloader, ...){
  # TODO: maybe don't use S3?
  dataloader$dataset$scale_params
}






