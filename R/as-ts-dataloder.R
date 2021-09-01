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
#' @export
as_ts_dataloader <- function(data, formula, index = NULL, key = NULL, target = NULL,
                          n_timesteps, batch_size, h = 1, sample_frac = 1, ...){
  UseMethod("as_ts_dataloader")
}


#' @export
as_ts_dataset.data.frame <- function(data, formula = NULL, index = NULL,
                                     key = NULL, target = NULL, n_timesteps, batch_size,
                                     h = 1, sample_frac = 1, ...){
  dataloader(
    as_ts_dataset(
      data = data,
      formula = formula,
      index = index,
      key = key,
      target = target,
      n_timesteps = n_timesteps,
      batch_size = batch_size,
      h = h,
      sample_frac = sample_frac,
      ...)
    )
}
