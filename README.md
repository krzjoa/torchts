
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
