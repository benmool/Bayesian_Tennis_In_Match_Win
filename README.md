# README.qmd

``` r
library(tidyverse)
library(compr)
library(broom)
library(dplyr)
library(readr)
library(deuce)
library(ggplot2)
library(knitr)
library(kableExtra)

# Source the functions
source("comp_prior_start.R")
source("bayes_intro.R")
source("wrangle_point_level_data.R")
source("Create_Prior.R")
source("get_probabilities_df.R")
source("get_plot_df.R")
```

``` r
sin_alc_paired <- wrangle_point_level(ext = "2022-usopen-points.csv",
                               ID = "2022-usopen-1503")
```

    Rows: 47243 Columns: 65
    ── Column specification ────────────────────────────────────────────────────────
    Delimiter: ","
    chr (10): match_id, ElapsedTime, PointNumber, P1Score, P2Score, WinnerType, ...
    dbl (38): SetNo, P1GamesWon, P2GamesWon, SetWinner, GameNo, GameWinner, Poin...
    lgl (17): Rally, P1FirstSrvIn, P2FirstSrvIn, P1FirstSrvWon, P2FirstSrvWon, P...

    ℹ Use `spec()` to retrieve the full column specification for this data.
    ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
sin_serving <- sin_alc_paired[[1]]
alc_serving <- sin_alc_paired[[2]]
```

## ATP and WTA Professional Tennis: Calculating In-Match-Win Probability with Bayesian Modeling

This project explores the probabilities of professional tennis players
winning matches. Tennis’ scoring format allows for huge momentum swings
in a short amount of time, and we are going to explore how the
probabilities that tennis players win a match are calculated and update
throughout the match using Bayesian modeling. We will be using the
probability that player1 wins a point on serve against player2, the
probability that player2 wins a point on serve against player1, and the
current score of the match of interest. We will explore the 2022 Men’s
US Open Quarterfinal between Carlos Alcaraz and Jannik Sinner as an
example. Alcaraz defeated Sinner in 5 sets, 6-3, 6-7(7), 6-7(0), 7-5,
6-3.

### Bayesian Modeling

A brief overview on Bayesian modeling is that we start with some
existing beliefs about a parameter, which we call our prior
distribution. We then observe new data come in and update our beliefs
about the parameter based on the new data, which we call our posterior
distribution.

In this project, our parameters of interest are the probabilities that
player1 and player2 win a point on their serve. We calculate these
probabilities using previous matches that have been played. As the match
progresses, we update our beliefs about these probabilities of winning a
point on serve, and at a specific state of the match, we can calculate
the probability that either of the players wins the match.

### Data

The data used in this project is from the ATP and WTA professional
tennis tours, and is from Jeff Sackman’s tennis data on Github. There is
[point-level
data](https://github.com/JeffSackmann/tennis_slam_pointbypoint) on the
ATP and WTA main-draw singles grand slam tournaments from 2011-present.
There is also [match-level
data](https://github.com/JeffSackmann/tennis_atp) for ATP matches and
[match-level data](https://github.com/JeffSackmann/tennis_wta) for WTA
matches. We will be using functions that handle reading in the data and
wrangling it and will not have to interact with the data directly.

### Prior Distributions

We start with some prior beliefs about the probabilities that player1
and player2 win a point on serve. We use the data from previous matches
to calculate these prior distributions. We will update these prior
distributions as the match progresses.

For our example of Alcaraz vs Sinner, we will use data from the leadup
tournaments to the 2022 US Open (hard court tournaments) and the rounds
of the 2022 US Open before the quarterfinals to calculate the
probability that Alcaraz wins a point while serving against Sinner, and
the probability that Sinner wins a point while serving against Alcaraz.
With these estimated probabilities and standard deviations, we then
create distributions for the prior probabilities of winning a point on
serve for Alcaraz and Sinner.

``` r
prior_sin_logodds <- 0.2434863
prior_sin_sd_logodds <- 0.1193404

prior_sin_df <- tibble::tibble(logodds = rnorm(200000,
                                                 prior_sin_logodds,
                                                 prior_sin_sd_logodds),
                           prob = expit(logodds))

prior_alc_logodds <- 0.5017383
prior_alc_sd_logodds <- 0.1196950

prior_alc_df <- tibble::tibble(logodds = rnorm(200000,
                                                 prior_alc_logodds,
                                                 prior_alc_sd_logodds),
                           prob = expit(logodds))

both_priors_df <- bind_rows(prior_sin_df, prior_alc_df, .id = "type") |>
  mutate(type = fct_recode(type, "Sinner" = "1",
                           "Alcaraz" = "2"),
         type = fct_relevel(type, c("Sinner", "Alcaraz")))

ggplot(data = both_priors_df, aes(x = prob)) +
  geom_density(aes(colour = type), adjust = 2,
               linewidth = 1.4) + ## adjust smooths it out
  scale_colour_viridis_d(end = 0.9) +
  theme_minimal() +
  labs(title = "Prior Distributions for Sinner and Alcaraz",
       x = "Probability of Winning a Point (on serve)",
       y = "Density",
       caption = "Prior includes matches from leadup tournaments to 2022 USO and 2022 USO itself") +
  theme_bw(base_size = 20)
```

![](README_files/figure-commonmark/unnamed-chunk-3-1.png)

From our prior distributions, we can see that Sinner’s probability of
winning a point on serve against Alcaraz is around 0.57, and Alcaraz’s
probability of winning a point on serve against Sinner is around 0.62.
These are our starting probability distributions for the match. Based on
their prior matches we have included, we think that Alcaraz has a higher
probability of winning a point on his serve than Sinner does, but, there
is some overlap in their prior distributions. As each point is played,
we will update these probability distributions.

### Prior, Data and Posterior

Now with our prior distributions for the probabilities that the players
win a point while serving, we can observe how these probabilities update
throughout the match by looking at a specific state of the match.

For our Alcaraz and Sinner example, now that we have their probabilities
of winning a point on serve, we can look at Sinner when he is serving at
40-15, 1-1 in the 3rd set (a little less than halfway through the match)
and see how his probability of winning a point on serve has changed. At
this state of the match, Sinner has played 150 points on his serve and
won 89 of them, which is right around 0.6.

``` r
p1_serving_df <- sin_serving |> slice(1:150)

p1_serving_df |>
  summarise(points_won = sum(PointWinner == 1),
            points_played = n(),
            prop_won = points_won / points_played)

alc_serving |>
  summarise(points_won = sum(PointWinner == 2),
            points_played = n(),
            prop_won = points_won / points_played)

p1_niter <- p1_serving_df |> nrow()

p1_prob_store <- double()
  
p1_serving <- p1_serving_df |>
    # also create indicator if serving player won the point
    mutate(server_won = ifelse(PointWinner == 1, 1, 0))
  
mod <- stan_glm(server_won ~ 1, data = p1_serving |> slice(1:p1_niter),
                    family = binomial,
                    prior_intercept = normal(prior_sin_logodds, prior_sin_sd_logodds),
                    seed = 123)
coef(mod) |> expit()

# use above to pull specific probabilities at a state of the match

tibble_mod <- as_tibble(mod) |>
  mutate(prob = expit(`(Intercept)`)) |>
  rename(logodds = `(Intercept)`)

ggplot(data = tibble_mod, aes(x = prob)) +
  geom_density(adjust = 5, linewidth = 0.9)
```

``` r
plot_df <- bind_rows(tibble_mod, prior_sin_df, .id = "type") |>
  mutate(type = fct_recode(type, "posterior" = "1",
                           "prior" = "2"),
         type = fct_relevel(type, c("prior", "posterior")))
```

``` r
ggplot(data = plot_df, aes(x = prob)) +
  geom_density(aes(linetype = type), adjust = 2,
               linewidth = 0.9) + ## adjust smooths it out
  theme_minimal() +
  labs(title = "Prior and Posterior Distributions at Specific Match State",
       subtitle = "Sinner serving at 40-15, 1-1, 3rd set",
       x = "Sinner's Probability of Winning a Point (on serve)",
       y = "Density",
       caption = "Sinner: 89/150 points won on serve") +
  coord_cartesian(ylim = c(0, 17)) +
  theme_bw(base_size = 22)
```

![](README_files/figure-commonmark/unnamed-chunk-5-1.png)

We can see that Sinner’s probability distribution of winning a point on
serve when he is serving at 40-15, 1-1 in the 3rd set has shifted from
the prior distribution, closer to 0.6.

### Caclulating In-Match-Win Probability

With the probabilities of both players winning a point on their serve,
we can calculate the probability of either player winning the entire
match. We can do this by simulating the match point by point, and
updating the probabilities of the players winning a point on serve as
each successive point is played. For a current state of the match, we
have the updated probabilities of each player winning a point on serve,
and the score at that state of the match, and using these we can
calculate the overall probability of winning the match.

For our example, we will explore the probability that Alcaraz wins the
match.

``` r
combined_prob_sin_alc_sp_df <- get_probabilities_df(p1_serving_df = sin_serving,
                                 p2_serving_df = alc_serving,
                                 p1 = "Jannik Sinner",
                                 p2 = "Carlos Alcaraz",
                                 p1_original_prob = 0.2434863,
                                 p1_original_se = 0.1193404,
                                 p2_original_prob = 0.5017383,
                                 p2_original_se = 0.1196950)

plot_sin_alc_small_prior <- get_plot_df(combined_df = combined_prob_sin_alc_sp_df, 
                        which_player_prob = 2,
                        best_of_3 = FALSE,
                        advantage = FALSE,
                        type = "distribution") |>
  mutate(set_number = as.factor(as.numeric(total_sets))) |>
  # fix last row in data set where set_number is 6, should be a 5
  mutate(set_number = ifelse(pt_number == max(pt_number), '5', set_number)) |>
  mutate(set_number = as.factor(set_number))

fills <- c("#F57A5C", "#F5C25C", "#94E25B", "#69CEE0", "#A875CE")
```

``` r
plot_five_sets_sin_alc <- plot_sin_alc_small_prior |>
  filter(set_number == 1 | set_number == 2 | set_number == 3 | set_number == 4 | set_number == 5)

five_set_boundaries_alc_sin_small_prior <- plot_sin_alc_small_prior |>
  group_by(set_number) |>
  summarize(xmin = min(pt_number) - 0.5,
            xmax = max(pt_number) + 0.5) |>
  filter(set_number == 1 | set_number == 2 | set_number == 3 | set_number == 4 | set_number == 5)
```

``` r
plot_sin_alc_small_prior |> ggplot(aes(x = pt_number, y = probability)) +
  geom_rect(data = five_set_boundaries_alc_sin_small_prior, aes(x = NULL, y = NULL, xmin = xmin, xmax = xmax, 
                                       ymin = -Inf, ymax = Inf, fill = set_number), alpha = 0.2) + 
  geom_line(data = plot_five_sets_sin_alc, aes(y = win_prob_px)) +
  labs(x = "Point Number",
       y = "Probability of Winning Match",
       title = "Alcaraz vs Sinner US Open Quarterfinal 2022",
       subtitle = "Probability of Alcaraz Winning Match",
       caption = "Prior contains 'lead-up' tournaments to the 2022 USO and 2022 USO itself",
       color = "Server") +
  coord_cartesian(ylim = c(0, 1),
                  xlim = c(0, nrow(plot_sin_alc_small_prior))) +
  scale_fill_manual(values = fills[1:5]) +
  theme_bw(base_size = 14)
```

![](README_files/figure-commonmark/unnamed-chunk-8-1.png)

### Changing Prior Distributions

We can change what matches we include in our prior distributions and see
how this affects our probabilities of each player winning a point on
serve at the start of the match. With these different probabilities of
winning a point on serve, we can see how the overall probability of
winning the match changes.

For our example, we will explore the effect of changing the prior
distributions on the probability of Alcaraz winning the match. We have
our original prior distribution we used, labeled “Small Prior”, and it
included the lead-up tournaments to the 2022 US Open and the 2022 US
Open itself. We will compare this to a “Large Prior” distribution that
includes all hard court matches from the 2021 US Open to the 2022 US
Open itself. We can also fix the probabilities of Sinner and Alcaraz
winning a point on serve at a specific value, such as 0.68 (around tour
average).

``` r
combined_prob_alc_sin_lp_df <- get_probabilities_df(p1_serving_df = sin_serving,
                                 p2_serving_df = alc_serving,
                                 p1 = "Jannik Sinner",
                                 p2 = "Carlos Alcaraz",
                                 p1_original_prob = 0.4288085,
                                 p1_original_se = 0.04919170,
                                 p2_original_prob = 0.4795682,
                                 p2_original_se = 0.04971023)

plot_sin_alc_large_prior <- get_plot_df(combined_df = combined_prob_alc_sin_lp_df,
                                        which_player_prob = 2,
                                        best_of_3 = FALSE,
                                        advantage = FALSE,
                                        type = "distribution") |>
  mutate(set_number = as.factor(as.numeric(total_sets))) |>
  # fix last row in data set where set_number is 6, should be a 5
  mutate(set_number = ifelse(pt_number == max(pt_number), '5', set_number)) |>
  mutate(set_number = as.factor(set_number))

sin_serving_fp <- sin_serving |> 
  mutate(player1 = "Jannik Sinner",
         player2 = "Carlos Alcaraz") |>
    # also create indicator if serving player won the point
    mutate(server_won = ifelse(PointWinner == 1, 1, 0))

alc_serving_fp <- alc_serving |> 
  mutate(player1 = "Jannik Sinner",
         player2 = "Carlos Alcaraz") |>
    # also create indicator if serving player won the point
    mutate(server_won = ifelse(PointWinner == 2, 1, 0))

combined_sin_alc_fixed_df <- bind_rows(sin_serving_fp, alc_serving_fp) |>
    arrange(pt_number) |>
  mutate(p1_wserv_prob = 0.68,
         p2_wserv_prob = 0.68) |>
  mutate(P1SetsWon = cumsum(SetWinner == 1),
           P2SetsWon = cumsum(SetWinner == 2)) |>
  select(pt_number, player1, player2, PointServer, p1_wserv_prob, p2_wserv_prob,
         P1PointsWon, P2PointsWon, P1GamesWon, P2GamesWon, P1SetsWon, P2SetsWon) |>
  mutate(PointServer = case_when(P1PointsWon == 0 & P2PointsWon == 0 & PointServer == 1 ~ 2,
                                 P1PointsWon == 0 & P2PointsWon == 0 & PointServer == 2 ~ 1,
                                 TRUE ~ PointServer))

plot_sin_alc_fixed_prior <- get_plot_df(combined_df = combined_sin_alc_fixed_df, 
                        which_player_prob = 2,
                        best_of_3 = FALSE,
                        advantage = FALSE,
                        type = "mean") |>
  mutate(set_number = as.factor(as.numeric(total_sets))) |>
  # fix last row in data set where set_number is 6, should be a 5
  mutate(set_number = ifelse(pt_number == max(pt_number), '5', set_number)) |>
  mutate(set_number = as.factor(set_number))
```

``` r
plot_sin_alc_small_prior |> ggplot(aes(x = pt_number, y = probability)) +
  geom_line(aes(y = win_prob_px, 
                color = factor("Small Prior", levels = c("Small Prior", "Large Prior", "Fixed Probability"))), 
                alpha = 0.9) +
  geom_line(data = plot_sin_alc_large_prior, aes(y = win_prob_px, color = "Large Prior"), alpha = 0.5) +
  geom_line(data = plot_sin_alc_fixed_prior, aes(y = win_prob_px, color = "Fixed Probability (0.68)"), alpha = 0.5) +
  labs(x = "Point Number",
       y = "Probability of Winning Match",
       title = "Alcaraz vs Sinner US Open Quarterfinal 2022",
       subtitle = "Probability of Alcaraz Winning Match with Different Priors",
       caption = "Comparing Different Prior Distributions",
       color = "Server") +
  scale_color_manual(values = c("Small Prior" = "red", "Large Prior" = "blue", "Fixed Probability" = "green"),
                     labels = c("Small Prior", "Large Prior", "Fixed Probability (0.68)")) +
  coord_cartesian(ylim = c(0, 1),
                  xlim = c(0, nrow(plot_sin_alc_small_prior))) +
  scale_colour_viridis_d(end = 0.9) +
  theme_bw(base_size = 14) +
  annotate("text", x = 110, y = 0.2, label = "Starting Win-Serve Probabilities:", size = 3.5, color = "black") +
  annotate("text", x = 110, y = 0.15, 
           label = paste0("'Small Prior - '*p[alcaraz]: 0.6229*', '*p[sinner]: 0.5606"), size = 3.5, color = "black",
           parse = TRUE) +
  annotate("text", x = 110, y = 0.1, 
           label = paste0("'Large Prior - '*p[alcaraz]: 0.61768*', '*p[sinner]: 0.6056"), size = 3.5, color = "black",
           parse = TRUE) +
  annotate("text", x = 110, y = 0.05, 
           label = "'Fixed Probability - '*p[alcaraz]: 0.68*', '*p[sinner]: 0.68", size = 3.5, color = "black",
           parse = TRUE)
```

    Scale for colour is already present.
    Adding another scale for colour, which will replace the existing scale.

![](README_files/figure-commonmark/unnamed-chunk-10-1.png)

Using different size priors changes the probabilities of Alcaraz and
Sinner winning a point on their serve at the start of the match, and
lead to different probabilities of Alcaraz winning the overall match.