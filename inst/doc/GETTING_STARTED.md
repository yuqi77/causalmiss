# Getting started with causalmiss 0.1.0

## Installation and help

Install the delivered source tarball with `install.packages(path, repos=NULL,
type="source")`. Windows also accepts the delivered zip with `type="win.binary"`.
Load `library(causalmiss)` and use `help(package="causalmiss")`.

## One small incomplete dataset

```r
library(causalmiss)
s <- simulate_causal_data(n = 400, missing = 0.2, mechanism = "mar", seed = 42)
colMeans(is.na(s$incomplete))
fit <- iterative_discovery(s$incomplete, max_iter = 5)
fit$trace
fit$converged
fit$graph$adjacency
plot(fit$graph)
stopifnot(!anyNA(fit$data))
stopifnot(all(fit$data[!is.na(s$incomplete)] == s$incomplete[!is.na(s$incomplete)]))
```

The fit contains completed data and an undirected skeleton. Use the observed
change trace to assess stopping. A FALSE convergence flag is a valid reported
iteration-limit outcome. This synthetic example does not reproduce a paper's tables.

## Empirical-likelihood correction with a supplied graph

```r
dr <- dr_impute(s$incomplete, graph = s$dag)
dr$diagnostics[, c("target", "status", "correction", "calibration_residual")]
```

Here the graph is the simulator's known DAG. Outcome predictors follow incoming
arcs; propensity predictors use fully observed neighbours. Read `?dr_impute` and
`?dr_calibrate` before interpreting a result. A regression fallback is explicitly
marked and warned. The method map records a manuscript formula ambiguity and
the corrected computation relative to supplied research scripts.

## Source-aware multiple imputation and pooled skeleton

```r
source <- rep(c("site_A", "site_B"), each = 200)
mi <- source_mi(s$incomplete, source = source, m = 5, max_iter = 5,
                graph = s$skeleton, seed = 17)
length(mi)
attr(mi, "diagnostics")
test <- pooled_ci_test(mi, "X1", "X4", given = "X3", source = source)
test[c("estimate", "within", "between", "total", "df", "p.value")]
g <- discover_skeleton(mi, source = source, max_cond = 2)
plot(g)
```

The optional graph stays fixed during FCS. Source labels enter both imputation
and CI conditioning. In this example the labels are artificial groups, not a
real multi-source survey. Proper MI and comparable sources remain modeling assumptions.

## Lagged windows

```r
w <- lag_windows(s$complete, lags = 2, step = 1)
head(w)
attributes(w)
```

This is row alignment only. The demonstration reuses independent data to show
the API; it does not turn that dataset into a time-series experiment. Apply the
helper separately within each actual series. Ordinary CI tests in this release
do not adjust for temporal dependence or overlapping windows.

## Complete installed example

```r
source(system.file("examples", "toy_workflow.R", package = "causalmiss"))
```

The example reports completion diagnostics, a pooled test and graphs. It writes
no files unless you explicitly add output commands.
