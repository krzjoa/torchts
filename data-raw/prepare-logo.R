library(ggplot2)
library(data.table)

devtools::install_github("coolbutuseless/minisvg")   # SVG creation
devtools::install_github("coolbutuseless/devout")    # Device interface
devtools::install_github("coolbutuseless/devoutsvg") # This package

shampoo <- read.csv("https://raw.githubusercontent.com/jbrownlee/Datasets/master/shampoo.csv")
setDT(shampoo)
shampoo[, n := 1:.N]

plt <-
  ggplot(shampoo) +
  geom_line(aes(n, Sales, lwd = 0.1)) +
  theme_void() +
  theme(legend.position="none")

devoutsvg::svgout(
  filename = here::here("shampoo.svg"),
  width = 8, height = 4,
)

plt

invisible(dev.off())

ggsave("torch.svg")


plt
