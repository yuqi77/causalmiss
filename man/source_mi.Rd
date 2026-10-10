\name{source_mi}
\alias{source_mi}
\title{Source-Aware Linear Multiple Imputation}
\usage{
source_mi(data, source = NULL, m = 5, max_iter = 5,
          graph = NULL, seed = NULL)
}
\arguments{
\item{data}{Numeric matrix or numeric data frame with at least five rows and two variables. Missing entries must be represented by \code{NA}; infinities are rejected. Every variable needs observed values.}
\item{source}{Optional complete vector of source labels, converted to factor contrasts, or a finite numeric matrix of predictors. Numeric labels in a vector are treated as categories.}
\item{m}{Integer number of completed data sets, at least two.}
\item{max_iter}{Positive integer number of fully conditional specification sweeps for each imputation. This is a fixed iteration count, not a convergence criterion.}
\item{graph}{Optional fixed finite numeric or logical square adjacency matrix. An edge in either direction defines a neighborhood; diagonals are ignored. If named, both dimensions must match the data variable names.}
\item{seed}{Optional nonnegative integer seed. When supplied, the caller's random-number state is restored, including when an error occurs. Without a seed, the caller's random-number stream is used.}
}
\value{A list of \code{m} complete numeric matrices. Attributes include \code{method}, \code{iterations}, \code{graph}, \code{call}, and a \code{diagnostics} data frame with convergence, boundary, number of clipped probabilities, warning text and rank information from each missingness propensity regression. Original observed entries are preserved exactly.}
\description{Performs a small source-aware Bayesian linear fully conditional specification (FCS) imputation procedure, optionally augmented with fixed-neighborhood missingness propensities.}
\details{
The function implements a Gaussian submodule motivated by Woldemariam, Zhou and Qiu (2026), Section 4.1 and Algorithm 1, PDF pages 13--17. Missing values are initialized by sampling observed values from their own variable. Each sweep regresses each incomplete variable on the current completed values of all other variables and the source design. Under the standard improper linear-regression prior, residual variance and coefficients are sampled from their posterior and missing responses are sampled from the resulting predictive normal distribution. Numerical standardization preserves the specified regression model and its measurement units after back transformation. Rank-deficient predictor columns are removed by QR decomposition. Models with no residual degrees of freedom or variation are rejected.

When \code{graph} is supplied, each variable's original binary missingness indicator is fitted by logistic regression on its neighbors' current completed values and original missingness indicators, following equations (1)--(2). Its fitted missingness probability is added as an auxiliary predictor for that variable's imputation. Probabilities are clipped to \eqn{[10^{-6},1-10^{-6}]} for numerical stability. Propensity model convergence, boundary status, clipping and warning text are recorded in \code{attr(result, "diagnostics")}; these diagnostics should be reviewed before analysis. Any such numerical issue triggers one summary warning per call. A propensity predictor may be removed if it is constant or linearly redundant on the observed response rows.

The graph is fixed by the user: this function does not implement the paper's alternating graph estimation, propensity estimation, and Markov-equivalence stopping rule. Supplying no graph gives source-aware linear FCS without propensity augmentation. The model requires defensible conditional missing-at-random assumptions, sufficient overlap and a suitable linear Gaussian imputation model. Adding predictors does not establish these assumptions. Entirely unobserved variables cannot be recovered. Variables entirely absent within a source require untestable extrapolation from sources where they are observed; source adjustment alone does not identify those values. Mixed data types, predictive mean matching, survey weights, clusters, strata and survey variance estimation are outside this implementation.
}
\references{
Woldemariam, A. A., Zhou, Y., and Qiu, Y. (2026).
Causal discovery with incomplete data integrated from multiple sources.
\emph{Journal of Survey Statistics and Methodology}.
\doi{10.1093/jssam/smag016}.
}
\examples{
set.seed(10)
d <- cbind(x = rnorm(80), y = rnorm(80), z = rnorm(80))
d[1:12, "x"] <- NA
source <- rep(c("A", "B"), each = 40)
completed <- source_mi(d, source, m = 3, seed = 20)
anyNA(completed[[1]])
all(completed[[1]][!is.na(d)] == d[!is.na(d)])
graph <- matrix(1, 3, 3, dimnames = list(colnames(d), colnames(d)))
diag(graph) <- 0
augmented <- source_mi(d, source, m = 3, graph = graph, seed = 20)
attr(augmented, "diagnostics")
}
