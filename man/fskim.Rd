% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fskim.R
\name{fskim}
\alias{fskim}
\title{Fast alternative to \code{skimr::skim()}}
\usage{
fskim(data, hist = FALSE)
}
\arguments{
\item{data}{A data frame.}

\item{hist}{Logical. If \code{TRUE}, histogram spark graphs are produced
in the numeric summary.}
}
\value{
A list of length 7 with the elements:
\itemize{
\item \code{nrow} - Number of rows
\item \code{ncol} - Number of columns
\item \code{logical} - A \code{tibble} summary of the logical columns.
\item \code{numeric} - A \code{tibble} summary of the numeric columns.
\item \code{date} - A \code{tibble} summary of the date columns.
\item \code{datetime} - A \code{tibble} summary of the datetime columns.
\item \code{categorical} - A \code{tibble} summary of the categorical columns.
}
}
\description{
Inspired by the brilliant \code{skimr} package, this is a fast
alternative that provides an un-grouped data frame summary.
}
\details{
\code{collapse} is used to compute the summary statistics and
\code{data.table} is used to wrangle the data frames. \cr
Character vectors are internally converted to factors using
\code{collapse::qF()}.
}
\examples{
library(timeplyr)
library(nycflights13)
\dontshow{
.n_dt_threads <- data.table::getDTthreads()
.n_collapse_threads <- collapse::get_collapse()$nthreads
data.table::setDTthreads(threads = 2L)
collapse::set_collapse(nthreads = 1L)
}
fskim(flights)
\dontshow{
data.table::setDTthreads(threads = .n_dt_threads)
collapse::set_collapse(nthreads = .n_collapse_threads)
}
}
