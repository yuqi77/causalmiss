library(causalmiss)
error <- function(expr) inherits(tryCatch(force(expr), error = identity), "error")

set.seed(123)
state <- .Random.seed
s <- simulate_causal_data(n = 2500, missing = 0, seed = 23)
stopifnot(identical(state, .Random.seed), identical(s, simulate_causal_data(n = 2500, missing = 0, seed = 23)))
d <- s$complete
# Compare the CI statistic against a hand residual calculation.
z <- cbind(1, d[, "X3"])
a <- qr.resid(qr(z), d[, "X1"])
b <- qr.resid(qr(z), d[, "X4"])
hand <- atanh(sum(a * b) / sqrt(sum(a^2) * sum(b^2))) * sqrt(nrow(d) - 4)
test <- gaussian_ci_test(d, "X1", "X4", "X3")
stopifnot(abs(hand - test$statistic) < 1e-12, test$conditioning_rank == 1)
scaled <- d
scaled[, "X1"] <- scaled[, "X1"] * 10 + 2
stopifnot(abs(gaussian_ci_test(scaled, "X1", "X4", "X3")$p.value - test$p.value) < 1e-12)
shifted <- d
shifted[, "X1"] <- shifted[, "X1"] + 1e10
stopifnot(abs(gaussian_ci_test(shifted, "X1", "X4", "X3")$p.value - test$p.value) < 1e-4)
tiny <- d * 1e-10
stopifnot(abs(gaussian_ci_test(tiny, "X1", "X4", "X3")$p.value - test$p.value) < 1e-12)
g <- discover_skeleton(d, alpha = 0.001, max_cond = 2)
stopifnot(identical(unname(g$adjacency), unname(s$skeleton)),
          identical(g$adjacency, t(g$adjacency)), all(diag(g$adjacency) == 0))
permuted <- discover_skeleton(d[, 4:1], alpha = 0.001, max_cond = 2)
stopifnot(identical(g$adjacency, permuted$adjacency[colnames(d), colnames(d)]))
stopifnot(error(gaussian_ci_test(cbind(d, constant = 1), "constant", "X1")),
          error(discover_skeleton(d, max_cond = -1)),
          error(mean_impute(matrix(NA_real_, 10, 2))))
miss <- simulate_causal_data(n = 200)$incomplete
filled <- mean_impute(miss)
stopifnot(!anyNA(filled), identical(filled[!is.na(miss)], miss[!is.na(miss)]))
cat("Core CI, skeleton, validation and RNG checks passed.\n")
