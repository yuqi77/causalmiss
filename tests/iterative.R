library(causalmiss)
s <- simulate_causal_data(n = 300, missing = 0.15, seed = 7)
fit <- iterative_discovery(s$incomplete, max_iter = 3)
stopifnot(!anyNA(fit$data), all(is.finite(fit$data)),
          identical(fit$data[!is.na(s$incomplete)], s$incomplete[!is.na(s$incomplete)]),
          identical(fit$graph$adjacency, discover_skeleton(fit$data)$adjacency),
          nrow(fit$trace) <= 3, is.logical(fit$converged))
complete_fit <- iterative_discovery(s$complete, max_iter = 3)
stopifnot(complete_fit$converged, nrow(complete_fit$trace) == 1,
          identical(complete_fit$data, s$complete))
dr_fit <- suppressWarnings(iterative_discovery(s$incomplete, max_iter = 2, imputation = "dr"))
stopifnot(all(is.finite(dr_fit$data)), all(dr_fit$trace$fallbacks >= 0),
          identical(dr_fit$data[!is.na(s$incomplete)], s$incomplete[!is.na(s$incomplete)]))
cat("Installed alternating pipeline checks passed.\n")
