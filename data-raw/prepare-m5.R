# A slice of dataset from M5 challenge

sample_ids <-
  walmart_foods_ca1_prepared$item_id %>%
  sample(10)

small_walmart <-
  walmart_foods_ca1_prepared %>%
  filter(item_id %in% sample_ids)

save(small_walmart, file = here::here("data/m5.rda"))


format(object.size(small_walmart), units = "MB")
format(object.size(), units = "MB")
