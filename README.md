
<!-- README.md is generated from README.Rmd. Please edit that file -->

# torchts

> Time series models with torch

<!-- badges: start -->

[![Travis build
status](https://travis-ci.com/krzjoa/torchts.svg?branch=master)](https://travis-ci.com/krzjoa/torchts)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/krzjoa/torchts?branch=master&svg=true)](https://ci.appveyor.com/project/krzjoa/torchts)
<!-- badges: end -->

## Installation

You can install the released version of torchts from
[CRAN](https://CRAN.R-project.org) with:

The development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("krzjoa/torchts")
```

## Usage

## parsnip models

``` r
library(torchts)
library(torch)
library(rsample)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(parsnip)

data_set <-
  read.csv("https://raw.githubusercontent.com/jbrownlee/Datasets/master/daily-min-temperatures.csv")

# Splitting on training and test
data_split <- initial_time_split(data_set)

# Training 
model <- 
  rnn(epochs = 10, hidden_units = 32) %>% 
  fit(Temp ~ Temp + index(Date), 
      data = training(data_split))
#> Warning: Engine set to `torchts`.
#> 
#> Epoch 1, training: loss: 95.42544 
#> 
#> Epoch 2, training: loss: 48.88457 
#> 
#> Epoch 3, training: loss: 29.60288 
#> 
#> Epoch 4, training: loss: 21.21282 
#> 
#> Epoch 5, training: loss: 16.75105 
#> 
#> Epoch 6, training: loss: 13.32213 
#> 
#> Epoch 7, training: loss: 10.93875 
#> 
#> Epoch 8, training: loss: 9.33267 
#> 
#> Epoch 9, training: loss: 8.31204 
#> 
#> Epoch 10, training: loss: 7.67917

# prediction <- 
#   model %>% 
#   predict(new_data = testing(data_split))
```

### Transforming data.frames to tensors

In `as_tensor` function we can specify columns, that are used to create
a tensor out of the input `data.frame`. Listed column names are only
used to determine dimension sizes - they are removed after that and are
not present in the final tensor.

``` r
library(torchts)
suppressMessages(library(dplyr))
data("mts-examples", package="MTS")

dim(ibmspko)
#> [1] 612   4
head(ibmspko)
#>       date       ibm        sp        ko
#> 1 19610131  0.072513  0.063156  0.009331
#> 2 19610228  0.062500  0.026870  0.103236
#> 3 19610330  0.029630  0.025536  0.012291
#> 4 19610428  0.027338  0.003843 -0.050000
#> 5 19610531  0.027521  0.019139  0.087719
#> 6 19610630 -0.026612 -0.028846 -0.058065

monthly_returns <- 
  ibmspko %>% 
  as_tensor(date)

dim(monthly_returns)
#> [1] 612   3
monthly_returns[1:6, ]
#> torch_tensor
#>  0.0725  0.0632  0.0093
#>  0.0625  0.0269  0.1032
#>  0.0296  0.0255  0.0123
#>  0.0273  0.0038 -0.0500
#>  0.0275  0.0191  0.0877
#> -0.0266 -0.0288 -0.0581
#> [ CPUFloatType{6,3} ]
```
