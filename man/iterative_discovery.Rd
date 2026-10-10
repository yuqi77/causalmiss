\name{iterative_discovery}
\alias{iterative_discovery}
\alias{print.cm_iterative}
\title{Alternate Graph-Guided Imputation and Skeleton Discovery}
\usage{
iterative_discovery(data, max_iter = 5L, tol = 1e-5, alpha = 0.05,
max_cond = 2L, imputation = c("regression", "dr"), clip = 0.01)
\method{print}{cm_iterative}(x, ...)
}
\arguments{
\item{data}{Incomplete continuous numeric data.}
\item{max_iter}{Positive iteration limit.}
\item{tol}{Positive absolute threshold for the largest completed-data change.}
\item{alpha, max_cond}{Arguments passed to discover_skeleton.}
\item{imputation}{Graph-guided linear regression or empirical-likelihood correction.}
\item{clip}{Propensity clipping threshold passed to dr_impute.}
\item{x}{A cm_iterative object.}
\item{...}{Unused additional print arguments.}
}
\description{Start with mean initialization and alternate a graph-guided
imputation pass with stable Gaussian skeleton search.}
\details{This is an educational adaptation of the papers' alternating design.
It uses PC-stable skeleton search rather than GES or the time-series proxy
orientation method. Stopping requires both zero edge changes and completed-data
change at most tol. Hitting the limit is reported as converged=FALSE.
This criterion is numerical and does not establish global optimization or
causal identification. The dr option reports regression fallbacks in its trace.}
\value{A cm_iterative list with data, graph, trace, converged, imputation and fits.}
\examples{
s <- simulate_causal_data(n = 200)
fit <- iterative_discovery(s$incomplete, max_iter = 3)
print(fit)
fit$trace
}
