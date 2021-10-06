# A slice of dataset from M5 challenge

library(data.table)
library(disk.frame)
library(tsintermittent)
library(tsutils)
library(ggplot2)

# sales_long <-
#   fst::read_fst(here::here("data-dev/walmart/sales_long.fst"))
#
# sales_long <-
#   as.disk.frame(sales_long, here::here("data-dev/walmart/sales_long"))

sales_long <-
  disk.frame(here::here("data-dev/walmart/sales_long/"))

# Quick analysis to choose products
# Number of products
product_types <-
  sales_long[, .(n = n_distinct(item_id)), by = .(cat_id, dept_id)]

# Product example
sales_long[, .(unique(item_id))]

sample_product <-
  sales_long[item_id == "HOBBIES_1_001" & store_id == "CA_1"]

x <- sample_product$value
rle(x)

# View(sample_product)
# plot(ts(sample_product$value))

as.numeric(sample_product$value > 0)

adi(x)
cv2(x)

#' https://deep-and-shallow.com/2020/10/07/forecast-error-measures-intermittent-demand/
#' Helper functions
#'
adi <- function(x, ...){
  sequences <- rle(x > 0)
  n_seq <- length(sequences$values)
  non_zero_seq  <- sum(sequences$values)
  n_seq / non_zero_seq
}

#' CV²
cv2 <- function(x, ...){
  (sd(x) / mean(x)) ^ 2
}



# Intermittent sales
# https://frepple.com/blog/demand-classification/

# sales_long <-
#   sales_long %>%
#   arrange()

demand_types <-
  sales_long[, .(
    adi = adi(value),
    cv2 = cv2(value),
    trimmed_adi = adi(leadtrail(value, lead = TRUE, trail = FALSE)),
    trimmed_cv2 = cv2(leadtrail(value, lead = TRUE, trail = FALSE))
  ), by = .(item_id, store_id)]


dplot <-
  ggplot(demand_types) +
  geom_point(aes(trimmed_cv2, trimmed_adi, item_id = item_id, store_id = store_id)) +
  theme_minimal()

plotly::ggplotly(dplot)

#' Demand classification
#'
#' * Smooth demand (ADI < 1.32 and CV² < 0.49).
#' * Intermittent demand (ADI >= 1.32 and CV² < 0.49)
#' * Erratic demand (ADI < 1.32 and CV² >= 0.49)
#' * Lumpy demand (ADI >= 1.32 and CV² >= 0.49)


# "Smooth"
# FOODS_3_135 CA_3
plot(ts(sales_long[item_id == "FOODS_3_135" & store_id == "CA_3"]$value))


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
