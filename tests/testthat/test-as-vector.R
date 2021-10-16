test_that("Test as.vector.torch_tensor", {
  x <- torch_tensor(array(10, dim = c(3, 3, 3)))
  expect_equal(as.vector(x), rep(10, 27))
})
