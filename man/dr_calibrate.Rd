\name{dr_calibrate}
\alias{dr_calibrate}
\title{Calibrate supplied outcome means and observation probabilities}
\usage{
dr_calibrate(y, observed, mu, propensity, tol = 1e-6)
}
\arguments{
\item{y}{Numeric response vector. Values at observed rows must be finite. Unobserved rows may be \code{NA}.}
\item{observed}{Logical observation indicator with no missing values.}
\item{mu}{Finite fitted conditional means, one per row.}
\item{propensity}{Finite fitted observation probabilities strictly between 0 and 1, one per row. No clipping is applied by this function.}
\item{tol}{Positive maximum error for the normalization and scaled calibration moments.}
}
\description{
Computes empirical-likelihood weights and the scalar residual correction using
supplied nuisance predictions. This function makes the manuscript equation
implementation inspectable independently of nuisance model fitting.
}
\details{
Uses the centered per-row vector \eqn{(1-w_i)\mu_i} and the inverse-denominator
form implied by the moment equations. Calibration weights must be positive and
normalized, and satisfy the outcome and observation-probability moments.
An infeasible calibration emits a warning and returns an explicitly marked
regression fallback with zero correction. See \code{\link{dr_impute}} for the
method scope and assumptions.
}
\value{
A list containing \code{ok}, \code{status}, \code{reason}, \code{correction},
\code{residual}, \code{theta}, \code{xi}, \code{min_denominator}, and
\code{weight_sum}. On success, \code{p} and \code{q} are weight vectors indexed
by \code{observed_rows}, and \code{eta_centered} is the centered calibration
vector on all rows. The \code{imputed} vector contains \code{mu + correction}
on all rows; \code{data} preserves observed responses and replaces only
unobserved entries.
}
\seealso{\code{\link{dr_impute}}}
\examples{
y <- c(1, 3, NA, NA)
fit <- dr_calibrate(y, c(TRUE, TRUE, FALSE, FALSE),
                    mu = rep(2, 4), propensity = rep(0.5, 4))
fit$data
}
