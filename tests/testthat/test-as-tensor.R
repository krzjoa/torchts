library(torch)
library(dplyr)

test_that("torch_tensor passed to as_tensor with no arguments", {
  x <- torch_tensor(rep(3, 10))
  y <- as_tensor(x)
  expect_identical(x, y)
})

test_that("Simple data.frame transformation", {
  x <- as_tensor(mtcars)
  expect_equal(dim(x), dim(mtcars))
})

test_that("data.frame reshaped with non-numeric columns", {

  weather_tensor <-
    weather_pl %>%
    select(-rr_type) %>%
    as_tensor(station, date)

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
  expect_error(as_tensor(weather_pl))
})



