\name{lag_windows}
\alias{lag_windows}
\title{Construct Current and Past Observation Windows}
\usage{
lag_windows(data, lags = 1L, step = 1L)
}
\arguments{
\item{data}{A numeric matrix or data frame with at least five rows, unique
column names, and at least one observed value per column. Rows must be ordered
from earlier to later observations within a single trajectory.}
\item{lags}{Distinct positive integer lag labels. The current observation,
labelled lag zero, is included automatically. Labels are sorted in ascending order.}
\item{step}{A positive integer row interval. Lag \code{h} uses the row
\code{h * step} positions before the current row.}
}
\value{
A numeric matrix with columns arranged in blocks for lag zero followed by the
requested lags. Column names have the form \code{variable_lag0}. Missing values
are preserved. Attribute \code{row_index} gives each output row's current input
row. Attribute \code{column_map} records the output column, input variable, lag
label, and row offset; attribute \code{step} records the supplied row interval.
}
\description{
Forms aligned observation windows without filling missing values or using future
rows as lagged predictors.
}
\details{
For one lag and interval \code{k}, output row \code{r} contains
\code{(data[r, ], data[r - k, ])}. Reversing the two column blocks yields the
two-slice pair in Section 3.1.1, equations (3.1)--(3.2), of the supplied Chinese
thesis. This function constructs the data layout only; it does not implement
proxy conditional-independence tests or identify latent system-time causal edges.
\code{step} counts rows in the supplied data, not unobserved system-time steps.
If rows are already subsampled, \code{step = 1} means adjacent observed rows.
For several independent trajectories, call this function separately on each
trajectory and then combine the output matrices. Concatenating trajectories
before window construction would create artificial transitions at boundaries.
}
\references{
\emph{Causal discovery and missing-data imputation for subsampled time series
based on proxy variables} (Chinese thesis supplied as \code{论文正文.pdf}),
Section 3.1.1, printed pages 23--24, equations (3.1)--(3.2).
}
\examples{
x <- cbind(X = 1:8, Y = 11:18)
x[3, "Y"] <- NA
w <- lag_windows(x, lags = c(1, 2))
attr(w, "row_index")
attr(w, "column_map")
}
