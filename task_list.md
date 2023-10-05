## October 19

1. Put data from (2) into `in_match_win(c(3), c(2), c(5), c(5),c(0), c(0), c(0.69), c(0.69), bestof3 = T, advantage = F)`

2. Look at purrr_toy.R and apply iteration to obtain probabilities over an entire match.
    
3. Make a line plot of the probabilities through time for a particular match of interest.
    
4. Get WTA data (both match-level and point-level) and format the data in the same way you did the ATP data.

## October 5

1. In addition to Sept. 21 tasks

    1. Look at purrr_toy.R and apply iteration to obtain probabilities over an entire match.
    
    2. Make a line plot of the probabilities through time for a particular match of interest.
    
    3. Get WTA data (both match-level and point-level) and format the data in the same way you did the ATP data.

## September 28 (No Meeting: MH)

## September 21 (No Meeting: BM)

1. Download <https://github.com/skoval/deuce/tree/master>

2. Grab interesting match from <https://github.com/JeffSackmann/tennis_slam_pointbypoint>

3. Put data from (2) into `in_match_win(c(3), c(2), c(5), c(5),c(0), c(0), c(0.69), c(0.69), bestof3 = T, advantage = F)`

make a data.frame with 8 columns, n_point rows, each column corresponds
to an argument in the function above.

## September 14

1. Wrangle data below into format we discussed. Start to explore serving percentages for each player (compute points won on serve and make sure that they make sense).

2. <https://www.bayesrulesbook.com/chapter-3>

## September 7

1. Bayesian intro reading (Chapters 1 and 2).
2. Wrangle data below into format we discussed.

```{r}
readr::read_csv("https://raw.githubusercontent.com/JeffSackmann/tennis_atp/master/atp_matches_2023.csv")
```


