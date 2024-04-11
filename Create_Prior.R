library(tidyverse)
library(readr)
source("comp_prior_start.R")

create_prior <- function(ext = c("atp_matches_2022.csv",
                                 "atp_matches_2023.csv"),
                         tourn_name = "Wimbledon",
                         surf = "Grass",
                         start_date = "2023-07-03",
                         end_date = "2023-01-01",
                         player1 = "Carlos Alcaraz",
                         player2 = "Novak Djokovic",
                         ref_player = "Milos Raonic") {
  
  matches <- purrr::map(ext, read_matches) |>
    bind_rows()
  
  # filter for relevant matches
  prior <- matches |>
    mutate(tourney_date = lubridate::ymd(tourney_date)) |>
    
    # incorrect filter here, show to higham
    # filter(tourney_name ==  tourn_name |
             # (surface == surf & tourney_date <= lubridate::ymd(end_date) & tourney_date >= lubridate::ymd(start_date)))
    filter((tourney_name == tourn_name | surface == surf) &
           (tourney_date <= lubridate::ymd(end_date) & tourney_date >= lubridate::ymd(start_date)))
  
  
  prior_points <- prior |>
    select(1:3,6,7,9,11,17,19,24,30,32,33,39,41,42,46,48) |>
    mutate(w_svpt_w = w_1stWon + w_2ndWon,
           w_svpt_l = w_svpt - w_svpt_w,
           l_svpt_w = l_1stWon + l_2ndWon,
           l_svpt_l = l_svpt - l_svpt_w) |>
    select(winner_name, loser_name, w_svpt_w, w_svpt_l, l_svpt_w, l_svpt_l, match_num,
           1:5, 7, 9, 16:17) |>
    pivot_longer(cols = c("w_svpt_w", "w_svpt_l", "l_svpt_w", "l_svpt_l"),
                 names_to = "won_point",
                 values_to = "server") |>
    mutate(pt_winner = recode(
      won_point,
      "w_svpt_w" = 1,
      "w_svpt_l" = 0,
      "l_svpt_w" = 0,
      "l_svpt_l" = 1)) |>
    mutate(pt_server = recode(
      won_point,
      "w_svpt_w" = 1,
      "w_svpt_l" = 1,
      "l_svpt_w" = 0,
      "l_svpt_l" = 0)) |>
    # remove rows where server is NA (walkovers)
    filter(!is.na(server))
  
  prior_points_uncount <- uncount(prior_points, weights = as.numeric(server)) |>
    mutate(p1_server = ifelse(pt_server == 1, 1, 0),
           p2_server = ifelse(pt_server == 0, 1, 0)) |>
    # reorganize columns
    select(winner_name, loser_name, pt_winner, p1_server, p2_server, everything()) |>
    rename(player1 = winner_name, player2 = loser_name)
  
  # Now fit the model to your point data with serving effects
  comp_mod <- comp_glm(pt_winner ~ -1, data = prior_points_uncount,
                       p1 = "player1", p2 = "player2",
                       p1_effects = ~ p1_server, p2_effects = ~ p2_server,
                       ref_player = ref_player)
  
  match_data <- data.frame(
    player1 = (player1),
    player2 = (player2),
    p1_server = c(1, 0),
    p2_server = c(0, 1))

  aug_mod <- aug_mod(comp_mod, newdata = match_data)
  
  return(aug_mod)
}
