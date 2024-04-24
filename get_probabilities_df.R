library(tidyverse)


get_probabilities_df <- function(p1_serving_df = alcaraz_serving,
                                 p2_serving_df = djokovic_serving,
                                 p1 = "Carlos Alcaraz",
                                 p2 = "Novak Djokovic",
                                 p1_original_prob = 0.6194617,
                                 p1_original_se = 0.1038723,
                                 p2_original_prob = 0.6703011,
                                 p2_original_se = 0.1009560) {
  
  p1_niter <- p1_serving_df |> nrow()
  p1_prob_store <- double()
  ## create empty list to store posterior samples
  p1_prob_store_list <- list()
  
  p1_serving <- p1_serving_df |>
    mutate(player1 = p1,
           player2 = p2) |>
    # also create indicator if serving player won the point
    mutate(server_won = ifelse(PointWinner == 1, 1, 0))
  
  
  for (i in 1:p1_niter) {
    mod <- stan_glm(server_won ~ 1, data = p1_serving |> slice(1:i),
                    family = binomial,
                    prior_intercept = normal(p1_original_prob, p1_original_se),
                    seed = 123)
    p1_prob_store[i] <- coef(mod) |> expit()
    p1_prob_store_list[[i]] <- as_tibble(mod) |> expit() ## grab posterior samples
  }
  
  p1_serving <- p1_serving |>
    mutate(p1_wserv_prob = p1_prob_store,
           p1_wserv_prob_list = p1_prob_store_list)
  ## can have a column in a data frame that is a column of lists
  ## each row has a list of 4000 posterior samples
  
  p2_niter <- p2_serving_df |> nrow()
  p2_prob_store <- double()
  p2_prob_store_list <- list()
  
  p2_serving <- p2_serving_df |>
    mutate(player1 = p1,
           player2 = p2) |>
    # also create indicator if serving player won the point
    mutate(server_won = ifelse(PointWinner == 2, 1, 0))
  
  for (i in 1:p2_niter) {
    mod <- stan_glm(server_won ~ 1, data = p2_serving |> slice(1:i),
                    family = binomial,
                    prior_intercept = normal(p2_original_prob, p2_original_se),
                    seed = 123)
    p2_prob_store[i] <- coef(mod) |> expit()
    p2_prob_store_list[[i]] <- as_tibble(mod) |> expit()
  }
  
  p2_serving <- p2_serving |>
    mutate(p2_wserv_prob = p2_prob_store,
           p2_wserv_prob_list = p2_prob_store_list)
  
  # combine the data frames and arrange by pt_number
  combined_df <- bind_rows(p1_serving, p2_serving) |>
    arrange(pt_number) |>
    select(pt_number, player1, player2, PointServer, PointWinner, server_won,
           p1_wserv_prob, p2_wserv_prob,
           p1_wserv_prob_list, p2_wserv_prob_list,
           everything())
  
  #  Fill in the missing probabilities with the previously known probability
  #  for the list column, fill in the missing probabilities for the first
  #  match with a sample from the prior
  if (combined_df$PointServer[1] == 1) {
    combined_df[1, "p2_wserv_prob"] <- p2_original_prob |> expit()
    combined_df[1, "p2_wserv_prob_list"][[1]] <- rnorm(4000, p2_original_prob,
                                                       p2_original_se) |> expit() |>
      as_tibble() |> rename(`(Intercept)` = value) |> list()
    
  } else {
    combined_df[1, "p1_wserv_prob"] <- p1_original_prob |> expit()
    combined_df[1, "p1_wserv_prob_list"][[1]] <- rnorm(4000, p1_original_prob,
                                                       p1_original_se) |> expit() |>
      as_tibble() |> rename(`(Intercept)` = value) |> list()
  }
  
  combined_filled <- combined_df |>
    fill(p1_wserv_prob, p2_wserv_prob,
         p1_wserv_prob_list, p2_wserv_prob_list,
         .direction = "down")
  
  combined_final <- combined_filled |>
    mutate(P1SetsWon = cumsum(SetWinner == 1),
           P2SetsWon = cumsum(SetWinner == 2))
  
  ## TODO
  ## make p1_wserv_prob and p2_wserv_prob columns of
  ## lists with the posterior samples
  combined_final_cleaned <- combined_final |>
    select(pt_number, player1, player2, PointServer, p1_wserv_prob, p2_wserv_prob,
           P1PointsWon, P2PointsWon, P1GamesWon, P2GamesWon, P1SetsWon, P2SetsWon,
           p1_wserv_prob_list, p2_wserv_prob_list) |>
    mutate(PointServer = case_when(P1PointsWon == 0 & P2PointsWon == 0 & PointServer == 1 ~ 2,
                                   P1PointsWon == 0 & P2PointsWon == 0 & PointServer == 2 ~ 1,
                                   TRUE ~ PointServer))
  
  return(combined_final_cleaned)
}
