torchts_predict <- function(object, new_data, ...){
  # WARNING: Cannot be used parallely for now

  # For now we suppose it's continuous
  # TODO: Check more conditions
  # TODO: keys!!!


  n_outcomes <- length(object$outcomes)
  batch_size <- 1

  # Checks
  check_length_vs_horizon(object, new_data)
  check_is_new_data_complete(object, new_data)
  recursive_mode <- check_recursion(object, new_data)

  # Preparing dataloader
  new_data_dl <-
    as_ts_dataloader(
      new_data,
      timesteps      = object$timesteps,
      horizon        = object$horizon,
      batch_size     = batch_size,
      jump           = object$horizon,
      # Extras
      parsed_formula = object$parsed_formula,
      cat_recipe     = object$extras$cat_recipe,
      shuffle        = FALSE,
      drop_last      = FALSE
    )

  net <- object$net

  if (!is.null(object$device)) {
    net         <- set_device(net, object$device)
    new_data_dl <- set_device(new_data_dl, object$device)
  }

  net$eval()

  output_shape <-
    c(length(new_data_dl$dataset), object$horizon, length(object$outcomes))

  preds <- array(0, dim = output_shape)
  iter  <- 0

  # b <- dataloader_next(dataloader_make_iter(new_data_dl))

  coro::loop(for (b in new_data_dl) {

    output <- do.call(net, get_x(b))
    preds[iter+1,,] <- as_array(output$cpu())

    if (recursive_mode) {
      start <- object$timesteps + iter * object$horizon + 1
      end   <- object$timesteps + iter * object$horizon + object$horizon
      cols  <- unlist(new_data_dl$dataset$outcomes_spec)

      if (length(cols) == 1)
        output <- output$reshape(nrow(output))

      # TODO: insert do dataset even after last forecast for consistency?
      if (dim(new_data_dl$dataset$data[start:end, mget(object$outcomes)]) == dim(output))
        new_data_dl$dataset$data[start:end, mget(object$outcomes)] <- output
    }

    iter <- iter + 1

  })

  # Make sure that forecast has right length
  preds <-
    preds %>%
    aperm(c(2, 1, 3)) %>%
    array(dim = c(output_shape[1] * output_shape[2], output_shape[3]))

  # Adding colnames if more than one outcome
  if (ncol(preds) > 1)
    colnames(preds) <- object$outcomes
  else
    colnames(preds) <- ".pred"

  # browser()

  # Cutting if longer than expected
  preds <- as_tibble(preds)
  preds <- head(preds, nrow(new_data) - object$timesteps)
  preds <- preprend_empty(preds, object$timesteps)

  preds
}
