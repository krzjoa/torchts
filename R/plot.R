#' Plot forecast vs ground truth
#'
#' @export
plot_forecast <- function(data, forecast, outcome,
                          index = NULL, interactive = TRUE, ...){

  outcome <- as.character(substitute(outcome))

  if (!is.null(index))
    index   <- as.character(substitute(index))

  if (ncol(forecast) > 1)
    forecast <- forecast[outcome]


  fcast_vs_true <-
    bind_cols(
      n = 1:nrow(data),
      actual = data[[outcome]],
      fcast
    ) %>%
    tidyr::pivot_longer(c(actual, .pred))

  p <-
    ggplot(fcast_vs_true) +
      geom_line(aes(n, value, col = name)) +
      theme_minimal() +
      ggtitle("Forecast vs actual values")

  if (interactive)
    p <- plotly::ggplotly()

  p
}
