#' Prepare dataloders
#'
#' @inheritParams as_ts_dataset
#' @inheritParams rnn_fit
#'
prepare_dl <- function(data, formula, index,
                       timesteps, horizon,
                       categorical = NULL,
                       validation = NULL,
                       scale = TRUE, batch_size,
                       parsed_formula = NULL, ...){

  # TODO: use predictors, outcomes instead of parsing formula second time
  valid_dl <- NULL

  if (!is.null(validation)) {

    if(is.numeric(validation)) {

      train_len  <- floor(nrow(data) * (1 - validation))
      assess_len <- nrow(data) - train_len

      validation <-
        data %>%
        arrange(!!index) %>%
        tail(timesteps + assess_len)

      data <-
        data %>%
        arrange(!!index) %>%
        head(train_len)

      # data_split <-
      #   timetk::time_series_split(
      #     data     = data,
      #     date_var = !!index,
      #     lag      = timesteps,
      #     initial  = train_len,
      #     assess   = assess_len
      #   )

      # data       <- rsample::training(data_split)
      # validation <- rsample::testing(data_split)
    }

    valid_dl <-
      as_ts_dataloader(
        data           = validation,
        formula        = formula,
        timesteps      = timesteps,
        horizon        = horizon,
        categorical    = categorical,
        scale          = scale,
        batch_size     = batch_size,
        parsed_formula = parsed_formula
      )

  }

  train_dl <-
    as_ts_dataloader(
      data           = data,
      formula        = formula,
      timesteps      = timesteps,
      horizon        = horizon,
      categorical    = categorical,
      scale          = scale,
      batch_size     = batch_size,
      parsed_formula = parsed_formula
    )

  list(
    train_dl = train_dl,
    valid_dl = valid_dl
  )
}


prepare_categorical <- function(data, categorical){

  if (nrow(categorical) > 0) {

    embedded_vars  <- dict_size(data[categorical$.var])
    embedding_size <- embedding_size_google(embedded_vars)

    embedding<-
      embedding_spec(
        num_embeddings = embedded_vars,
        embedding_dim  = embedding_size
      )

  } else {
    embedding <- NULL
  }

  embedding
}

