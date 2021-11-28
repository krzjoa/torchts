test_that("Nonlinear module simple test", {

  net <- nn_nonlinear(10, 1)
  x   <- torch_tensor(matrix(1, nrow = 2, ncol = 10))
  out <- net(x)

  expect_equal(dim(out), c(2, 1))
})
