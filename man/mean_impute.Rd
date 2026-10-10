\name{mean_impute}
\alias{mean_impute}
\title{Initialize Missing Values with Observed Column Means}
\usage{mean_impute(data)}
\arguments{\item{data}{Numeric matrix or data frame with at least five rows.}}
\description{Replace missing entries with column means computed from observed entries.}
\value{A numeric matrix preserving column names and observed entries.}
\details{An all-missing column is rejected. This is an initialization tool,
not a multiple-imputation model.}
\examples{
d <- simulate_causal_data(n = 100)$incomplete
filled <- mean_impute(d)
stopifnot(!anyNA(filled))
}
