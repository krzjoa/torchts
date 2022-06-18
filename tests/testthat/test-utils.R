tarnow_temp <-
  weather_pl %>%
  filter(station == "TRN") %>%
  select(date, tmax_daily, tmin_daily)

test_that("Test vars_with_role", {

  parsed_formula_1 <-
    torchts_parse_formula(tmax_daily + tmin_daily ~ date, tarnow_temp)

  expect_equal(
    vars_with_role(parsed_formula_1, "predictor"),
    c("tmax_daily", "tmin_daily")
  )

  expect_equal(
    vars_with_role(parsed_formula_1, "outcome"),
    c("tmax_daily", "tmin_daily")
  )

  expect_equal(
    vars_with_role(parsed_formula_1, "index"),
    c("date")
  )

})


test_that("Test empty_rows", {

  EMPTY <- 5

  iris_with_empty_rows <- preprend_empty(iris, EMPTY)

  expect_equal(
    nrow(iris_with_empty_rows),
    nrow(iris) + EMPTY
  )

  expect_true(all(is.na(
    iris_with_empty_rows[1:EMPTY, ]
  )))

  expect_false(all(is.na(
    iris_with_empty_rows[1:(2 * EMPTY), ]
  )))

})

