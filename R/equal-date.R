#' Converts a date column to numeric-only format
#'
#' @param .date A Date vector
#' @return A numeric vector with YYYYMMDD format
#'
#' @examples
#' numeric_date(as.Date("2020-12-06"))
#'
#' @export
numeric_date <- function(.date){
  lubridate::year(.date) * 10000 +
    lubridate::month(.date) * 100 +
    lubridate::day(.date)
}

#' @name equal
#' @title Adds a phantom 29th of February to data.frame
#'
#' @param .data A data.frame-like object
#' @param fill If true, all the dates between
#' minimum and maximum date are added
#'
#' @examples
#' pedestrian_per_day <-
#'  as_tibble(tsibble::pedestrian) %>%
#'  group_by(Sensor, Date) %>%
#'  summarise(Count = sum(Count, na.rm = TRUE))
#'
#' head(pedestrian_per_day)
#'
#' # Equal years
#' filled_dates <-
#'   pedestrian_per_day %>%
#'   equal_years(Date)
#'
#' head(filled_dates)
#'
#' filter(filled_dates, is.na(Date))
#'
#' # Equal months
#' filled_dates <-
#'   pedestrian_per_day %>%
#'   equal_months(Date)
#'
#' filter(filled_dates, is.na(Date))
NULL

#' @rdname equal
#' @export
equal_years <- function(.data, .date_col, .fill = TRUE){

  .date_col <- deparse(substitute(.date_col))
  .phantom_date_col <- paste0("phantom_", .date_col)

  if (.fill)
    .data <- timetk::pad_by_time(.data, !!.date_col, .by = "day")

  .data[[.phantom_date_col]] <-
    numeric_date(.data[[.date_col]])

  .phantom_date_range <-
    dplyr::select(ungroup(.data), !!.date_col, !!.phantom_date_col)

  .to_be_added <-
    .phantom_date_range %>%
    dplyr::filter(
      lubridate::month(.[[.date_col]]) == 2,
      lubridate::day(.[[.date_col]]) == 28
    ) %>%
    dplyr::select(!!.phantom_date_col) %>%
    unique() %>%
    pull()

  .to_be_added <- .to_be_added + 1

  .phantom_date_range <-
    c(
      .phantom_date_range[[.phantom_date_col]],
      .to_be_added
    )

  .phantom_date_range <-
    sort(unique(.phantom_date_range))

  .phantom_date_range <-
    tibble(!!.phantom_date_col := .phantom_date_range)

  .data <-
    dplyr::right_join(.data, .phantom_date_range,
                      by = .phantom_date_col)
  .data
}

#' @rdname equal
#' @export
equal_months <- function(.data, .date_col, .fill = TRUE){

  .date_col <- deparse(substitute(.date_col))
  .phantom_date_col <- paste0("phantom_", .date_col)

  if (.fill)
    .data <- timetk::pad_by_time(.data, !!.date_col, .by = "day")

  .data[[.phantom_date_col]] <-
    numeric_date(.data[[.date_col]])

  .phantom_date_range <-
    dplyr::select(ungroup(.data), !!.date_col, !!.phantom_date_col)

  .to_be_added <-
    .phantom_date_range %>%
    dplyr::filter(
      lubridate::day(.[[.date_col]]) == 28
    ) %>%
    dplyr::select(!!.phantom_date_col) %>%
    unique() %>%
    pull()

  .to_be_added <-
    purrr::reduce(purrr::map(.to_be_added, ~ .x + 1:3), c)

  .phantom_date_range <-
    c(
      .phantom_date_range[[.phantom_date_col]],
      .to_be_added
    )

  .phantom_date_range <-
    sort(unique(.phantom_date_range))

  .phantom_date_range <-
    tibble(!!.phantom_date_col := .phantom_date_range)

  .data <-
    dplyr::right_join(.data, .phantom_date_range,
                      by = .phantom_date_col)
  .data
}
