tarnow_temp <-
  weather_pl %>%
  filter(station == "TARNÓW") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

test_that("Test as_ts_dataset scaling", {
  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(max_temp ~ date)

  tarnow_ds <-
    tarnow_temp %>%
    as_ts_dataset(max_temp ~ min_temp)

  tarnow_ds[1]

  tarnow_dl <- torch::dataloader(tarnow_ds, batch_size = 32)
  dataloader_next(tarnow_dl)



  tarnow_ds$std

})
