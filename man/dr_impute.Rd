\name{dr_impute}
\alias{dr_impute}
\title{Graph-guided calibrated imputation for continuous data}
\usage{
dr_impute(data, graph = NULL, outcome_predictors = NULL,
  propensity_predictors = NULL, clip = 0.01, calibration_tol = 1e-6,
  initial = NULL)
}
\arguments{
\item{data}{Numeric matrix or data frame with unique column names. Missing values are \code{NA}.}
\item{graph}{Optional numeric 0/1 adjacency matrix. Entry \code{graph[i, j] = 1} means an edge from column \code{i} to column \code{j}; two symmetric entries represent an undirected edge. If dimnames are supplied, both axes must match the data names.}
\item{outcome_predictors}{Optional named list of character vectors overriding predictors for particular targets. Defaults are incoming and undirected neighbors when a graph is supplied, or all other columns otherwise.}
\item{propensity_predictors}{Optional named list of character vectors. Predictors must be fully observed. Defaults are fully observed graph neighbors, or fully observed other columns if no graph is supplied. The target itself is excluded.}
\item{clip}{Bound used to clip fitted observation probabilities to \code{[clip, 1 - clip]}; must be strictly between 0 and 0.5.}
\item{calibration_tol}{Positive maximum absolute error for the normalization and scaled calibration moments.}
\item{initial}{Optional complete numeric starting matrix or data frame with identical dimensions and column order. Observed entries are restored from \code{data}. If omitted, missing entries start at observed column means.}
}
\description{
Performs one pass of linear outcome regression, logistic observation modeling,
and positive empirical-likelihood calibration. Targets are processed in ascending
order of missingness. Only missing entries are replaced.
}
\details{
The implementation follows equations 12--20 and the variable-ordering step of
Peng, Qiu and Zhou's supplied manuscript. For each target, let \eqn{w_i} be its
fitted observation probability and \eqn{\mu_i} its fitted conditional mean. The
calibration vector is \eqn{\eta_i = (1-w_i)\mu_i}, centered using all rows. Positive
weights solve the centered outcome and observation-probability moment equations.
One scalar weighted residual sum, computed using observed target rows, is added
to every missing prediction. The inverse-denominator weight form is used, as
required by the manuscript's moment equations and normalization constraints.

This first implementation is for continuous data and a MAR analysis with fully
observed propensity covariates. If an outcome predictor has missing values,
its current mean-initialized or previously updated values are used; that step is
a plug-in approximation. Symmetric graph edges are included in the outcome
predictor set without selecting a unique causal orientation.

The calibration checks a positive denominator, normalization, and both moments.
If calibration is infeasible or fails numerically, a warning is emitted and the
target is explicitly marked \code{regression_fallback}. Its missing entries
then receive only the regression prediction. Rank-deficient nuisance designs
produce an error. Logistic fit warnings and clipping rates are retained.

Doubly robust mean-estimation arguments require their identifying assumptions
and correctly specified nuisance models. This deterministic completed dataset
does not recover missing-entry noise or preserve the full joint distribution.
The function supplies no general MNAR identification, causal-graph recovery,
or uncertainty guarantee. Clipping can change the target of the calibration.
}
\value{
A list of class \code{cm_dr_imputation} with:
\item{data}{Completed numeric data frame. Observed entries are unchanged.}
\item{diagnostics}{One row per incomplete target, with status, residual correction,
  moment error, fitted marginal observation probability, minimum denominator,
  weight sum, clipping rate, predictor names, fallback reason, and model warnings.}
\item{models}{Low-level fitted linear and logistic models, nuisance predictions,
  observation probabilities, and calibration results by target.}
}
\references{
Peng, Y., Qiu, Y., and Zhou, Y. \emph{Doubly Robust Causal Structure Learning
Under Missing Data, with an Application to Health Survey Data}. Supplied
manuscript, sections 3.3 and 4.2, equations 12--20.

Qin, J., Shao, J., and Zhang, B. (2008). Efficient and doubly robust imputation
for covariate-dependent missing responses. \emph{Journal of the American
Statistical Association}, 103, 797--810.
\doi{10.1198/016214508000000238}.
}
\examples{
set.seed(20)
x <- rnorm(150)
y <- 1 + 2 * x + rnorm(150)
y[runif(150) > plogis(1 + 0.3 * x)] <- NA
fit <- dr_impute(data.frame(x = x, y = y))
fit$diagnostics[, c("target", "status", "correction")]
stopifnot(!anyNA(fit$data))
}
