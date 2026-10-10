\name{simulate_causal_data}
\alias{simulate_causal_data}
\title{Generate a Four-Variable Synthetic Gaussian DAG}
\usage{simulate_causal_data(n = 400L, missing = 0.2,
mechanism = c("mcar", "mar"), seed = 1L)}
\arguments{
\item{n}{Integer sample size of at least 20.}
\item{missing}{Expected missing fraction per incomplete variable in [0, 0.8).}
\item{mechanism}{MCAR or MAR; MAR missingness depends on fully observed X1.}
\item{seed}{Optional local random seed; a specified seed preserves the caller's RNG state.}
}
\description{Generate X1 and X2 independently, X3 from both, and X4 from X3,
with independent unit normal disturbances. Only X3 and X4 can be missing.}
\value{A list containing complete, incomplete, dag, skeleton and mechanism.
dag[i,j]=1 denotes i to j. This dataset is newly simulated and is not a paper's survey data.}
\examples{s <- simulate_causal_data(n = 100, mechanism = "mar")
colMeans(is.na(s$incomplete))}
