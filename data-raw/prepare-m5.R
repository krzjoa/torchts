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
  #sequences <- rle(x > 0)
  #n_seq <- length(sequences$values)
  #non_zero_seq  <- sum(sequences$values)
  #n_seq / non_zero_seq
  length(x) / sum(x > 0)
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

# ADI < 1.32 and CV² < 0.49

demand_types <-
  sales_long[, .(
    adi = adi(value),
    cv2 = cv2(value),
    trimmed_adi = adi(leadtrail(value, lead = TRUE, trail = FALSE)),
    trimmed_cv2 = cv2(leadtrail(value, lead = TRUE, trail = FALSE))
  ), by = .(item_id, store_id)]

dplot2 <-
  ggplot(demand_types[startsWith(as.character(demand_types$item_id), "FOODS_1")]) +
  geom_point(aes(log(cv2), log(adi),
                 item_id = item_id, store_id = store_id)) +
  geom_hline(yintercept = log(1.32)) +
  geom_vline(xintercept = log(0.49)) +
  theme_minimal()

plotly::ggplotly(dplot2)


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

#' FOODS_1 FOODS_1_057 FOODS_1_033 FOODS_1_046 FOODS_1_218
#' FOODS_2 FOODS_2_181 FOODS_2_360 FOODS_2_096 FOODS_2_352
#' FOODS_3 FOODS_3_586 FOODS_3_702 FOODS_3_377 FOODS_3_080
#'
#' HOUSEHOLD_1 HOUSEHOLD_1_272 HOUSEHOLD_1_474 HOUSEHOLD_1_179 HOUSEHOLD_1_521
#' HOUSEHOLD_2 HOUSEHOLD_2_448 HOUSEHOLD_2_062 HOUSEHOLD_2_239 HOUSEHOLD_2_067
#'
#' HOBBIES_1 HOBBIES_1_330 HOBBIES_1_115 HOBBIES_1_254 HOBBIES_1_157
#' HOBBIES_2 HOBBIES_2_113 HOBBIES_2_015 HOBBIES_2_126 HOBBIES_2_025

# Smooth items
smooth_sales <-
  sales_long[item_id %in% c(
    "FOODS_3_586",
    "FOODS_2_181",
    "HOUSEHOLD_1_272",
    "HOBBIES_1_330",
    "FOODS_3_377",
    "FOODS_2_360",
    "FOODS_3_080"
  )]

# Intermittent
intermittent_sales <-
  sales_long[item_id %in% c(
    "HOUSEHOLD_2_448",
    "HOBBIES_2_113",
    "FOODS_1_057",
    "FOODS_1_033",
    "FOODS_2_096",
    "HOBBIES_1_157",
    "HOBBIES_2_025"
  )]

# Lumpy
lumpy_sales <-
  sales_long[item_id %in% c(
    "HOBBIES_2_015",
    "HOUSEHOLD_2_062",
    "HOBBIES_1_115",
    "FOODS_2_352",
    "HOUSEHOLD_2_239",
    "HOBBIES_2_057",
    "HOBBIES_2_126"
  )]

# Erratic
erratic_sales <-
  sales_long[item_id %in% c(
    "HOBBIES_1_254",
    "HOUSEHOLD_1_474",
    "FOODS_3_702",
    "FOODS_1_046",
    "HOUSEHOLD_1_179",
    "HOUSEHOLD_1_521",
    "FOODS_1_218"
  )]

# "Smooth"
# FOODS_3_135 CA_3
# plot(ts(sales_long[item_id == "FOODS_3_586" & store_id == "CA_3"]$value))

# HOUSEHOLD_2_062 TX_1
# plot(ts(sales_long[item_id == "HOUSEHOLD_2_062" & store_id == "TX_1"]$value))
# plot(ts(sales_long[item_id == "HOUSEHOLD_2_062" & store_id == "CA_3"]$value))

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
    intermittent_sales,
    lumpy_sales,
    erratic_sales
  ) %>%
  select(-id) %>%
  mutate(across(where(is.factor), as.character))

tiny_m5 <-
  selected_sales  %>%
  left_join(calendar, by = c("d", "state_id")) %>%
  left_join(prices, by = c("store_id", "item_id", "wm_yr_wk")) %>%
  select(-d)

tiny_m5 <-
  tiny_m5 %>%
  select(item_id, dept_id, cat_id, store_id, state_id, date, value, everything())

# head(tiny_m5)
# setDT(tiny_m5)
# tiny_m5[, .(n_items = n_distinct(item_id)), by = store_id]

save(tiny_m5, file = here::here("data/tiny_m5.rda"))

