#' @export
print.torchts_model <- function(x, ...){

  key <- if (length(x$key) == 0) "NULL" else x$key
  predictors <- paste0(x$predictors, collapse = ", ")
  outcomes   <- paste0(x$outcomes, collapse = ", ")

  print(x$net)
  cat("\n")
  cat("Model specification: \n")
  cli::cat_bullet(glue::glue("key: {key}"))
  cli::cat_bullet(glue::glue("index: {x$index}"))
  cli::cat_bullet(glue::glue("predictors: {predictors}"))
  cli::cat_bullet(glue::glue("outcomes: {outcomes}"))
  cli::cat_bullet(glue::glue("timesteps: {x$timesteps}"))
  cli::cat_bullet(glue::glue("horizon: {x$horizon}"))
  cli::cat_bullet(glue::glue("optimizer: {class(x$optim)[1]}"))

}
