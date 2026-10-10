\name{discover_skeleton}
\alias{discover_skeleton}
\alias{print.cm_skeleton}
\alias{plot.cm_skeleton}
\title{Stable Gaussian Skeleton Search}
\usage{
discover_skeleton(data, alpha = 0.05, max_cond = 2L, source = NULL)
\method{print}{cm_skeleton}(x, ...)
\method{plot}{cm_skeleton}(x, ...)
}
\arguments{
\item{data}{Complete numeric data, or a list of at least two completed matrices
with identical dimensions, column order and row identities.}
\item{alpha}{Significance level between zero and one.}
\item{max_cond}{Maximum conditioning set size; a small bound is intended for toy data.}
\item{source}{Complete source labels or numeric source covariates.}
\item{x}{A cm_skeleton object.}
\item{...}{Additional plot arguments; unused for printing.}
}
\description{Run the adjacency-search portion of PC-stable with Gaussian tests
or pooled Fisher-z tests across completed datasets.}
\details{Neighbours are frozen within each conditioning level. Conditioning
sets from both endpoints are considered. The output is an undirected skeleton;
collider orientation and Meek rules are outside this version. Markov,
faithfulness and independent-sampling assumptions underlie causal interpretation.
An insufficient conditioning bound may leave extra edges. Errors from
degenerate tests are propagated instead of treating them as independence.}
\value{A cm_skeleton list containing adjacency, sepsets, tests, alpha,
max_cond, n, m and method. adjacency is symmetric with zero diagonal.}
\examples{
d <- simulate_causal_data(n = 400, missing = 0)$complete
g <- discover_skeleton(d)
print(g)
plot(g)
}
