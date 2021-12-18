test_that("Test check_is_complete", {
  expect_error(check_is_complete(weather_pl))
  expect_equal(check_is_complete(mtcars), NULL)
})

test_that("Test check_is_new_data_complete", {

  weather_trn_1 <-
    weather_pl %>%
    filter(station == 'TRN') %>%
    select(date, tmin_daily, tmin_soil)

  weather_trn_1 <-
    clear_outcome(weather_trn, date,
                  c(tmin_daily, tmin_soil), 20)

  object_1 <- list(predictors = "tmin_soil", outcomes = "tmin_daily")

  expect_error(check_is_new_data_complete(object_1, weather_trn_1))

  weather_trn_2 <-
    weather_pl %>%
    filter(station == 'TRN') %>%
    select(date, tmin_daily, tmin_soil)

  weather_trn_2 <-
    clear_outcome(weather_trn_2, date, tmin_daily, 20)

  object_2 <- list(predictors = "tmin_soil", outcomes = "tmin_daily")

  expect_equal(check_is_new_data_complete(object_2, weather_trn_2), NULL)
})
