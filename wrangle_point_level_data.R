library(tidyverse)
library(readr)

wrangle_point_level <- function(ext = "2023-wimbledon-points.csv",
                                ID = "2023-wimbledon-1701") {
  df <- readr::read_csv(paste0("https://raw.githubusercontent.com/JeffSackmann/tennis_slam_pointbypoint/master/",
                               ext))
  df <- df |> dplyr::filter(match_id == ID) |>
  
    dplyr::mutate(P1GamesWon = ifelse(SetWinner != 0, 0, P1GamesWon),
                  P2GamesWon = ifelse(SetWinner != 0, 0, P2GamesWon)) |>
    
    filter(PointWinner != 0)
  
  df <- df |> select(PointWinner,
                     P1Score,
                     P2Score,
                     P1GamesWon,
                     P2GamesWon,
                     SetWinner,
                     PointServer) |>
    mutate(P1Score = ifelse(P1Score == "AD", 4, P1Score),
           P2Score = ifelse(P2Score == "AD", 4, P2Score),
           P1PointsWon = as.numeric(P1Score),
           P2PointsWon = as.numeric(P2Score)) |>
    mutate(P1PointsWon = case_when(P1Score == 0 ~ 0,
                                   P1Score == 15 ~ 1,
                                   P1Score == 30 ~ 2,
                                   P1Score == 40 ~ 3,
                                   TRUE ~ P1PointsWon),
           P2PointsWon = case_when(P2Score == 0 ~ 0,
                                   P2Score == 15 ~ 1,
                                   P2Score == 30 ~ 2,
                                   P2Score == 40 ~ 3,
                                   TRUE ~ P2PointsWon)) |>
    mutate(pt_number = row_number())
  
  p1_serving <- df |> filter(PointServer == 1)
  p2_serving <- df |> filter(PointServer == 2)
  
  return(list(p1_serving, p2_serving))
}
