library(timetk)

tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, tmax_daily, tmin_daily, press_mean_daily)

test_that("RNN autoregression output", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  data_split <-
    time_series_split(
      tarnow_temp, date,
      initial = "18 years",
      assess  = "2 years",
      lag     = TIMESTEPS
    )

  non_trained_model <-
    rnn_fit(
      tmax_daily ~ date,
      data = training(data_split),
      dropout = FALSE,
      learn_rate = 0.9,
      hidden_units = 10,
      timesteps = TIMESTEPS,
      horizon = HORIZON,
      epochs = 0
    )

  cleared_new_data <-
    testing(data_split) %>%
    clear_outcome(date, tmax_daily, TIMESTEPS)

  output <-
    non_trained_model %>%
    predict(cleared_new_data)

  expect_equal(
    dim(output)[1], nrow(cleared_new_data) - TIMESTEPS
  )

})


test_that("RNN autoregression multioutput", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  data_split <-
    time_series_split(
      tarnow_temp, date,
      initial = "18 years",
      assess  = "2 years",
      lag     = TIMESTEPS
    )

  non_trained_model <-
    rnn_fit(
      tmax_daily + tmin_daily ~ date,
      data = training(data_split),
      dropout = FALSE,
      learn_rate = 0.9,
      hidden_units = 10,
      timesteps = TIMESTEPS,
      horizon = HORIZON,
      epochs = 0
    )

  cleared_new_data <-
    testing(data_split) %>%
    clear_outcome(date, c(tmax_daily, tmin_daily), TIMESTEPS)

  output <-
    non_trained_model %>%
    predict(cleared_new_data)

  # Dimensions
  expect_equal(
    dim(output)[1],
    nrow(cleared_new_data) - TIMESTEPS
  )

  expect_equal(dim(output)[2], 2)

  # Colnames if mor than two columns
  expect_equal(
    colnames(output),
    c("tmax_daily", "tmin_daily")
  )

})




