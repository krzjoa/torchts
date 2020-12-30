# https://www.tensorflow.org/tutorials/structured_data/time_series
# TODO: modeling grouped time series: PR on fable!

# m_embed <- nn_multi_embedding(d_size + 1, rep(2, 5))
# debugonce(m_embed$forward)
# m_embed(X_tensor)

# X_tensor$type_as(torch_long())

# data_tensor$shape

# Global model
# embedded <-
#   torch::nn_embedding()

# embedding <- nn_embedding(7, 2)
# # a batch of 2 samples of 4 indices each
# input2 <- torch_tensor(rbind(c(1,2,4,5),c(4,3,2,9)), dtype = torch_long())
# embedding(input2)
# # example with padding_idx
# embedding <- nn_embedding(10, 3, padding_idx=1)
# input <- torch_tensor(matrix(c(1,3,1,6), nrow = 1), dtype = torch_long())
# embedding(input)

# .data %>%
#   group_by(date) %>%
#   summarise(n = n()) %>%
#   View()

