library(causalmiss)
s <- simulate_causal_data(n = 400, missing = 0.2, mechanism = "mar", seed = 42)
cat("Missing fractions:\n")
print(colMeans(is.na(s$incomplete)))

fit <- iterative_discovery(s$incomplete, max_iter = 5)
print(fit)
print(fit$trace)
stopifnot(!anyNA(fit$data),
          all(fit$data[!is.na(s$incomplete)] == s$incomplete[!is.na(s$incomplete)]))

dr <- dr_impute(s$incomplete, graph = s$dag)
cat("Fixed known-graph calibration diagnostics:\n")
print(dr$diagnostics[, c("target", "status", "correction", "calibration_residual")])

source_labels <- rep(c("site_A", "site_B"), each = 200)
mi <- source_mi(s$incomplete, source = source_labels, m = 5, max_iter = 5,
                graph = s$skeleton, seed = 17)
pooled_test <- pooled_ci_test(mi, "X1", "X4", given = "X3", source = source_labels)
cat("Pooled approximate Fisher-z test:\n")
print(pooled_test[c("estimate", "within", "between", "total", "df", "p.value")])
pooled_graph <- discover_skeleton(mi, source = source_labels)
print(pooled_graph)

windows <- lag_windows(s$complete, lags = 1, step = 1)
cat("Lag window dimensions:", dim(windows), "\n")
if (interactive()) plot(fit$graph, main = "Regression-imputed skeleton")
