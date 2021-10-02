tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, tmax_daily, tmin_daily)

test_that("RNN autoregression output", {

  data_split <-
    time_series_split(
      tarnow_temp, date,
      initial = "18 years",
      assess  = "2 years",
      lag     = 20
    )

  non_trained_model <-
    rnn_fit(
      tmax_daily ~ date,
      data = training(data_split),
      dropout = NULL,
      learn_rate = 0.9,
      hidden_units = 10,
      timesteps = 20,
      horizon = 1,
      epochs = 0
    )

  cleared_new_data <-
    testing(data_split) %>%
    clear_outcome(date, tmax_daily, 20)

  output <-
    non_trained_model %>%
    predict(cleared_new_data)

})



