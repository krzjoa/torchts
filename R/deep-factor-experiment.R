# Walmart data
# https://www.tensorflow.org/tutorials/structured_data/time_series
# TODO: modeling grouped time series: PR on fable!

library(data.table)
library(magrittr)
library(dplyr)
library(tsibble)
library(torch)

walmart_foods_ca1_prepared <-
  fst::read_fst("../data/walmart/walmart_foods_ca1_prepared.fst")

experiment_data <-
  walmart_foods_ca1_prepared %>%
  filter(dept_id == "FOODS_1") %>%
  select(-snap_TX, -snap_WI) %>%
  select(item_id, d, wm_yr_wk, id, dept_id, value,
         date, wday, month, year, event_name_1,
         event_type_1, event_name_2, event_type_2, snap_CA,
         sell_price)

experiment_data <-
  experiment_data %>%
  mutate(date = lubridate::as_date(date)) %>%
  mutate(across(where(is.factor), as.character))

experiment_data <-
  experiment_data %>%
  select(item_id, date,value, wday,
         month, year, snap_CA, sell_price)

experiment_data <-
  experiment_data %>%
  arrange(item_id, date)

View(head(experiment_data))

categorical_features <-
  c("wday", "month", "snap_CA")

X_tensor <-
  experiment_data %>%
  select(
    item_id, date, wday, month,
    year, snap_CA, sell_price
  ) %>%
  as_tensor(item_id, date)

y_tensor <-
  experiment_data %>%
  select(item_id, date, value) %>%
  as_tensor(item_id, date, requires_grad = FALSE) # because is not float


# Osobny embedding per cecha + konkatenacja
nn_multi_embedding


debugonce(as_tensor)


# data_tensor$shape

# Global model
# embedded <-
#   torch::nn_embedding()


