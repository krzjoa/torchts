test_that("Test check_is_complete", {
  expect_error(check_is_complete(weather_pl))
  expect_equal(check_is_complete(mtcars), NULL)
})
