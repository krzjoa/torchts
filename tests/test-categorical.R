
test_that("Test is_categorical", {

  char_vector <- c("Ferrari", "Lamborghini", "Porsche", "McLaren", "Koenigsegg")

  # TRUE
  expect_true(is_categorical(c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE)))
  expect_true(is_categorical(1:10))
  expect_true(is_categorical(char_vector))
  expect_true(is_categorical(as.factor(char_vector)))

  # FALSE
  expect_false(is_categorical((1:10) + 0.1))
  expect_false(
    withr::with_options(
      list(torchts_categoricals = "factor"), {
      is_categorical(char_vector)
    })
  )


})
