library(causalmiss)

calibrate <- function(y, mu, w, observed, tol = 1e-6) {
  dr_calibrate(y, observed, mu, w, tol)
}

# Independent hand-computable root: r = 0.5, theta = 0.5, xi = 0.
# Observed propensities 1/3 and 1 have harmonic mean 0.5. The second value
# is moved below 1 with a matching first value to satisfy strict positivity.
w2 <- 0.9
w1 <- 1 / (4 - 1 / w2)
w <- c(w1, w2, 0.4, 0.6)
observed <- c(TRUE, TRUE, FALSE, FALSE)
# Choose eta centered so the observed calibration moment is zero at the root.
z1 <- 1
z2 <- -w2 / w1
eta <- c(z1, z2, -0.5 * (z1 + z2), -0.5 * (z1 + z2))
mu <- eta / (1 - w)
y <- c(mu[1] + 2, mu[2] - 1, NA, NA)
cal <- calibrate(y, mu, w, observed, tol = 1e-9)
stopifnot(cal$ok, abs(cal$theta - 0.5) < 1e-8,
          abs(cal$xi) < 1e-8, cal$min_denominator > 0,
          abs(sum(cal$p) - 1) < 1e-8)
expected_q <- (1 - w[observed]) / (4 * w[observed] * 0.5)
expected_correction <- sum(expected_q * c(2, -1))
stopifnot(abs(cal$correction - expected_correction) < 1e-8,
          abs(cal$correction) > 0.1)
for (scale_factor in c(1e-10, 1e6)) {
  scaled <- calibrate(y * scale_factor, mu * scale_factor, w, observed, 1e-9)
  stopifnot(scaled$ok, max(abs(scaled$p - cal$p)) < 1e-8,
            abs(scaled$correction / scale_factor - cal$correction) < 1e-8)
}

# A zero residual implies zero correction without claiming zero prediction error.
zero <- calibrate(c(mu[observed], NA, NA), mu, w, observed, 1e-9)
stopifnot(zero$ok, abs(zero$correction) < 1e-12)

# The full-sample eta target is outside observed support: explicit failure.
bad <- suppressWarnings(calibrate(c(1, 2, NA, NA), c(0, 0, 10, 10), rep(0.5, 4), observed))
stopifnot(!bad$ok, grepl("convex hull", bad$reason, fixed = TRUE))

# Extreme probabilities fail explicitly instead of dereferencing an invalid
# numerical starting point.
extreme <- suppressWarnings(calibrate(c(1, 2, NA, NA), rep(2, 4),
                                     rep(1e-300, 4), observed))
stopifnot(!extreme$ok, extreme$status == "regression_fallback", !anyNA(extreme$data))

# Infeasible end-to-end calibration returns a visibly marked regression fallback.
outside <- data.frame(x = c(1, 2, 3, -10, -11, -12),
                      y = c(1, 2, 3, NA, NA, NA))
fallback <- suppressWarnings(dr_impute(outside))
stopifnot(fallback$diagnostics$status == "regression_fallback",
          fallback$diagnostics$correction == 0,
          all(fallback$data$y[1:3] == outside$y[1:3]),
          !anyNA(fallback$data))

# End-to-end MAR completion and exact preservation of observed values.
set.seed(312)
x <- rnorm(300)
y <- 2 + 1.5 * x + rnorm(300)
y[runif(300) > plogis(0.5 + 0.2 * x)] <- NA
d <- data.frame(x = x, y = y, check.names = FALSE)
fit <- dr_impute(d)
stopifnot(!anyNA(fit$data), identical(fit$data$x, d$x),
          identical(fit$data$y[!is.na(y)], d$y[!is.na(y)]),
          fit$diagnostics$status == "empirical_likelihood",
          fit$diagnostics$calibration_residual <= 1e-6)

# Arbitrary names and explicit empty predictor overrides avoid formula parsing.
names(d) <- c("predictor with space", "target-value")
named <- dr_impute(d,
  outcome_predictors = list("target-value" = "predictor with space"),
  propensity_predictors = list("target-value" = character()))
stopifnot(identical(names(named$data), names(d)), !anyNA(named$data))

# Cyclic optimization is outside this function: it only uses graph neighborhoods.
g <- matrix(c(0, 1, 0, 0), 2, 2, byrow = TRUE,
            dimnames = list(names(d), names(d)))
guided <- dr_impute(d, graph = g)
stopifnot(guided$diagnostics$outcome_predictors == "predictor with space")

# A propensity covariate with missing values is rejected in the MAR prototype.
d2 <- data.frame(x = c(1, NA, 3, 4, 5, 6), y = c(1, 2, NA, 4, 5, 6))
err <- try(dr_impute(d2, propensity_predictors = list(y = "x")), silent = TRUE)
stopifnot(inherits(err, "try-error"))

# Fully observed data needs no calibration and returns an empty diagnostic table.
complete <- data.frame(a = 1:5, b = c(2, 1, 3, 4, 7))
none <- dr_impute(complete)
stopifnot(nrow(none$diagnostics) == 0L, !anyNA(none$data))

# An explicit initial matrix may supply missing predictors, but cannot alter
# any observed data values.
initial <- as.matrix(d)
initial[is.na(initial)] <- 0
initial[!is.na(as.matrix(d))] <- 99
started <- dr_impute(d, initial = initial)
stopifnot(identical(started$data[[1L]], d[[1L]]),
          identical(started$data[[2L]][!is.na(d[[2L]])], d[[2L]][!is.na(d[[2L]])]))
