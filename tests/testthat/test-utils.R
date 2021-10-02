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
