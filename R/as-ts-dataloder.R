#' Quick shortcut to create a torch dataloader based on the given dataset
#'
#' @inheritParams as_ts_dataset
#' @param batch_size (`numeric`) Batch size.
#' @param shuffle (`logical`) Shuffle examples.
#' @param drop_last (`logical`) Set to TRUE to drop the last incomplete batch,
#' if the dataset size is not divisible by the batch size.
#' If FALSE and the size of dataset is not divisible by the batch size,
#' then the last batch will be smaller. (default: TRUE)
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
                             timesteps, horizon = 1,
                             sample_frac = 1,
                             batch_size, shuffle = FALSE,
                             jump = 1, drop_last = TRUE,
                             ...){
  UseMethod("as_ts_dataloader")
}


#' @export
as_ts_dataloader.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, predictors = NULL,
                                     outcomes = NULL, categorical = NULL,
                                     timesteps, horizon = 1, sample_frac = 1,
                                     batch_size, shuffle = FALSE,
                                     jump = 1, drop_last = TRUE, ...){
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
      jump        = jump,
      # Extra args
      ...),

    # Dataloader args
    batch_size = batch_size,
    shuffle    = shuffle,
    drop_last  = drop_last
    )
}
