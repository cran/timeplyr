% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/growth_rate.R
\name{growth_rate}
\alias{growth_rate}
\title{Fast Growth Rates}
\usage{
growth_rate(x, na.rm = FALSE, log = FALSE, inf_fill = NULL)
}
\arguments{
\item{x}{Numeric vector.}

\item{na.rm}{Should missing values be removed when calculating window?
Defaults to \code{FALSE}. When \code{na.rm = TRUE} the size of the rolling windows
are adjusted to the number of non-\code{NA} values in each window.}

\item{log}{If \code{TRUE} then growth rates are calculated on the log-scale.}

\item{inf_fill}{Numeric value to replace \code{Inf} values with.
Default behaviour is to keep \code{Inf} values.}
}
\value{
\code{numeric(1)}
}
\description{
Calculate the rate of percentage
change per unit time.
}
\details{
It is assumed that \code{x} is a vector of values with
a corresponding time index that increases regularly
with no gaps or missing values.

The output is to be interpreted as the average percent change per unit time.

For a rolling version that can calculate rates as you move through time,
see \code{roll_growth_rate}.

For a more generalised method that incorporates
time gaps and complex time windows,
use \code{time_roll_growth_rate}.

The growth rate can also be calculated using the
geometric mean of percent changes.

The below identity should always hold:
\preformatted{
`tail(roll_growth_rate(x, window = length(x)), 1) == growth_rate(x)`
}
}
\examples{
library(timeplyr)
\dontshow{
.n_dt_threads <- data.table::getDTthreads()
.n_collapse_threads <- collapse::get_collapse()$nthreads
data.table::setDTthreads(threads = 2L)
collapse::set_collapse(nthreads = 1L)
}
set.seed(42)
initial_investment <- 100
years <- 1990:2000
# Assume a rate of 8\% increase with noise
relative_increases <- 1.08 + rnorm(10, sd = 0.005)

assets <- Reduce(`*`, relative_increases, init = initial_investment, accumulate = TRUE)
assets

# Note that this is approximately 8\%
growth_rate(assets)

# We can also calculate the growth rate via geometric mean

rel_diff <- exp(diff(log(assets)))
all.equal(rel_diff, relative_increases)

geometric_mean <- function(x, na.rm = TRUE, weights = NULL){
  exp(collapse::fmean(log(x), na.rm = na.rm, w = weights))
}

geometric_mean(rel_diff) == growth_rate(assets)

# Weighted growth rate

w <- c(rnorm(5)^2, rnorm(5)^4)
geometric_mean(rel_diff, weights = w)

# Rolling growth rate over the last n years
roll_growth_rate(assets)

# The same but using geometric means
exp(roll_mean(log(c(NA, rel_diff))))

# Rolling growth rate over the last 5 years
roll_growth_rate(assets, window = 5)
roll_growth_rate(assets, window = 5, partial = FALSE)

## Rolling growth rate with gaps in time

years2 <- c(1990, 1993, 1994, 1997, 1998, 2000)
assets2 <- assets[years \%in\% years2]

# Below does not incorporate time gaps into growth rate calculation
# But includes helpful warning
time_roll_growth_rate(assets2, window = 5, time = years2)
# Time step allows us to calculate correct rates across time gaps
time_roll_growth_rate(assets2, window = 5, time = years2, time_step = 1) # Time aware
\dontshow{
data.table::setDTthreads(threads = .n_dt_threads)
collapse::set_collapse(nthreads = .n_collapse_threads)
}
}
\seealso{
\link{roll_growth_rate} \link{time_roll_growth_rate}
}
