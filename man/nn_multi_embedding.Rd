% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nn-multi-embedding.R
\name{nn_multi_embedding}
\alias{nn_multi_embedding}
\title{Create multiple embeddings at once}
\usage{
nn_multi_embedding(
  num_embeddings,
  embedding_dim,
  padding_idx = NULL,
  max_norm = NULL,
  norm_type = 2,
  scale_grad_by_freq = FALSE,
  sparse = FALSE,
  .weight = NULL
)
}
\arguments{
\item{num_embeddings}{(\code{integer}) Size of the dictionary of embeddings.}

\item{embedding_dim}{(\code{integer}) The size of each embedding vector.}

\item{padding_idx}{(\code{integer}, optional) If given, pads the output with
the embedding vector at \code{padding_idx} (initialized to zeros) whenever it encounters the index.}

\item{max_norm}{(\code{numeric}, optional) If given, each embedding vector with norm larger
than max_norm is renormalized to have norm max_norm.}

\item{norm_type}{(\code{numeric}, optional) The p of the p-norm to compute for the max_norm option. Default 2.}

\item{scale_grad_by_freq}{(\code{logical}, optional) If given, this will scale gradients by
the inverse of frequency of the words in the mini-batch. Default FALSE.}

\item{sparse}{(\code{logical}, optional) If TRUE, gradient w.r.t. weight matrix will be a sparse tensor.}

\item{.weight}{(\code{torch_tensor} or \code{list} of \code{torch_tensor}) Embeddings weights (in case you want to set it manually).}
}
\description{
It is especially useful, for dealing with multiple categorical features.
}
\examples{
library(recipes)

data("gss_cat", package = "forcats")

gss_cat_transformed <-
  recipe(gss_cat) \%>\%
  step_integer(everything()) \%>\%
  prep() \%>\%
  juice()

gss_cat_transformed <- na.omit(gss_cat_transformed)

gss_cat_transformed <-
   gss_cat_transformed \%>\%
   mutate(across(where(is.numeric), as.integer))

glimpse(gss_cat_transformed)

gss_cat_tensor  <- as_tensor(gss_cat_transformed)
.dict_size      <- dict_size(gss_cat_transformed)
.dict_size

.embedding_size <- embedding_size_google(.dict_size)

embedding_module <-
  nn_multi_embedding(.dict_size, .embedding_size)

# Expected output size
sum(.embedding_size)

embedding_module(gss_cat_tensor)

}
