#' Plot forecast vs ground truth
#'
#' @param data
#' @param forecast
#' @param outcome
#' @param index
#' @param interactive (`logical`)
#'
#' @importFrom ggplot2 ggplot geom_line aes theme_minimal ggtitle
#'
#' @export
plot_forecast <- function(data, forecast, outcome,
                          index = NULL, interactive = TRUE,
                          title = "Forecast vs actual values",
                          ...){

  outcome <- as.character(substitute(outcome))

  if (!is.null(index))
    index   <- as.character(substitute(index))

  if (ncol(forecast) > 1)
    forecast <- forecast[outcome]

  fcast_vs_true <-
    bind_cols(
      n = 1:nrow(data),
      actual = data[[outcome]],
      forecast
    ) %>%
    tidyr::pivot_longer(c(actual, .pred))

  p <-
    ggplot(fcast_vs_true) +
      geom_line(aes(n, value, col = name)) +
      theme_minimal() +
      ggtitle(title) +
      scale_color_manual(values = torchts_palette)

  if (interactive)
    p <- plotly::ggplotly()

  p
}
