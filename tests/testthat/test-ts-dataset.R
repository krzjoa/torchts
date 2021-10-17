test_that("Test ts_dataset", {

  weather_pl_tensor <-
    weather_pl %>%
    filter(station == "TRN") %>%
    select(-station, -rr_type) %>%
    as_tensor(date)

  weather_pl_dataset <-
     ts_dataset(
       data = weather_pl_tensor,
       timesteps = 28,
       horizon = 7,
       predictors_spec = list(x = 2:7),
       outcomes_spec   = list(y = 1),
       scale = TRUE
     )

  batch <-
    weather_pl_dataset$.getitem(1)

  expect_equal(dim(batch$x), c(28, 6))
  expect_equal(dim(batch$y), 7)

})


test_that("Passing non-tabular data as first argument", {

  weather_pl_tensor <-
    weather_pl %>%
    select(-rr_type) %>%
    as_tensor(station, date)

  expect_error(
    ts_dataset(
      data = weather_pl_tensor,
      timesteps = 28,
      horizon = 7,
      predictors_spec = list(x = 2:7),
      outcomes_spec   = list(y = 1),
      scale = TRUE
    )
  )

})


test_that("Test ts_dataset jump option", {

  weather_pl_tensor <-
    weather_pl %>%
    filter(station == "TRN") %>%
    select(-station, -rr_type) %>%
    as_tensor(date)

  DS_2_JUMP <- 7

  ds_1 <-
    ts_dataset(
      data = weather_pl_tensor,
      timesteps = 28,
      horizon = 7,
      jump = 1,
      predictors_spec = list(x = 2:7),
      outcomes_spec   = list(y = 1),
      scale = TRUE
    )

  ds_2 <-
    ts_dataset(
      data = weather_pl_tensor,
      timesteps = 28,
      horizon = 7,
      jump = DS_2_JUMP,
      predictors_spec = list(x = 2:7),
      outcomes_spec   = list(y = 1),
      scale = TRUE
    )

  expected_ds_2_length <- floor(length(ds_1) / DS_2_JUMP)

  expect_equal(length(ds_2), expected_ds_2_length)
})

# TODO: add additional test to check scaling

