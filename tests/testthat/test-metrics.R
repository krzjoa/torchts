
test_that("MAPE", {

  target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
  target <- as_torch_tensor(target)

  input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27., 70.96)
  input <- as_torch_tensor(input)

  expect_equal(
    as.vector(nnf_mape(input, target)),
    0.2372984,
    tolerance = 1e-7
  )

})

test_that("MAE", {

  target <- c(91.54, 5.87, 58.85, 10.73, 81.47, 75.39, 2.05, 40.95, 27.34, 66.61)
  target <- as_torch_tensor(target)

  input <- c(92, 6.5, 57.69, 15.9, 88.47, 75.01, 5.06, 45.95, 27.8, 70.96)
  input <- as_torch_tensor(input)

  expect_equal(
    nnf_mae(input, target),
    as_torch_tensor(2.762),
    tolerance = 1e-10
  )

})
