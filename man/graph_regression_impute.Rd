\name{graph_regression_impute}
\alias{graph_regression_impute}
\title{Iterative Linear Imputation Under a Fixed Supplied Graph}
\usage{
graph_regression_impute(data, graph, max_iter = 10L,
  tol = 1e-6, initial = NULL)
}
\arguments{
\item{data}{A numeric matrix or data frame with at least five rows, unique
column names, and at least one observed value per column. Missing values are
represented by \code{NA}.}
\item{graph}{A square zero-diagonal 0/1 adjacency matrix. Entry
\code{graph[i, j] = 1} includes variable \code{i} as a predictor for variable
\code{j}. Symmetric entries represent an undirected adjacency and allow each
variable to predict the other. Dimension names, when supplied, must match data
column names. \code{NULL} includes all other variables as predictors.}
\item{max_iter}{Maximum number of simultaneous imputation updates.}
\item{tol}{Stop when the maximum absolute change at missing positions is at
most this nonnegative tolerance.}
\item{initial}{Optional complete numeric matrix or data frame with the same
dimensions and column names as \code{data}. Named columns are aligned to
\code{data}; original observed values override any supplied initialization.
The default initializes missing cells with column means.}
}
\value{
A list with completed matrix \code{data}, validated \code{graph},
\code{trace} (iteration, maximum absolute change, and number of mean fallbacks),
logical \code{converged}, fitted \code{coefficients} from the last update, and
\code{fallback_nodes}. Coefficients are \code{NULL} for variables without missing
cells or whose final observed design is rank deficient. Complete data have an
empty trace and \code{converged = TRUE}.
}
\description{
Fits linear regressions to observed responses using predictors selected by a
fixed graph, updates missing responses, and preserves original observations.
}
\details{
Each regression includes an intercept and uses only rows where its response was
originally observed. Predictor values come from the previous completed matrix;
all missing cells are then updated simultaneously. A node with no predictors
uses its observed mean. If its observed design is rank deficient, the node uses
the observed mean, reports the fallback, and emits a warning. There is no random
residual draw or multiple-imputation uncertainty assessment.

This is a fixed-graph, linear adaptation of the observed-response regression
update in Section 3.1.2, equation (3.5), of the supplied Chinese thesis. Predictors
refer to columns of the same input row. Time lags must be encoded explicitly in
the input columns, for example by \code{lag_windows}. This function does not
learn a graph, implement the thesis's proxy discovery operator, reconstruct
unobserved fine-time states, or inherit its conditional convergence and causal
identification claims. With reciprocal predictor relations the iteration may
fail to converge; \code{converged} and \code{trace} report the numerical stopping
criterion actually used.
}
\references{
\emph{Causal discovery and missing-data imputation for subsampled time series
based on proxy variables} (Chinese thesis supplied as \code{论文正文.pdf}),
Section 3.1.2, printed page 25, equations (3.4)--(3.6).
}
\seealso{\code{\link{lag_windows}}, \code{\link{mean_impute}}}
\examples{
x <- cbind(X = 1:8, Y = 3 + 2 * (1:8))
x[c(3, 6), "Y"] <- NA
g <- matrix(0, 2, 2, dimnames = list(colnames(x), colnames(x)))
g["X", "Y"] <- 1
fit <- graph_regression_impute(x, g)
fit$data
fit$trace
}
