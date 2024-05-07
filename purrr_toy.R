library(deuce)
library(tidyverse)


toy_points <- tibble::tibble(point_a = c(0, 1), point_b = c(1, 1),
                         game_a = c(4, 4), game_b = c(4, 4),
                         set_a = c(1, 1), set_b = c(1, 1),
                         server.prob = c(0.67, 0.67),
                         returner.prob = c(0.61, 0.59))


toy_points |> pmap(in_match_win, bestof3 = FALSE,
                   advantage = TRUE)
## iteration over each row returns a list of probabilities.

