# A slice of dataset from M5 challenge

library(data.table)
library(disk.frame)

sales_long <-
  fst::read_fst(here::here("data-dev/walmart/sales_long.fst"))

sales_long <-
  as.disk.frame(sales_long, here::here("data-dev/walmart/sales_long"))

# Quick analysis to choose products
# Number of products
product_types <-
  sales_long[, .(n = n_distinct(item_id)), by = .(cat_id, dept_id)]

# Intermittent sales
# https://frepple.com/blog/demand-classification/
adi <- function()


setDT(sales_long)


sample_ids <-
  walmart_foods_ca1_prepared$item_id %>%
  sample(10)

small_walmart <-
  walmart_foods_ca1_prepared %>%
  filter(item_id %in% sample_ids)

save(small_walmart, file = here::here("data/m5.rda"))


format(object.size(small_walmart), units = "MB")
format(object.size(), units = "MB")
