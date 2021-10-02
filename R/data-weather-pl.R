#' Weather data from Polish "poles of extreme temperatures" in 2001-2020
#'
#' The data comes from IMGW (Institute of Meteorology and Water Management) and
#' was downloaded using the `climate` package. Two places have been chosen:
#' \itemize{
#' \item{TRN - Tarnów ("pole of warmth")}
#' \item{SWK - Suwałki ("pole of cold")}
#' }
#' A subset of columns has been selected and `date` column was added.
#'
#' @format
#' \describe{
#' \item{station}{A place where weather data were measured}
#' \item{date}{Date}
#' \item{tmax_daily}{Maximum daily air temperatury [C]}
#' \item{tmin_daily}{Minimum daily air temperature [C]}
#' \item{tmin_soil}{Minimum near surface air temperature [C]}
#' \item{rr_daily}{Total daily preciptation [mm]}
#' \item{rr_type}{Precipitation type [S/W]}
#' \item{rr_daytime}{Total precipitation during day [mm]}
#' \item{rr_nightime}{Total precipitation during night [mm]}
#' \item{press_mean_daily}{Daily mean pressure at station level [hPa]}
#' }
#'
#' @examples
#' # Head of weather_pl
#' head(weather_pl)
"weather_pl"
