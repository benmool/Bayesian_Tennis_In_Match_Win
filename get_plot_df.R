library(tidyverse)
library(deuce)

get_plot_df <- function(combined_df = combined_prob_df,
                        which_player_prob = 1,
                        best_of_3 = FALSE,
                        advantage = FALSE) {
  
  # Filter for player 1 serving
  p1_serv <- combined_prob_df |>
    filter(PointServer == 1)
  
  # Filter for player 2 serving
  p2_serv <- combined_prob_df |>
    filter(PointServer == 2)
  
  # Create tibble for player 1 serving to feed into in_match_win
  p1_serving_tib <- tibble(
    point_a = p1_serv$P1PointsWon,
    point_b = p1_serv$P2PointsWon,
    game_a = p1_serv$P1GamesWon,
    game_b = p1_serv$P2GamesWon,
    set_a = p1_serv$P1SetsWon,
    set_b = p1_serv$P2SetsWon,
    server.prob = p1_serv$p1_wserv_prob,
    returner.prob = p1_serv$p2_wserv_prob
  )
  
  # Create tibble for player 2 serving to feed into in_match_win
  p2_serving_tib <- tibble(
    point_a = p2_serv$P2PointsWon,
    point_b = p2_serv$P1PointsWon,
    game_a = p2_serv$P2GamesWon,
    game_b = p2_serv$P1GamesWon,
    set_a = p2_serv$P2SetsWon,
    set_b = p2_serv$P1SetsWon,
    server.prob = p2_serv$p2_wserv_prob,
    returner.prob = p2_serv$p1_wserv_prob
  )
  
  # calculate probability of player 1 winning throughout the match
  p1_win_prob <- p1_serving_tib |> pmap(in_match_win, bestof3 = best_of_3,
                                        advantage = advantage)
  # add probability to player 1 serving df
  p1_serv$probability <- p1_win_prob
  # fix the probability column
  p1_serv <- p1_serv |> unnest(probability)
  
  # calculate probability of player 2 winning throughout the match
  p2_win_prob <- p2_serving_tib |> pmap(in_match_win, bestof3 = best_of_3,
                                        advantage = advantage)
  # add probability to player 2 df
  p2_serv$probability <- p2_win_prob
  # fix the probability column
  p2_serv <- p2_serv |> unnest(probability)
  
  # combine the data frames
  recombined_df <- rbind(p2_serv, p1_serv) |> 
    arrange(pt_number) |>
    mutate(total_sets = as.factor(P1SetsWon + P2SetsWon)) |>
    # create probability var for just player 1 winning
    mutate(win_prob_px = ifelse(PointServer == which_player_prob, probability, 1 - probability))
  
  return(recombined_df)
}
