## install.packages("rstanarm")
library(rstanarm)
library(tidyverse)
## suppose that prior: normal on logit scale with mean -0.0867, sd 0.0548
## replace -0.0867 with logodds from running aug_mod() on comp_glm() and 0.0548 with standard error from aug_mod() on comp_glm()


## replace this fake point-level data with your match of interest point data at a particular state of the match
set.seed(341281818)
fake_data <- sample(c(0, 1), size = 50, replace = TRUE)
fake_df <- tibble::tibble(won_or_lost = fake_data)



# Estimate Bayesian version with stan_glm
stan_glm1 <- stan_glm(won_or_lost ~ 1,
                      data = fake_df, family = binomial,
                      ## fake_df is match of interest at
                      ## a particular state
                      prior_intercept = normal(-0.08004, 0.0548),
                      ## normal(., .) is logodds and se
                      ## from  aug_mod()
                      seed = 12345)

expit <- function(x) { exp(x) / (1 + exp(x))
}
coef(glm1) |> expit()
coef(stan_glm1) |> expit()
