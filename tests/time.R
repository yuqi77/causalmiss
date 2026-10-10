library(causalmiss)

fails <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")

# Hand-aligned multivariate windows test the row order, lag interval, and NA mask.
x <- cbind(X = 1:8, Y = 11:18)
x[3, "Y"] <- NA_real_
w <- lag_windows(x, lags = c(2L, 1L), step = 2L)
expected <- cbind(x[5:8, ], x[3:6, ], x[1:4, ])
stopifnot(identical(dim(w), c(4L, 6L)),
          identical(unname(as.vector(w)), unname(as.vector(expected))),
          identical(attr(w, "row_index"), 5:8),
          identical(colnames(w), c("X_lag0", "Y_lag0", "X_lag1", "Y_lag1",
                                   "X_lag2", "Y_lag2")),
          identical(attr(w, "column_map")$offset, rep(c(0L, 2L, 4L), each = 2)))
# Every lagged source row must precede the corresponding current row.
map <- attr(w, "column_map")
for (j in which(map$lag > 0)) {
  source_rows <- attr(w, "row_index") - map$offset[j]
  stopifnot(all(source_rows < attr(w, "row_index")))
}
stopifnot(fails(lag_windows(x, lags = 0)),
          fails(lag_windows(x, lags = c(1, 1))),
          fails(lag_windows(x, step = 0)),
          fails(lag_windows(x, lags = 4, step = 2)))

# An exact affine outcome identifies the required regression, including intercept.
truth <- cbind(X = 1:8, Y = 3 + 2 * (1:8))
incomplete <- truth
incomplete[c(3, 6), "Y"] <- NA_real_
g <- matrix(0, 2, 2, dimnames = list(colnames(truth), colnames(truth)))
g["X", "Y"] <- 1
initial <- truth * 1000
initial[c(3, 6), "Y"] <- -1e6
fit <- graph_regression_impute(incomplete, g, initial = initial)
stopifnot(max(abs(fit$data - truth)) < 1e-10,
          identical(fit$data[!is.na(incomplete)], incomplete[!is.na(incomplete)]),
          fit$converged, nrow(fit$trace) == 2L,
          max(abs(fit$coefficients$Y - c(3, 2))) < 1e-10)

# Reversing the edge excludes X from Y's predictors; Y must use its observed mean.
reverse_fit <- graph_regression_impute(incomplete, t(g))
stopifnot(max(abs(reverse_fit$data[c(3, 6), "Y"] -
                  mean(incomplete[, "Y"], na.rm = TRUE))) < 1e-10)

# An incomplete predictor chain requires more than one simultaneous update.
chain_truth <- cbind(X = 1:8, Y = 2 * (1:8), Z = 1 + 6 * (1:8))
chain_data <- chain_truth
chain_data[c(2, 5), "Y"] <- NA_real_
chain_data[c(4, 6), "Z"] <- NA_real_
chain_graph <- matrix(0, 3, 3,
                      dimnames = list(colnames(chain_truth), colnames(chain_truth)))
chain_graph["X", "Y"] <- chain_graph["Y", "Z"] <- 1
one <- graph_regression_impute(chain_data, chain_graph, max_iter = 1L)
three <- graph_regression_impute(chain_data, chain_graph, max_iter = 3L)
stopifnot(!one$converged, max(abs(one$data[, "Z"] - chain_truth[, "Z"])) > 0.1,
          max(abs(three$data - chain_truth)) < 1e-10, three$converged)
order <- c("Z", "X", "Y")
reordered <- graph_regression_impute(chain_data[, order], chain_graph[order, order],
                                      max_iter = 3L)
stopifnot(max(abs(reordered$data[, colnames(chain_truth)] - three$data)) < 1e-10)

# A nonidentifiable design has a finite and declared mean fallback.
rank_data <- cbind(A = 1:8, B = 2 * (1:8), Y = 3 * (1:8))
rank_data[c(3, 6), "Y"] <- NA_real_
rank_graph <- matrix(0, 3, 3,
                     dimnames = list(colnames(rank_data), colnames(rank_data)))
rank_graph[c("A", "B"), "Y"] <- 1
rank_fit <- suppressWarnings(graph_regression_impute(rank_data, rank_graph))
stopifnot(identical(rank_fit$fallback_nodes, "Y"),
          length(rank_fit$coefficients) == 3L,
          is.null(rank_fit$coefficients$Y),
          all(rank_fit$data[c(3, 6), "Y"] == mean(rank_data[, "Y"], na.rm = TRUE)))

complete_fit <- graph_regression_impute(truth, g)
stopifnot(identical(complete_fit$data, truth * 1), complete_fit$converged,
          nrow(complete_fit$trace) == 0L,
          fails(graph_regression_impute(incomplete, g, initial = incomplete)),
          fails(graph_regression_impute(incomplete, g, max_iter = 0)),
          fails(graph_regression_impute(incomplete, g, tol = -1)))
