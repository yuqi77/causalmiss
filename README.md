# causalmiss

Small R tools for causal discovery with incomplete continuous data.

**Version 0.1.0 is a local first release.** It implements selected linear Gaussian
components from three supplied manuscripts, with explicit method-to-code mapping.
The package depends only on packages shipped with R (R >= 4.1.0), needs no compiler,
and includes synthetic examples and base-R regression tests.

Author and maintainer: Yuqi Qiu <yqqiu@fem.ecnu.edu.cn>.

## Install the local release

From R, using the actual path to the delivered file:

```r
install.packages("path/to/causalmiss_0.1.0.tar.gz", repos = NULL, type = "source")
library(causalmiss)
```

Windows users can install `causalmiss_0.1.0.zip` with `type = "win.binary"`.
The source release also works on macOS and Linux. A repository and GitHub
installation URL will be added when public hosting is selected.

## Quick start

```r
library(causalmiss)
s <- simulate_causal_data(n = 400, mechanism = "mar", seed = 42)

# Alternating graph-guided regression and Gaussian skeleton search.
fit <- iterative_discovery(s$incomplete, max_iter = 5)
print(fit)
fit$trace
plot(fit$graph)

# Fixed-graph empirical-likelihood correction, with numerical diagnostics.
dr <- dr_impute(s$incomplete, graph = s$dag)
dr$diagnostics

# Source-aware multiple imputation and pooled tests.
source <- rep(c("site_A", "site_B"), each = 200)
mi <- source_mi(s$incomplete, source = source, m = 5, max_iter = 5, seed = 17)
pooled_ci_test(mi, "X1", "X4", given = "X3", source = source)
pooled_graph <- discover_skeleton(mi, source = source)

# Construct observed-scale past/current windows.
windows <- lag_windows(s$complete, lags = 1, step = 1)
```

The installed tutorial gives complete executable examples:

```r
file.show(system.file("doc", "GETTING_STARTED.md", package = "causalmiss"))
source(system.file("examples", "toy_workflow.R", package = "causalmiss"))
help(package = "causalmiss")
```

## Implemented scope

| Component | First-release behavior | Manuscript connection |
|---|---|---|
| `dr_impute()` | Linear outcome/logistic observation models; corrected calibration and scalar residual adjustment; explicit numerical diagnostics | Complete manuscript, Section 4.3, equations 16-20 |
| `source_mi()` | Bayesian linear FCS, source contrasts, optional fixed-graph propensity covariate | JSSAM, Section 4.1 and Algorithm 1, pp. 13-17 |
| `pooled_ci_test()` | Rubin pooling of Fisher-transformed partial correlations, source conditioning | JSSAM, equations 8-12 |
| `lag_windows()` | Lagged observed-scale row alignment | Chinese manuscript, equations 3.1-3.2 |
| `graph_regression_impute()` | Fixed-graph linear updates preserving observed entries | Chinese manuscript, equations 3.4-3.6, linear adaptation |
| `discover_skeleton()` | PC-stable adjacency search, complete or multiply imputed input | Shared Gaussian discovery component |
| `iterative_discovery()` | Alternating imputation and PC-stable skeleton search | Adaptation of the alternating framework |

Skeleton search does not determine edge direction or return a CPDAG. This release
does not implement GES, the full time-series proxy orientation algorithm,
complex-survey design corrections, discrete/nonlinear models, or general MNAR
identification. Ordinary Fisher-z inference requires independent rows; overlapping
time windows alone do not satisfy that assumption. A doubly robust mean correction
does not establish recovery of each missing value or the causal graph.

See [the method map](inst/doc/METHODS.md), [Chinese guide](README.zh-CN.md),
[development guide](docs/DEVELOPMENT.zh-CN.md), and [publication guide](docs/PUBLISHING.zh-CN.md).

## Development and checks

```sh
R CMD build causalmiss --no-build-vignettes --no-manual
R CMD check causalmiss_0.1.0.tar.gz --no-manual
R CMD INSTALL causalmiss_0.1.0.tar.gz
```

From the repository directory, `Rscript tools/build_release.R` builds and checks
the package and records logs outside the package source directory. CI performs
the same check on Windows, macOS and Linux after the repository is published.
The package uses maintained `.Rd` files rather than requiring roxygen2 at build time.

## Citation and license

Use `citation("causalmiss")` for software and method citations. The software is
MIT licensed. Manuscript PDFs, original survey data and supplied research code
are not bundled in this package. Their rights and access rules are separate.
All distributed examples generate synthetic data.
