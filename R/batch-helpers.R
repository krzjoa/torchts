#' Training helper
train_batch <- function(input, target,
                        net, optimizer, loss_fun = nnf_mse_loss) {

  optimizer$zero_grad()
  output <- net(input)

  loss <- loss_fun(output, target)
  loss$backward()
  optimizer$step()

  loss$item()
}

#' Validation helper function
valid_batch <- function(net, input, target, loss_fun = nnf_mse_loss) {
  output <- net(input)
  loss <- loss_fun(output, target)
  loss$item()

}




