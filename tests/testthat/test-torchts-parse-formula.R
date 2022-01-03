library(dplyr)

tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, max_temp = tmax_daily, min_temp = tmin_daily)

test_that("Test simple formula", {

  output <-
    torchts_parse_formula(max_temp ~ date, tarnow_temp)

  expected <- tribble(
   ~ .var, ~ .role, ~ .class, ~ .type,
    "max_temp", "outcome", "numeric", "numeric",
    "date", "index", "Date", "date",
    "max_temp", "predictor", "numeric", "numeric"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula with two outcome variables", {

  output <-
    torchts_parse_formula(max_temp + min_temp ~ max_temp + date, tarnow_temp)

  expected <- tribble(
   ~ .var, ~ .role, ~ .class, ~ .type,
    "max_temp", "outcome", "numeric", "numeric",
    "min_temp", "outcome", "numeric", "numeric",
    "max_temp", "predictor", "numeric", "numeric",
    "date", "index", "Date", "date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula, where outcome is not an input variable as well", {

  output <-
    torchts_parse_formula(min_temp ~ max_temp + date, tarnow_temp)

  expected <- tribble(
   ~ .var, ~ .role, ~ .class, ~ .type,
    "min_temp", "outcome", "numeric", "numeric",
    "max_temp", "predictor", "numeric", "numeric",
    "date", "index", "Date", "date"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula without explicit predictors", {

  output <-
    torchts_parse_formula(max_temp + min_temp ~ date, tarnow_temp)

  expected <- tribble(
   ~ .var, ~ .role, ~ .class, ~ .type,
    "max_temp", "outcome", "numeric", "numeric",
    "min_temp", "outcome", "numeric", "numeric",
    "date", "index", "Date", "date",
    "max_temp", "predictor", "numeric", "numeric",
    "min_temp", "predictor", "numeric", "numeric"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})

test_that("Formula outcome variables order", {

  parsed_formula_1 <-
    torchts_parse_formula(max_temp + min_temp ~ date, tarnow_temp)

  outcome_1 <- filter(parsed_formula_1, .role == "outcome")$.var

  expect_equal(outcome_1, c("max_temp", "min_temp"))


  parsed_formula_2 <-
    torchts_parse_formula(min_temp + max_temp ~ date, tarnow_temp)

  outcome_2 <- filter(parsed_formula_2, .role == "outcome")$.var

  expect_equal(outcome_2, c("min_temp", "max_temp"))

})

test_that("Variables that not appear in the data.frame", {

  expect_error(
    torchts_parse_formula(max_temp + min_temperature ~ date, tarnow_temp)
  )

})


test_that("Test formula with multiple predictors and outcomes where index is first", {

  output <-
    torchts_parse_formula(
      min_temp + max_temp ~ date + min_temp + max_temp,
      tarnow_temp
    )

  expected <- tribble(
   ~ .var, ~ .role, ~ .class, ~ .type,
    "min_temp", "outcome", "numeric", "numeric",
    "max_temp", "outcome", "numeric", "numeric",
    "date", "index", "Date", "date",
    "min_temp", "predictor", "numeric", "numeric",
    "max_temp", "predictor", "numeric", "numeric"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})


test_that("Test formula with a modifier", {

  output <-
    torchts_parse_formula(
      min_temp ~ date + min_temp + max_temp + lead(max_temp, 5),
      tarnow_temp
    )

  expected <- tribble(
    ~ .var, ~ .role, ~ .modifier, ~ .class, ~ .type,
    "min_temp", "outcome", NA, "numeric", "numeric",
    "date", "index", NA, "Date", "date",
    "min_temp", "predictor", NA, "numeric", "numeric",
    "max_temp", "predictor", NA, "numeric", "numeric",
    "max_temp", "predictor", "lead(5)", "numeric", "numeric"
  )

  class(expected$.role) <- "list"

  expect_equal(expected, output)
})




