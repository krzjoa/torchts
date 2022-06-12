library(torch)
library(dplyr)

test_that("torch_tensor passed to as_torch_tensor with no arguments", {
  x <- torch_tensor(rep(3, 10))
  y <- as_torch_tensor(x)
  expect_identical(x, y)
})

test_that("Simple data.frame transformation", {
  x <- as_torch_tensor(mtcars)
  expect_equal(dim(x), dim(mtcars))
})

test_that("data.frame reshaped with non-numeric columns", {

  weather_tensor <-
    weather_pl %>%
    select(-rr_type) %>%
    as_torch_tensor(station, date)

  expected_shape <-
    c(
      n_distinct(weather_pl$station),
      n_distinct(weather_pl$date),
      length(colnames(weather_pl)) - 3 # station, date and removed rr_type
    )

  expect_equal(
    dim(weather_tensor), expected_shape
  )

})

test_that("data.frame with a non-numeric colum: raises error", {
  expect_error(as_torch_tensor(weather_pl))
})


test_that("Check data order after reshaping", {

  # TODO: add tests for more than 3 shapes

  temperature_pl <-
    weather_pl %>%
    select(station, date, tmax_daily)

  temperature_tensor <-
    temperature_pl %>%
    as_torch_tensor(station, date)

  result <-
   temperature_tensor[1, 1:10] %>%
   as.vector()

  expected <-
    temperature_pl %>%
      filter(station == "SWK") %>%
      arrange(date) %>%
      head(10) %>%
      pull()

  expect_equal(result, expected, tolerance=1e-7)
})


