# A slice of dataset from M5 challenge

library(data.table)
library(disk.frame)
library(tsintermittent)
library(tsutils)
library(ggplot2)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                  LOADING DATA                                #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


# sales_long <-
#   fst::read_fst(here::here("data-dev/walmart/sales_long.fst"))
#
# sales_long <-
#   as.disk.frame(sales_long, here::here("data-dev/walmart/sales_long"))

sales_long <-
  disk.frame(here::here("data-dev/walmart/sales_long/"))

calendar <-
  fst::read_fst(here::here("data-dev/walmart/calendar.fst"))

prices <-
  fst::read_fst(here::here("data-dev/walmart/prices.fst"))

# Quick analysis to choose products
# Number of products
product_types <-
  sales_long[, .(n = n_distinct(item_id)), by = .(cat_id, dept_id)]

# HOBBIES_1, HOBBIES_2, HOBBIES_3
# FOODS_1, FOODS_2, FOODS_3
# HOUSEHOLD_1, HOUSEHOLD_2, HOUSEHOLD_3

# Product example
# sales_long[, .(unique(item_id))]
#
# sample_product <-
#   sales_long[item_id == "HOBBIES_1_001" & store_id == "CA_1"]
#
# x <- sample_product$value
# rle(x)

# View(sample_product)
# plot(ts(sample_product$value))

# as.numeric(sample_product$value > 0)

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
  x <- x[x > 0]
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
  geom_point(aes(trimmed_cv2, trimmed_adi,
                 item_id = item_id, store_id = store_id)) +
  theme_minimal()

plotly::ggplotly(dplot)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                             CLASSIFYING SALES                                #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

#' Demand classification
#'
#' * Smooth demand (ADI < 1.32 and CV² < 0.49).
#' * Intermittent demand (ADI >= 1.32 and CV² < 0.49)
#' * Erratic demand (ADI < 1.32 and CV² >= 0.49)
#' * Lumpy demand (ADI >= 1.32 and CV² >= 0.49)

# Sorting
# Smooth adi, cv2
# Intermittent desc(adi), cv2
# erratic adi, desc(cv2)
# lumpy desc(adi), desc(cv2)

View(arrange(demand_types, trimmed_adi, trimmed_cv2), "Smooth")
View(arrange(demand_types, desc(trimmed_adi), trimmed_cv2), "Intermittent")
View(arrange(demand_types, desc(trimmed_cv2), trimmed_adi), "Erratic")
View(arrange(demand_types, desc(trimmed_adi), desc(trimmed_cv2)), "Lumpy")

# Smooth items
smooth_sales <-
  sales_long[item_id %in% c(
    "FOODS_3_586",
    "HOUSEHOLD_1_441",
    "HOBBIES_1_158"
  )]

# Lumpy
lumpy_sales <-
  sales_long[item_id %in% c(
    "HOUSEHOLD_2_062",
    "FOODS_1_206",
    "FOODS_2_105"
  )]

# "Smooth"
# FOODS_3_135 CA_3
plot(ts(sales_long[item_id == "HOUSEHOLD_1_141" & store_id == "CA_3"]$value))

# HOUSEHOLD_2_062 TX_1
plot(ts(sales_long[item_id == "HOUSEHOLD_2_062" & store_id == "TX_1"]$value))
plot(ts(sales_long[item_id == "HOUSEHOLD_2_062" & store_id == "CA_3"]$value))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                              PREPARE CALENDAR                                #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

calendar <-
  calendar %>%
  mutate(date = lubridate::as_date(date)) %>%
  tidyr::pivot_longer(starts_with("snap")) %>%
  rename(state_id = name,  snap = value) %>%
  mutate(across(where(is.factor), as.character)) %>%
  mutate(state_id = stringi::stri_sub(state_id, 6))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                PREPARE SALES                                 #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

selected_sales <-
  bind_rows(
    smooth_sales,
    lumpy_sales
  ) %>%
  select(-id) %>%
  mutate(across(where(is.factor), as.character))

tiny_m5 <-
  selected_sales  %>%
  left_join(calendar, by = c("d", "state_id")) %>%
  left_join(prices, by = c("store_id", "item_id", "wm_yr_wk")) %>%
  select(-d)

# format(object.size(tiny_m5), units = "MB")

save(tiny_m5, file = here::here("data/tiny_m5.rda"))
