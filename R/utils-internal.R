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
    return(rep(x, output_length))
  else
    return(x)
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

filter_vars <- function(parsed_formula, role = NULL, class = NULL){
  parsed_formula$.var[
    parsed_formula$.role == role &
      parsed_formula$.class == c
  ]
}


listed <- function(x){
  # Add truncate option
  paste0(x, collapse = ", ")
}

all_the_same <- function(x){
  all(x == x[1])
}

#' https://stackoverflow.com/questions/26083625/how-do-you-include-data-frame-output-inside-warnings-and-errors
print_and_capture <- function(x){
  paste(capture.output(print(x)), collapse = "\n")
}
