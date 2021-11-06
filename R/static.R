#' Check, which variables are static
#'
#' @examples
#' data <- tiny_m5 %>%
#' dplyr::select(store_id, item_id, state_id,
#'               weekday, wday, month, year)
#'
#' @export
which_static <- function(data, key, cols = NULL){

  if (is.null(cols))
    cols <- colnames(data)

  non_grouping_vars <- setdiff(cols, key)

  data %>%
    group_by(across(all_of(key))) %>%
    summarise(across(all_of(non_grouping_vars), all_the_same)) %>%
    ungroup() %>%
    summarise(across(all_of(non_grouping_vars), all))
}
