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

  expect_equal(dim(batch$x), c(32, 20, 1))
  expect_equal(dim(batch$y), c(32, 1))

})

# TODO: add further unit tests
