library(dplyr)

tarnow_temp <-
  weather_pl %>%
  filter(station == "TARNÓW") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

test_that("Test simple formula with explicit index", {

  output <-
    torchts_parse_formula(max_temp ~ max_temp +index(date), tarnow_temp)

  expected <- tribble(
    ~ .var, ~ .role, ~ .type,
    "max_temp", "outcome", "numeric",
    "max_temp", "predictor", "numeric",
    "date", "index", "Date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test simple formula", {

  output <-
    torchts_parse_formula(max_temp ~ date, tarnow_temp)

  expected <- tribble(
    ~ .var, ~ .role, ~ .type,
    "max_temp", "outcome", "numeric",
    "max_temp", "predictor", "numeric",
    "date", "index", "Date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula with two outcome variables", {

  output <-
    torchts_parse_formula(max_temp + min_temp ~ max_temp + index(date), tarnow_temp)

  expected <- tribble(
    ~ .var, ~ .role, ~ .type,
    "max_temp", "outcome", "numeric",
    "min_temp", "outcome", "numeric",
    "max_temp", "predictor", "numeric",
    "date", "index", "Date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})

