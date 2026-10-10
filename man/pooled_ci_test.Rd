\name{pooled_ci_test}
\alias{pooled_ci_test}
\title{Pool Gaussian Conditional Independence Tests Across Imputations}
\usage{
pooled_ci_test(imputations, x, y, given = character(), source = NULL)
}
\arguments{
\item{imputations}{A list of at least two complete finite numeric matrices or numeric data frames with identical dimensions and column names. Rows must refer to the same observations in the same order.}
\item{x, y}{Distinct single data column names or integer indices.}
\item{given}{Optional data column names or integer indices to condition on, excluding \code{x} and \code{y}.}
\item{source}{Optional complete vector of source labels, converted to factor contrasts, or a finite numeric matrix of additional conditioning columns. Numeric labels in a vector are treated as categories.}
}
\value{A list with \code{p.value}, \code{statistic}, \code{df}, \code{estimate} (the pooled Fisher-z estimate), \code{within}, \code{between}, \code{total}, \code{n}, \code{m}, and the \code{conditioning_rank}, partial \code{correlations}, \code{transformed} estimates and \code{variances} for each imputation.}
\description{Computes partial correlations in each completed data set, transforms them with Fisher's z transformation, and applies Rubin's variance and degrees of freedom rules.}
\details{
This implements the unweighted Gaussian combining rules in Woldemariam, Zhou and Qiu (2026), equations (8)--(12), PDF pages 19--20. The within-imputation variance is \eqn{1/(n-r-3)}, where \eqn{r} is the numerical rank of the conditioning design excluding its intercept. Source contrasts are included in that rank. The total variance is the mean within-imputation variance plus \eqn{(1+1/m)} times the between-imputation sample variance. If between-imputation variance is zero, the reference distribution is standard normal (infinite Rubin degrees of freedom).

The p-value is a two-sided approximate test of zero partial correlation. Interpreting it as conditional independence requires a suitable Gaussian linear model and appropriate imputations. Valid p-values for individual tests do not imply simultaneous error control or certain graph recovery. Source adjustment removes linear or source-specific mean effects; it cannot repair arbitrary source heterogeneity. Correlations at numerical boundaries are clipped to \eqn{[-1+10^{-15},1-10^{-15}]} before transformation. No survey weights, cluster or stratum design, design-based variance, or Barnard--Rubin survey degrees of freedom are implemented.
}
\references{
Woldemariam, A. A., Zhou, Y., and Qiu, Y. (2026).
Causal discovery with incomplete data integrated from multiple sources.
\emph{Journal of Survey Statistics and Methodology}.
\doi{10.1093/jssam/smag016}.
}
\examples{
set.seed(1)
z <- rnorm(100)
d <- cbind(x = z + rnorm(100), y = z + rnorm(100), z = z)
d[1:10, "x"] <- NA
completed <- source_mi(d, m = 3, max_iter = 3, seed = 2)
pooled_ci_test(completed, "x", "y", given = "z")$p.value
}
