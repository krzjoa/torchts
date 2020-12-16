# Walmart data
# https://www.tensorflow.org/tutorials/structured_data/time_series
# TODO: modeling grouped time series: PR on fable!

# library(data.table)
# library(magrittr)
# library(dplyr)
# library(tsibble)
#
# # walmart_foods_ca1_prepared <-
# #   walmart_foods_ca1 %>%
# #   merge(calendar, by = "d") %>%
# #   merge(prices, by = c("store_id", "item_id", "wm_yr_wk"))
#
# # walmart_foods_ca1_prepared <-
# #   walmart_foods_ca1_prepared %>%
# #   select(-snap_TX, -snap_WI)
#
# walmart_foods_ca1_prepared <-
#   fst::read_fst("../data/walmart/walmart_foods_ca1_prepared.fst")
#
# experiment_data <-
#   walmart_foods_ca1_prepared %>%
#   select(-snap_TX, -snap_WI) %>%
#   select(item_id, d, wm_yr_wk, id, dept_id, value,
#          date, wday, month, year, event_name_1,
#          event_type_1, event_name_2, event_type_2, snap_CA,
#          sell_price)
#
# experiment_data <-
#   experiment_data %>%
#   mutate(date = lubridate::as_date(date)) %>%
#   mutate(across(where(is.factor), as.character))
#
# # experiment_data <-
# #   experiment_data %>%
# #   as_tsibble(key = id, index = date)
#
#
# experiment_data <-
#   as_tibble(experiment_data)
#
# experiment_data <-
#   experiment_data %>%
#   select(item_id, date,value, wday, month, year, snap_CA, sell_price)
#
# experiment_data <-
#   experiment_data %>%
#   arrange(item_id, date)
#
# exp_data <-
#   experiment_data %>%
#   filter(item_id %in% c("FOODS_1_001", "FOODS_1_002")) %>%
#   select(item_id, date, value, wday, month, year, snap_CA, sell_price)
#
# experiment_data %>%
#   filter(item_id %in% c("FOODS_1_001", "FOODS_1_002")) %>%
#   arrange(item_id, date) %>%
#   select(value, wday, month, year, snap_CA, sell_price) %>%
#   array(dim = c(2, 1913, 6))
#
#
#   #as.matrix() %>%
#   #as.vector() %>%
#   torch::torch_tensor()
#   #array(1437, 1913, 6)
#
#
#
# as_tensor(exp_data, item_id, date)


# Functions for preparing data for training

# experiment_data <-
#   experiment_data %>%
#   group_by(dept_id)
#
# experiment_data %>%
#   model(deep_factor = fbl_deep_factor(value ~ .))


# experiment_data %>%
#   filter(is.na(value)) %>%
#   View


