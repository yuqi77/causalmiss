\name{causalmiss-package}
\alias{causalmiss-package}
\alias{causalmiss}
\docType{package}
\title{Small Tools for Causal Discovery with Incomplete Data}
\description{Selected linear Gaussian components of three manuscripts on
causal discovery with incomplete data. All examples use synthetic data.}
\details{The main discovery output is an undirected skeleton. A skeleton does
not identify causal directions. Gaussian tests require appropriate independent
sampling, model assumptions and a sufficient sample size. Missing-value
imputation does not establish general identification under missing not at random.
See the installed method map with
\code{system.file("doc", "METHODS.md", package = "causalmiss")} for manuscript
locators and the distinction between implemented formulas and adaptations.}
\author{Yuqi Qiu \email{yqqiu@fem.ecnu.edu.cn}}
\seealso{\code{\link{discover_skeleton}}, \code{\link{iterative_discovery}},
\code{\link{source_mi}}, \code{\link{dr_impute}}}
\keyword{package}
