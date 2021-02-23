#' Dictionary size per column
#' @param .data A data.frame-like object
#' @importFrom dplyr n_distinct
#' @export
dict_size <- function(.data){
  sapply(.data, n_distinct)
}

# .vec <- c(1,2,4,3020, 6, 3020, 1, 1, 1, 6)

#' Replace values usong dictionary
# dict_replace <- function(.vec){
#   unique_tokens <-
#     unique(.vec)
#
#   dict <-
#     data.frame(
#       key   = unique_tokens,
#       value = seq_along(unique_tokens)
#     )
#
#   .vec_modified <-
#     dict$value[match(.vec, dict$key)]
#
#   list(.vec_modified, dict)
# }

