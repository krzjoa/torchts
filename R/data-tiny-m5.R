#' A subset from M5 Walmart Challenge Dataset in one data frame
#'
#' A piece of data cut from the training dataset used in the M5 challenges on Kaggle.
#' M5 is a challenge from a series organized by Spyros Makridakis.
#'
#'
#' @format
#' \describe{
#' \item{item_id}{The id of the product}
#' \item{dept_id}{The id of the department the product belongs to}
#' \item{cat_id}{The id of the category the product belongs to}
#' \item{store_id}{The id of the store where the product is sold}
#' \item{state_id}{The State where the store is located}
#' \item{value}{The number of sold units}
#' \item{date}{The date in a “y-m-d” format}
#' \item{wm_yr_wk}{The id of the week the date belongs to}
#' \item{weekday}{The type of the day (Saturday, Sunday, …, Friday)}
#' \item{wday}{The id of the weekday, starting from Saturday}
#' \item{month}{ The month of the date}
#' \item{year}{The year of the date}
#' \item{event_name_1}{If the date includes an event, the name of this event}
#' \item{event_type_1}{If the date includes an event, the type of this event}
#' \item{event_name_2}{If the date includes a second event, the name of this event}
#' \item{event_type_2}{If the date includes a second event, the type of this event}
#' \item{snap}{A binary variable (0 or 1) indicating whether the stores of CA, TX or WI allow SNAP1 purchases on the examined date. 1 indicates that SNAP purchases are allowed}
#' \item{sell_price}{The price of the product for the given week/store.
#' The price is provided per week (average across seven days). If not available, this means that the product was not sold during the examined week.
#' Note that although prices are constant at weekly basis, they may change through time (both training and test set)}
#' }
#'
#' @seealso
#' [M5 Forecasting - Accuracy](https://www.kaggle.com/c/m5-forecasting-accuracy)
#'
#' [M5 Forecasting - Uncertainty](https://www.kaggle.com/c/m5-forecasting-uncertainty)
#'
#' [The M5 competition: Background, organization, and implementation](https://www.sciencedirect.com/science/article/pii/S0169207021001187)
#'
#' [Other Walmart datasets in timetk](https://business-science.github.io/timetk/reference/index.html#section-time-series-datasets)
#'
#' @examples
#' # Head of tiny_m5
#' head(tiny_m5)
"tiny_m5"
