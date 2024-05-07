library(tidyverse)

read_matches <- function(ext = "atp_matches_2023.csv") {
  if (substr(ext, 1, 3) == "atp") {
    url <- paste0("https://raw.githubusercontent.com/JeffSackmann/tennis_atp/master/", ext)
  } else if (substr(ext, 1, 3) == "wta") {
    url <- paste0("https://raw.githubusercontent.com/JeffSackmann/tennis_wta/master/", ext)
  } else {
    stop("Invalid extension. Extension must start with 'atp' or 'wta'.")
  }
  
  df <- readr::read_csv(url, col_types = list(match_num = col_character())) |>
    mutate(winner_seed = as.numeric(winner_seed)) |>
    mutate(loser_seed = as.numeric(loser_seed))
  return(df)
}

## reading in atp matches for 3 years
ext_vec <- c("atp_matches_2021.csv",
             "atp_matches_2022.csv",
             "atp_matches_2023.csv")
atp_21_23 <- purrr::map(ext_vec, read_matches) |>
  bind_rows()

## choose matches as part of "prior" model: these are likely going to
## be tournaments where the matches are most predictive of the current
## tournament of interest
## example
atp_us_prior <- atp_21_23 |>
  mutate(tourney_date = lubridate::ymd(tourney_date)) |>
  filter(tourney_name == "Us Open" |
           (surface == "Hard" & tourney_date <= "2023-08-30" & tourney_date >= "2023-01-01"))


## you'll want each row of the data frame to correspond to a __point__,
## not a match.
## Use the `tennis_point` data below as a model goal

## james is working on this package in his own repository: you'll likely
## be changing to his version once he gets it working
# devtools::install_github(repo = "https://github.com/highamm/compr")

library(compr)

## I've used some tennis sample data as example data within the package:
tennis_point

## You want your data to match this set-up: each row is a point,
## there is a column for point_winner,
## there is a column for whether or not the first player is serving
## there is a column for whether or not the second player is serving

comp_glm(point_winner ~ -1, data = tennis_point,
         p1 = "player1", p2 = "player2",
         p1_effects = ~ point_server1, p2_effects = ~ point_server2,
         ref_player = "Milos Raonic") |>
  broom::tidy() |>
  print(n = Inf)

## the output of this model gives both "serve" and "return" abilities
## for each player, along with standard errors
##
## to find the estimated probability that Roger Federer wins a point on
## serve against Andy Murray, the logodds are:

(0.580 + 0.756) - 0.230

## and the estimated probability is:
exp((0.580 + 0.756) - 0.230) / (1 + exp((0.580 + 0.756) - 0.230))

expit <- function(x) {
  exp(x) / (1 + exp(x))
}
expit((0.580 + 0.756) - 0.230)

## James's version will make it much easier to snag both
## the predicted log odds and the standard error (on the log odds scale)
