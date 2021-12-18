#' Helper function to invert scaling
#'
invert_scaling <- function(preds, scale, col_map_out){

  if (!is.null(scale)) {

    scale <- purrr::map(
      scale, ~ .x[, col_map_out]
    )

    mean_param <- as.vector(scale$mean)
    sd_param   <- as.vector(scale$sd)

    if (is.matrix(preds)) {
      preds <- sweep(preds, 2, sd_param, "*")
      preds <- sweep(preds, 2, mean_param, "+")
    } else {
      preds <- preds * sd_param + mean_param
    }

  }

  preds

}

#' Colmap for outcome variable
col_map_out <- function(dataloader){
  dataloader$dataset$col_map_out
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
