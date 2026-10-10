library(causalmiss)

# Paper equations: an independent hand calculation of all pooled components.
set.seed(810)
n <- 120L
z <- rnorm(n)
x <- z + rnorm(n)
y <- z + rnorm(n)
d1 <- cbind(x = x, y = y, z = z)
d2 <- d1
d2[, "x"] <- d2[, "x"] + rnorm(n, sd = 0.3)
d3 <- d1
d3[, "y"] <- d3[, "y"] + rnorm(n, sd = 0.4)
input <- list(d1, d2, d3)
result <- pooled_ci_test(input, "x", "y", "z")
manual_z <- vapply(input, function(d) {
  rx <- stats::lm(d[, "x"] ~ d[, "z"])$residuals
  ry <- stats::lm(d[, "y"] ~ d[, "z"])$residuals
  atanh(stats::cor(rx, ry))
}, numeric(1L))
manual_w <- 1 / (n - 1 - 3)
manual_b <- stats::var(manual_z)
manual_v <- manual_w + (1 + 1 / 3) * manual_b
manual_df <- (3 - 1) * (1 + 3 * manual_w / (4 * manual_b))^2
manual_t <- mean(manual_z) / sqrt(manual_v)
stopifnot(isTRUE(all.equal(result$estimate, mean(manual_z))),
          isTRUE(all.equal(result$within, manual_w)),
          isTRUE(all.equal(result$between, manual_b)),
          isTRUE(all.equal(result$total, manual_v)),
          isTRUE(all.equal(result$df, manual_df)),
          isTRUE(all.equal(result$statistic, manual_t)),
          isTRUE(all.equal(result$p.value,
                           2 * stats::pt(abs(manual_t), manual_df, lower.tail = FALSE))))

# Identical imputations have zero between variance and infinite Rubin df.
same <- pooled_ci_test(list(d1, d1), "x", "y", "z")
stopifnot(same$between == 0, is.infinite(same$df),
          all(same$conditioning_rank == 1L))
source <- rep(c("A", "B", "C"), length.out = n)
adjusted <- pooled_ci_test(input, "x", "y", "z", source)
stopifnot(all(adjusted$conditioning_rank == 3L),
          isTRUE(all.equal(adjusted$within, 1 / (n - 3 - 3))))
redundant_source <- cbind(source_z = z, source_z_again = 2 * z)
redundant <- pooled_ci_test(input, "x", "y", "z", redundant_source)
stopifnot(all(redundant$conditioning_rank == 1L),
          isTRUE(all.equal(redundant$p.value, result$p.value)))

# Observed entries, finite completion, variation across imputations and local RNG.
incomplete <- d1
incomplete[1:20, "x"] <- NA
incomplete[31:45, "y"] <- NA
rng_before <- .Random.seed
mi <- source_mi(incomplete, source, m = 3, max_iter = 4, seed = 919)
stopifnot(identical(rng_before, .Random.seed),
          identical(mi, source_mi(incomplete, source, m = 3, max_iter = 4, seed = 919)),
          all(vapply(mi, function(d) all(is.finite(d)), logical(1L))),
          all(vapply(mi, function(d) identical(d[!is.na(incomplete)],
                                                incomplete[!is.na(incomplete)]), logical(1L))),
          !identical(mi[[1]], mi[[2]]))

# The skeleton's MI path must use pooled tests with the source design.
mi_skeleton <- discover_skeleton(mi, max_cond = 0, source = source)
stopifnot(mi_skeleton$m == 3L, nrow(mi_skeleton$tests) == 3L)
for (i in seq_len(nrow(mi_skeleton$tests))) {
  test <- mi_skeleton$tests[i, ]
  direct <- pooled_ci_test(mi, test$x, test$y, source = source)
  stopifnot(isTRUE(all.equal(test$p.value, direct$p.value)))
}
graph <- matrix(1, 3L, 3L, dimnames = list(colnames(d1), colnames(d1)))
diag(graph) <- 0
propensity_warnings <- character()
augmented <- withCallingHandlers(
  source_mi(incomplete, source, m = 2, max_iter = 2,
             graph = graph, seed = 100),
  warning = function(w) {
    propensity_warnings <<- c(propensity_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
stopifnot(nrow(attr(augmented, "diagnostics")) == 8L,
          all(vapply(augmented, function(d) all(is.finite(d)), logical(1L))))
diagnostics <- attr(augmented, "diagnostics")
if (any(!diagnostics$converged | diagnostics$boundary | diagnostics$clipped > 0 |
        nzchar(diagnostics$warnings))) {
  stopifnot(length(propensity_warnings) == 1L)
}

# Input failures and local RNG restoration after an imputation error.
bad <- incomplete
bad[, "x"] <- NA
stopifnot(inherits(try(source_mi(bad, seed = 1), silent = TRUE), "try-error"),
          inherits(try(pooled_ci_test(list(d1), "x", "y"), silent = TRUE), "try-error"),
          inherits(try(pooled_ci_test(input, "x", "x"), silent = TRUE), "try-error"),
          inherits(try(source_mi(incomplete, source = rep(NA, n)), silent = TRUE), "try-error"))
degenerate <- cbind(a = 1:10, b = 1:10)
degenerate[1L, "a"] <- NA
before_failure <- .Random.seed
stopifnot(inherits(try(source_mi(degenerate, seed = 11), silent = TRUE), "try-error"),
          identical(before_failure, .Random.seed))

# A local seed also leaves an initially absent RNG state absent.
saved_rng <- .Random.seed
rm(".Random.seed", envir = .GlobalEnv)
invisible(source_mi(incomplete, source, m = 2, max_iter = 1, seed = 7))
stopifnot(!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
assign(".Random.seed", saved_rng, envir = .GlobalEnv)

# The linear predictive model is invariant to a change of measurement units.
tiny <- incomplete * 1e-10
tiny_mi <- source_mi(tiny, source, m = 3, max_iter = 4, seed = 919)
stopifnot(isTRUE(all.equal(unname(tiny_mi[[1]] / 1e-10), unname(mi[[1]]),
                          tolerance = 1e-10)))
