tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

tarnow_temp_full <-
  weather_pl %>%
  filter(station == "TRN") %>%
  rename(max_temp = tmax_daily, min_temp = tmin_daily)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                             SELECTED VARIABLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("Test as_ts_dataset", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(
      max_temp ~ date,
      timesteps = TIMESTEPS,
      horizon = HORIZON,
      scale = FALSE
    )

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input
  expect_equal(
    as.vector(ds_slice$x_num),
    tarnow_temp$max_temp[1:TIMESTEPS],
    tolerance = 1e-7
  )

  # Target
  expect_equal(
    as.vector(ds_slice$y),
    tarnow_temp$max_temp[TIMESTEPS + HORIZON],
    tolerance = 1e-7
  )

})


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                             ALL THE VARIABLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("Test as_ts_dataset (all vars)", {

  TIMESTEPS <- 20
  HORIZON   <- 1

  tarnow_ds <-
    tarnow_temp_full %>%
    as_ts_dataset(
      max_temp ~ date,
      timesteps = TIMESTEPS,
      horizon = HORIZON,
      scale = FALSE
    )

  # First slice
  ds_slice <- tarnow_ds[1]

  # Input is scaled
  expect_equal(
    as.vector(ds_slice$x_num),
    tarnow_temp_full$max_temp[1:TIMESTEPS],
    tolerance = 1e-7
  )

  # Target is not scaled
  expect_equal(
    as.vector(ds_slice$y),
    tarnow_temp_full$max_temp[TIMESTEPS + HORIZON],
    tolerance = 1e-7
  )

})

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                 ERRORS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("Error when index not defined", {
  expect_error(
      as_ts_dataset(
        tarnow_temp,
        max_temp ~ min_temp,
        timesteps = TIMESTEPS,
        horizon = HORIZON
      )
  )
})

test_that("Error when passed empty data.frame", {
  expect_error(
    as_ts_dataset(
      tarnow_temp %>% filter(date < as.Date("2001-01-01")),
      max_temp ~ min_temp,
      timesteps = TIMESTEPS,
      horizon = HORIZON
    )
  )
})

test_that("Error when passed a data.frame with non-numeric values (for now)", {

  tarnow_temp_non_numeric <-
    weather_pl %>%
    filter(station == "TRN")

  expect_error(
    as_ts_dataset(
      tarnow_temp_non_numeric,
      max_temp ~ min_temp,
      timesteps = TIMESTEPS,
      horizon = HORIZON
    )
  )

})

