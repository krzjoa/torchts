library(dplyr)

test_that("Dataloader basic test", {
  library(rsample)

  suwalki_temp <-
     weather_pl %>%
     filter(station == "SWK") %>%
     select(date, temp = tmax_daily)

  # Splitting on training and test
  data_split <-
    initial_time_split(suwalki_temp)

  train_ds <-
    training(data_split) %>%
    as_ts_dataloader(temp ~ date, timesteps = 20, horizon = 1, batch_size = 32)

  batch <-
    dataloader_next(dataloader_make_iter(train_ds))

  expect_equal(dim(batch$x_num), c(32, 20, 1))
  expect_equal(dim(batch$y), c(32, 1))

})


test_that("Dataloader - categorical variables", {

  library(rsample)

  suwalki_temp <-
    weather_pl %>%
    filter(station == "SWK") %>%
    select(date, temp = tmax_daily, rr_type)

  # Splitting on training and test
  data_split <-
    initial_time_split(suwalki_temp)

  train_ds <-
    training(data_split) %>%
    as_ts_dataloader(temp ~ date + temp + rr_type,
                     timesteps = 20, horizon = 1, batch_size = 32)

  batch <-
    dataloader_next(dataloader_make_iter(train_ds))

  # Sizes
  expect_equal(dim(batch$x_num), c(32, 20, 1))
  expect_equal(dim(batch$x_cat), c(32, 20, 1))
  expect_equal(dim(batch$y), c(32, 1))

  # Types
  expect_equal(batch$x_num$dtype, torch_float())
  expect_equal(batch$x_cat$dtype, torch_int())
  expect_equal(batch$y$dtype, torch_float())

})

# TODO: add further unit tests
