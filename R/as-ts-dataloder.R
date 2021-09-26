#' Quick shortcut to create a torch dataloader based on the given dataset
#'
#' @param data (data.frame)
#' @param formula A formula describing, how to use the data
#' @param index The index column
#' @param key The key column(s)
#' @param n_timesteps The time seris chunk length
#' @param h Forecast horizon
#' @param sample_frac Sample a fraction of rows (default: 1, i.e.: all the rows)
#' @param batch_size Batch size
#'
#' @importFrom torch dataloader
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
# train_ds <-
#  training(data_split) %>%
#  as_ts_dataloader(temp ~ date, n_timesteps = 20, h = 1, batch_size = 32)
#'
#' @export
as_ts_dataloader <- function(data, formula, index = NULL,
                             key = NULL, target = NULL,
                             timesteps, batch_size, h = 1,
                             sample_frac = 1, scale = TRUE){
  UseMethod("as_ts_dataloader")
}


#' @export
as_ts_dataloader.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, target = NULL,
                                     timesteps, batch_size,
                                     h = 1, sample_frac = 1, scale = TRUE){
  dataloader(
    as_ts_dataset(
      data        = data,
      formula     = formula,
      index       = index,
      key         = key,
      target      = target,
      timesteps   = timesteps,
      h           = h,
      sample_frac = sample_frac,
      scale       = scale),
    batch_size = batch_size
    )
}

#' Accessor for `scale_params` values in a dataloader object
#' @export
scale_params <- function(dataloader, ...){
  UseMethod("scale_params")
}

#' @export
scale_params.dataloader <- function(dataloader, ...){
  # TODO: maybe don't use S3?
  dataloader$dataset$scale_params
}






