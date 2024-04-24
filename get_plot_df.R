library(tidyverse)
library(deuce)


## added type argument that can either be mean or dist
get_plot_df <- function(combined_df,
                        which_player_prob = 1,
                        best_of_3 = FALSE,
                        advantage = FALSE,
                        type = "mean") {
  
  if (type != "mean" & type != "distribution") {
    stop("`type` must be either 'mean' or 'distribution'")
  }
  
  # Filter for player 1 serving
  p1_serv <- combined_df |>
    filter(PointServer == 1)
  
  # Filter for player 2 serving
  p2_serv <- combined_df |>
    filter(PointServer == 2)
  
  if (type == "mean") {
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
    
  } else if (type == "distribution") {
    
    p1_serving_tib <- tibble(
      point_a = p1_serv$P1PointsWon,
      point_b = p1_serv$P2PointsWon,
      game_a = p1_serv$P1GamesWon,
      game_b = p1_serv$P2GamesWon,
      set_a = p1_serv$P1SetsWon,
      set_b = p1_serv$P2SetsWon,
      server.prob = p1_serv$p1_wserv_prob_list,
      returner.prob = p1_serv$p2_wserv_prob_list
    )
    
    # Create tibble for player 2 serving to feed into in_match_win
    p2_serving_tib <- tibble(
      point_a = p2_serv$P2PointsWon,
      point_b = p2_serv$P1PointsWon,
      game_a = p2_serv$P2GamesWon,
      game_b = p2_serv$P1GamesWon,
      set_a = p2_serv$P2SetsWon,
      set_b = p2_serv$P1SetsWon,
      server.prob = p2_serv$p2_wserv_prob_list,
      returner.prob = p2_serv$p1_wserv_prob_list
    )
    
    ## number of rows should be number of server1 points times 4000
    ## unnest() gives a warning letting us know we are using the
    ## "old" syntax, which is fine
    p1_serving_tib <- p1_serving_tib |>
      unnest(server.prob, returner.prob) |>
      rename(server.prob = `(Intercept)`,
             returner.prob = `(Intercept)1`)
    
    # calculate probability of player 1 winning throughout the match
    p1_win_prob <- p1_serving_tib |> pmap(in_match_win, bestof3 = best_of_3,
                                          advantage = advantage)
    # add probability to player 1 serving df
    p1_serving_tib$probability <- unlist(p1_win_prob)
    
    ## create id for each point (should be 4000 rows for one point)
    p1_serving_tib <- p1_serving_tib |>
      mutate(id = rep(1:nrow(p1_serv), each = 4000))
    
    p1_win_prob <- p1_serving_tib |> group_by(id) |>
      summarise(mean_prob = mean(probability)) |>
      pull(mean_prob)
    
    p1_serv$probability <- p1_win_prob
    
    ## number of rows should be number of server1 points times 4000
    p2_serving_tib <- p2_serving_tib |>
      unnest(server.prob, returner.prob) |>
      rename(server.prob = `(Intercept)`,
             returner.prob = `(Intercept)1`)
    
    # calculate probability of player 1 winning throughout the match
    p2_win_prob <- p2_serving_tib |> pmap(in_match_win, bestof3 = best_of_3,
                                          advantage = advantage)
    # add probability to player 1 serving df
    p2_serving_tib$probability <- unlist(p2_win_prob)
    
    ## create id for each point (should be 4000 rows for one point)
    p2_serving_tib <- p2_serving_tib |>
      mutate(id = rep(1:nrow(p2_serv), each = 4000))
    
    p2_win_prob <- p2_serving_tib |> group_by(id) |>
      summarise(mean_prob = mean(probability)) |>
      pull(mean_prob)
    
    p2_serv$probability <- p2_win_prob
    
  }
  
  # combine the data frames
  recombined_df <- rbind(p2_serv, p1_serv) |>
    arrange(pt_number) |>
    mutate(total_sets = as.factor(P1SetsWon + P2SetsWon)) |>
    # create probability var for just player 1 winning
    mutate(win_prob_px = ifelse(PointServer == which_player_prob, probability, 1 - probability))
  
  return(recombined_df)
}
