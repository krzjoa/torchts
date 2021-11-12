#' Training helper
train_batch <- function(input, target,
                        net, optimizer,
                        loss_fun = nnf_mse_loss) {

  optimizer$zero_grad()
  output <- do.call(net, input)

  loss <- loss_fun(output, target$y)
  loss$backward()
  optimizer$step()

  loss$item()
}

#' Validation helper function
valid_batch <- function(net, input, target,
                        loss_fun = nnf_mse_loss) {
  output <- do.call(net, input)
  loss <- loss_fun(output, target$y)
  loss$item()

}


#' Fit a neural network
fit_network <- function(net, train_dl, valid_dl = NULL, epochs,
                        optimizer, loss_fn){


  # Info in Keras
  # 938/938 [==============================] - 1s 1ms/step - loss: 0.0563 - acc: 0.9829 - val_loss: 0.1041 - val_acc: 0.9692

  for (epoch in seq_len(epochs)) {

    net$train()
    train_loss <- c()

    # b <- dataloader_next(dataloader_make_iter(train_dl))

    coro::loop(for (b in train_dl) {
      loss <- train_batch(
        input     = get_x(b),
        target    = get_y(b),
        net       = net,
        optimizer = optimizer,
        loss_fun  = loss_fn
      )
      train_loss <- c(train_loss, loss)
    })

    valid_loss_info <- ""

    if (!is.null(valid_dl)) {

      net$eval()
      valid_loss <- c()

      coro::loop(for (b in valid_dl) {
        loss <- valid_batch(b)
        valid_loss <- c(valid_loss, loss)
      })

      valid_loss_info <- sprintf("validation: %3.5f", mean(valid_loss))
    }

    cat(sprintf(
      "\nEpoch %d/%d | training: %3.5f %s \n",
      epoch, epochs, mean(train_loss), valid_loss_info
    ))
  }

  net
}

#' batch <- list(x_num = "aaa", x_cat = "bbb", y = "c")
#' get_x(batch)
get_x <- function(batch){
  batch[startsWith(names(batch), "x")]
}

get_y <- function(batch){
  batch[startsWith(names(batch), "y")]
}



