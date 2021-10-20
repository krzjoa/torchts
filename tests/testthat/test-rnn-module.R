test_that("Basic RNN test", {

  # Preparing data
  weather_dl <-
    weather_pl %>%
    filter(station == "TRN") %>%
    select(date, tmax_daily) %>%
    as_ts_dataloader(
      tmax_daily ~ date,
      timesteps = 30,
      batch_size = 32
    )

  # Creating a model
  rnn_net <-
    model_rnn(
      input_size  = 1,
      output_size = 1,
      hidden_size = 10
    )

  expect_equal(
    class(rnn_net), c("model_rnn", "nn_module")
  )

  # Prediction example on non-trained neural network
  batch <-
    dataloader_next(dataloader_make_iter(weather_dl))

  output <- rnn_net(batch$x)

  expect_equal(dim(output), c(32, 1, 1))

})
