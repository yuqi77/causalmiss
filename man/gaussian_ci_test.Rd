\name{gaussian_ci_test}
\alias{gaussian_ci_test}
\title{Gaussian Conditional Independence Test}
\usage{gaussian_ci_test(data, x, y, given = character(), source = NULL)}
\arguments{
\item{data}{Complete numeric matrix or data frame.}
\item{x, y}{Distinct single column names or indices.}
\item{given}{Conditioning column names or indices excluding x and y.}
\item{source}{Optional complete source labels, or numeric covariate matrix.
Labels are converted to factor contrasts and always included in the conditioning set.}
}
\description{Residualize two variables on an intercept, conditioning variables,
and source contrasts, then apply the Gaussian Fisher-z approximation.}
\details{The Fisher transform is \eqn{z = atanh(r)} and its variance is
\eqn{1/(n-k-3)}, where k is the actual conditioning rank excluding the intercept.
Constant or conditionally degenerate variables are rejected. Complete data and
independent rows are required for the usual test interpretation.}
\value{A list with p.value, statistic, estimate, variance, correlation, n,
conditioning_rank and method.}
\examples{
d <- simulate_causal_data(n = 300, missing = 0)$complete
gaussian_ci_test(d, "X1", "X4", given = "X3")
}
