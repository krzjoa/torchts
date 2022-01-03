## TODO

* handling missing data as a separate vignette
* add a vignette with name explanation (index, key, outcome = target etc.)
* monitor hidden state
https://fairyonice.github.io/Understand-Keras%27s-RNN-behind-the-scenes-with-a-sin-wave-example.html
* sine
https://towardsdatascience.com/can-machine-learn-the-concept-of-sine-4047dced3f11
https://mourafiq.com/2016/05/15/predicting-sequences-using-rnn-in-tensorflow.html
https://goelhardik.github.io/2016/05/25/lstm-sine-wave/
https://codesachin.wordpress.com/2016/01/23/predicting-trigonometric-waves-few-steps-ahead-with-lstms-in-tensorflow/

* check model "confusion", i.e. variance for nearly the same examples
https://stats.stackexchange.com/questions/220307/rnn-learning-sine-waves-of-different-frequencies

## BUGS
* Learning rate on gpu (seem it works...)

## Which name?

* h, horizon, prediction_length (modeltime.gluonts)
* timesteps, steps, lookback_length (modeltime.gluonts)
* targets, outcomes <= https://recipes.tidymodels.org/articles/Roles.html
* predictor, inputs
* key (fable), id (modeltime)
* index (fable), date_var (timetk) <= https://tsibble.tidyverts.org/reference/tsibble.html

## Conditional RNN 
* [cond_rnn](https://github.com/philipperemy/cond_rnn)
* [Adding Features To Time Series Model LSTM](https://datascience.stackexchange.com/questions/17099/adding-features-to-time-series-model-lstm/17139#17139)

## Missing values
* See: https://www.tensorflow.org/guide/keras/masking_and_padding
* https://www.nature.com/articles/s41598-018-24271-9

## Demand
* https://www.researchgate.net/publication/298725275_A_new_metric_of_absolute_percentage_error_for_intermittent_demand_forecasts
* https://frepple.com/blog/demand-classification/

## Metrics
* https://datascience.stackexchange.com/questions/55388/tweedie-loss-for-keras

## Libraries
* https://github.com/zalandoresearch/pytorch-ts
* https://pytorch-widedeep.readthedocs.io/en/latest/index.html

## Other
* [AR-Net](https://arxiv.org/pdf/1911.12436.pdf)

## Heuristics
https://stats.stackexchange.com/questions/181/how-to-choose-the-number-of-hidden-layers-and-nodes-in-a-feedforward-neural-netw


## R + Keras
https://www.datatechnotes.com/2019/01/regression-example-with-lstm-networks.html


## RNN
* A Formal Hierarchy of RNN Architectures
https://arxiv.org/abs/2004.08500


## Formula proposals

h(value, 7) ~ b(value, 28) + price + lead(price, 5) 
