library(dplyr)

tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

test_that("Test simple formula with explicit index", {

  output <-
    torchts_parse_formula(max_temp ~ max_temp + index(date), tarnow_temp)

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
    "date", "index", "Date",
    "max_temp", "predictor", "numeric"
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


test_that("Test formula, where outcome is not an input variable as well", {

  output <-
    torchts_parse_formula(min_temp ~ max_temp + index(date), tarnow_temp)

  expected <- tribble(
    ~ .var, ~ .role, ~ .type,
    "min_temp", "outcome", "numeric",
    "max_temp", "predictor", "numeric",
    "date", "index", "Date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula without explit predictors", {

  output <-
    torchts_parse_formula(max_temp + min_temp ~ date, tarnow_temp)

  expected <- tribble(
    ~ .var, ~ .role, ~ .type,
    "max_temp", "outcome", "numeric",
    "min_temp", "outcome", "numeric",
    "date", "index", "Date",
    "max_temp", "predictor", "numeric",
    "min_temp", "predictor", "numeric"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


# test_that("Test formula with multiple predictors and outcomes where index is first", {
#
#   output <-
#     torchts_parse_formula(
#       min_temp + max_temp ~ index(date) + min_temp + max_temp, tarnow_temp
#     )
#
#
#   torchts_parse_formula(
#     min_temp + max_temp ~ min_temp + max_temp + , tarnow_temp
#   )
#
#   expected <- tribble(
#     ~ .var, ~ .role, ~ .type,
#     "max_temp", "outcome", "numeric",
#     "min_temp", "outcome", "numeric",
#     "date", "index", "Date",
#     "max_temp", "predictor", "numeric",
#     "min_temp", "predictor", "numeric"
#   )
#
#   class(expected$.role) <- "list"
#
#   expect_equal(expected, output)
# })



