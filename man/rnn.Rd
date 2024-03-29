% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rnn-parsnip.R
\name{rnn}
\alias{rnn}
\title{General interface to recurrent neural network models}
\usage{
rnn(
  mode = "regression",
  timesteps = NULL,
  horizon = 1,
  learn_rate = 0.01,
  epochs = 50,
  hidden_units = NULL,
  dropout = NULL,
  batch_size = 32,
  shuffle = FALSE,
  jump = 1,
  sample_frac = 1
)
}
\arguments{
\item{mode}{(\code{character}) Model mode, default: 'regression'.}

\item{timesteps}{(\code{integer}) Number of timesteps to look back.}

\item{horizon}{(\code{integer}) Forecast horizon.}

\item{learn_rate}{(\code{numeric} or \code{\link[dials:learn_rate]{dials::learn_rate}}) Learning rate.}

\item{epochs}{(\code{integer} or \code{\link[dials:dropout]{dials::epochs}}) Number of epochs.}

\item{hidden_units}{(\code{integer}) Number of hidden units.}

\item{dropout}{(\code{logical} or \code{\link[dials:dropout]{dials::dropout}}) Flag to use dropout.}

\item{batch_size}{(\code{integer}) Batch size.}

\item{shuffle}{(\code{logical}) Shuffle examples during the training (default: FALSE).}

\item{jump}{(\code{integer}) Input window shift.}

\item{sample_frac}{(\code{numeric}) A percent of subsamples used for training.}

\item{scale}{(\code{logical}) Scale input features.}
}
\description{
General interface to recurrent neural network models
}
\details{
This is a \code{parsnip} API to the recurent network models. For now the only
available engine is \code{torchts_rnn}.
}
\section{Categorical features}{

Categorical features are detected automatically - if a column of your input data (defined in the formula)
is \code{logical}, \code{character}, \code{factor} or \code{integer}.
}

\section{Empty model}{

Neural networks, unlike many other models (e.g. linear models) can return values
before any training epoch ended. It's because every neural networks model starts with
"random" parameters, which are gradually tuned in the following iterations according to the
Gradient Descent algorithm.

If you'd like to get a non-trained model, simply set \code{epochs = 0}.
You still have to "fit" the model to stick the standard \code{parsnip}'s API procedure.
}

\examples{
library(torchts)
library(parsnip)
library(dplyr, warn.conflicts = FALSE)
library(rsample)

# Univariate time series
tarnow_temp <-
 weather_pl \%>\%
 filter(station == "TARNÓW") \%>\%
 select(date, temp = tmax_daily)

data_split <- initial_time_split(tarnow_temp)

rnn_model <-
   rnn(
     timesteps = 20,
     horizon = 1,
     epochs = 10,
     hidden_units = 32
   )

rnn_model <-
   rnn_model \%>\%
   fit(temp ~ date, data = training(data_split))


}
