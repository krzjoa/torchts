#' Span a time range each
#'
#' @param .data A data.frame-like object
#' @param .key A key column(s)
#' @param .date_var A Date-like format column
#' @param .by
#'
#' @seealso `timetk::pad_by_time`
#'
#' @importFrom dplyr pull right_join
#' @export
span_time <-function(.data, .key, .date_var, .by = "day"){

   # TODO: .time_var instead of .date_var

  .key <- deparse(substitute(.key))
  .date_var <- deparse(substitute(.date_var))

  .min_date <- min(pull(.data, !!.date_var))
  .max_date <- max(pull(.data, !!.date_var))

  .var_list <- list()
  .var_list[[.date_var]] <-
    seq(.min_date, .max_date, by = .by)

  for (.var in .key) {
    .var_list[[.var]] <-
      unique(pull(.data, !!.var))
  }

  full_time_span <- expand.grid(.var_list)
  right_join(.data, full_time_span, by = c(.key, .date_var))
}
