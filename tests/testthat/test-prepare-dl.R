test_that("Simple prepare_dl test - no validataion dataloader", {

  tarnow_temp <-
    weather_pl %>%
    filter(station == "TRN") %>%
    select(date, tmax_daily, tmin_daily, press_mean_daily)

  data_split <-
    time_series_split(
      tarnow_temp, date,
      initial = "18 years",
      assess  = "2 years",
      lag     = 20
    )

  dls <-
    prepare_dl(
      data       = training(data_split),
      formula    = tmax_daily ~ date,
      index      = "date",
      timesteps  = 28,
      horizon    = 7,
      validation = NULL,
      scale      = TRUE,
      batch_size = 32
    )

  expect_equal(class(dls[[1]]), c("dataloader", "R6"))
  expect_equal(dls[[2]], NULL)

})


test_that("Simple prepare_dl test - with numeric validataion argument", {

  tarnow_temp <-
    weather_pl %>%
    filter(station == "TRN") %>%
    select(date, tmax_daily, tmin_daily, press_mean_daily)

  data_split <-
    time_series_split(
      tarnow_temp, date,
      initial = "18 years",
      assess  = "2 years",
      lag     = 20
    )

  dls <-
    prepare_dl(
      data       = training(data_split),
      formula    = tmax_daily ~ date,
      index      = "date",
      timesteps  = 28,
      horizon    = 7,
      validation = 0.25,
      scale      = TRUE,
      batch_size = 32
    )

  expect_equal(class(dls[[1]]), c("dataloader", "R6"))
  expect_equal(class(dls[[2]]), c("dataloader", "R6"))

})
