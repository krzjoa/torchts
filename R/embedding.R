library(torch)

embedding <- torch::nn_embedding(10, 3)
embedding$weight

input <- torch_tensor(
  rbind(c(1,2,4,5),c(4,3,2,9)), dtype = torch_long()
)

input <- torch_tensor(
  rbind(c(1,2,4,5),c(4,3,2,10)), dtype = torch_long()
)

embedding(input)

# Każdy indeks został zrutowany na trzyelementowy wektor
