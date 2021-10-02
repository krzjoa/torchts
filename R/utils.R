#' RNN output size
#' @param module (nn_module) A torch `nn_module`
#' @examples
#' gru_layer <- nn_gru(15, 3)
#' rnn_output_size(gru_layer)
#' @export
rnn_output_size <- function(module){
  tail(dim(module$weight_hh_l1), 1)
}

#' Partially clear outcome variable
#' in new data by overriding with NA values
#'
#' @param data (data.frame) New data
#' @param index Date variable
#' @param outcome Outcome (target) variable
#' @param timesteps Number of timesteps used by RNN model
#' @param key A key (id) to group the data.frame (for panel data)
#'
#' @importFrom dplyr group_by
#'
#' @export
clear_outcome <- function(data, index, outcome, timesteps, key = NULL){

  index   <- as.character(substitute(index))
  outcome <- as.character(substitute(outcome))

  if (outcome[1] == "c")
    outcome <- outcome[-1]

  if (!is.null(key))
    key <- as.character(substitute(key))

  data %>%
    arrange(!!index) %>%
    group_by(!!key) %>%
    mutate(across(!!outcome, ~ c(.x[1:timesteps], rep(NA, n() - timesteps))))
}


#' An auxilliary function to call optimizer
call_optim <- function(optim, params){
  if (!rlang::is_quosure(optim))
    quosure <- rlang::enquo(optim)
  else
    quosure <- optim
  fun     <- rlang::call_fn(quosure)
  args <- c(
    list(params = params),
    rlang::call_args(quosure)
  )
  do.call({fun}, args)
}


update_dl <- function(dl, output){
  target_col <- dl$dataset$target_columns
  new_data_dl$dataset$data[.., target_col][1:30]

  new_data_dl$.index_sampler$sampler

}


#' Repeat element if it length == 1
rep_if_one_element <- function(x, output_length){
  if (length(x) == 1)
    return(rep(x), output_length)
  else
    return(x)
}


#' Check, if recursion should be used in forecasting
check_recursion <- function(object, new_data){

  # TODO: check, if this procedure is sufficient

  recursive_mode <- FALSE

  # Check, if outcome is predictor
  if (any(object$outcome %in% colnames(new_data))) {
    # Check, there are na values in predictor column
    if (any(is.na(new_data[object$outcome]))) {
      if (nrow(new_data) > object$horizon)
        recursive_mode <- TRUE
    }
  }

  recursive_mode
}

#' Remove parsnip model
#' For development purposes only
remove_model <- function(model = "rnn"){
  env <- parsnip:::get_model_env()
  model_names <- grep(model, names(env), value = TRUE)
  rm(list = model_names, envir = env)
}


vars_with_role <- function(parsed_formula, role){
  parsed_formula$.var[parsed_formula$.role == role]
}



