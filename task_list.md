## April 4

1. Making plot look nice (adding sets as shading, one line, after you decide on a match, can add labels for important points).

2. Messing with prior and making a plot with fixed probabilities at 0.68 for men, 0.6x for women.

3. Start the posterdown template.

## March 28

1. create line plot for djokovic alcaraz 

2. write a few more functions and clean up current existing function.

3. try on a few different other matches and a few women's matches and make the resulting line plot. Can also try adding some background shading to the plot, shading according to the set (so that the background of the plot for set 1 is one colour, set 2 is another colour, etc.). 

4. Look at posterdown <https://github.com/brentthorne/posterdown> and <https://github.com/kaseygwood/slufellow/blob/main/fellow_poster/fellow_poster.Rmd>


## March 14

1. create line plot for djokovic alcaraz 

2. write a few more functions and clean up current existing function.

3. try on a few different other matches and a few women's matches and make the resulting line plot. Can also try adding some background shading to the plot, shading according to the set (so that the background of the plot for set 1 is one colour, set 2 is another colour, etc.). 

## March 7

1. Finish up third task from last week.

2. Use pmap() and in_match_win() to create a line plot of win probability through time.

3. Write functions to achieve data wrangling tasks for other potential matches.

4. Look over in_match_win() code.

## February 29

1. Loop through points in Bayesian model twice.

2. Combine the two data sets, arranging by point number.

3. Think about format needed for match_win_predict() function from the deuce package.

## February 13

1. Wrangle the point level data for Djokovic-Alcaraz.

2. Fit the Bayesian model for a particular stage of the match.

3. Put some point level data wrangling into a function, with input
    * match_id
    * player1 name, player2 name, and tournament name
    
Output would be one data frame with a column for point winner, a column for point server (1 or 0), in the correct point order, score in points, games, and sets.


## For February 1

1. Fit the model to your point data with serving effects.

    * with `compr`, point-level data from past matches you think are informative for the current match (e.g. grass leadups plus prior Wimbledon for current Wimbledon)

2. Create a new data frame that has the players for your match of interest (two rows: one when p1 is serving, one when p2 is serving).
    
    * put this data frame, along with fitted model from (1) into augment() in (3):
    
3. Use `augment()` to get a predicted log odds of p1 winning a point while serving and of p1 winning a point while returning.

    * give you predicted probability of p1 winning a point against p2 and of p2 winning a point against p1 (with standard errors)
    
4. Look at code file sent on November 3 (comp_prior).

5. Look at bayes_intro.R and run for a single state of the match (with a particular server at that state).

## December 15

1. Fit the model to your point data with serving effects.

2. Create a new data frame that has the players for your match of interest (two rows: one when p1 is serving, one when p2 is serving).

3. Use `augment()` to get a predicted log odds of p1 winning a point while serving and of p1 winning a point while returning.

4. Look at code file sent on November 3 (comp_prior).

5. Look at bayes_intro.R and run for a single state of the match (with a particular server at that state).

## November 9

1. Clean up files in repo (delete data sets).

2. Review the code that was sent in previous week.

3. Get match data so that each row is a point.

## October 26

1. Fix set issue.

2. fix data so that data is split with player A serving in one data frame, player B serving in the second data frame.

3. Make plot assuming equal serving probabilities.

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


