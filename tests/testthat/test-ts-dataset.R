tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

test_that("Test as_ts_dataset scaling", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(max_temp ~ date, timesteps = TIMESTEPS, h = HORIZON)

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input is scaled
  x_mean   <- mean(tarnow_temp$max_temp)
  x_std    <- sd(tarnow_temp$max_temp)
  x_scaled <- (tarnow_temp$max_temp - x_mean) / x_std

  expect_equal(as.vector(ds_slice$x), x_scaled[1:TIMESTEPS], tolerance = 1e-7)

  # Target is not scaled
  expect_equal(
    as.vector(ds_slice$y),
    tarnow_temp$max_temp[TIMESTEPS + HORIZON],
    tolerance = 1e-7
  )

})

test_that("Test as_ts_dataset without scaling", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(
      max_temp ~ date,
      timesteps = TIMESTEPS,
      h = HORIZON,
      scale = FALSE
    )

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input is scaled
  expect_equal(
    as.vector(ds_slice$x),
    tarnow_temp$max_temp[1:TIMESTEPS],
    tolerance = 1e-7
  )

  # Target is not scaled
  expect_equal(
    as.vector(ds_slice$y),
    tarnow_temp$max_temp[TIMESTEPS + HORIZON],
    tolerance = 1e-7
  )

})

test_that("Set scaling values - passing numeric", {

  TIMESTEPS <- 20
  HORIZON   <- 1
  MEAN      <- 2
  STD       <- 3

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(
      max_temp ~ date,
      timesteps = TIMESTEPS,
      h = HORIZON,
      scale = list(mean = MEAN, std = STD)
    )

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input is scaled
  x_scaled <- (tarnow_temp$max_temp - MEAN) / STD

  expect_equal(as.vector(ds_slice$x), x_scaled[1:TIMESTEPS], tolerance = 1e-7)

})


test_that("Set scaling values - passing tensors", {

  TIMESTEPS   <- 20
  HORIZON     <- 1
  MEAN        <- 2
  STD         <- 3
  MEAN_TENSOR <- as_tensor(MEAN)
  STD_TENSOR  <- as_tensor(STD)

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(
      max_temp ~ date,
      timesteps = TIMESTEPS,
      h = HORIZON,
      scale = list(mean = MEAN_TENSOR,
                   std = STD_TENSOR)
    )

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input is scaled
  x_scaled <- (tarnow_temp$max_temp - MEAN) / STD

  expect_equal(
    as.vector(ds_slice$x), x_scaled[1:TIMESTEPS], tolerance = 1e-7
  )

})

test_that("Error when index not defined", {
  expect_error(
      as_ts_dataset(
        tarnow_temp,
        max_temp ~ min_temp,
        timesteps = TIMESTEPS,
        h = HORIZON
      )
  )
})

test_that("Error when passed empty data.frame", {
  expect_error(
    as_ts_dataset(
      tarnow_temp %>% filter(date < as.Date("2001-01-01")),
      max_temp ~ min_temp,
      timesteps = TIMESTEPS,
      h = HORIZON
    )
  )
})

