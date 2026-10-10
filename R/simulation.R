simulate_causal_data <- function(n = 400L, missing = 0.2, mechanism = c("mcar", "mar"), seed = 1L) {
  mechanism <- match.arg(mechanism)
  if (length(n) != 1L || !is.numeric(n) || !is.finite(n) || n < 20 || n != floor(n))
    stop("n must be an integer of at least 20.", call. = FALSE)
  if (length(missing) != 1L || !is.numeric(missing) || !is.finite(missing) || missing < 0 || missing >= 0.8)
    stop("missing must lie in [0, 0.8).", call. = FALSE)
  .cm_with_seed(seed, {
    x1 <- stats::rnorm(n); x2 <- stats::rnorm(n)
    x3 <- 0.9 * x1 + 0.8 * x2 + stats::rnorm(n)
    x4 <- 0.8 * x3 + stats::rnorm(n)
    complete <- cbind(X1 = x1, X2 = x2, X3 = x3, X4 = x4)
    incomplete <- complete
    for (j in 3:4) {
      prob <- rep(missing, n)
      if (mechanism == "mar" && missing > 0) {
        intercept <- stats::uniroot(function(b) mean(stats::plogis(b + 0.6 * x1)) - missing,
                                    c(-40, 40))$root
        prob <- stats::plogis(intercept + 0.6 * x1)
      }
      incomplete[stats::runif(n) < prob, j] <- NA_real_
    }
    truth <- matrix(0, 4, 4, dimnames = list(colnames(complete), colnames(complete)))
    truth[1, 3] <- truth[2, 3] <- truth[3, 4] <- 1
    list(complete = complete, incomplete = incomplete, dag = truth,
         skeleton = 1 * ((truth + t(truth)) > 0), mechanism = mechanism)
  })
}
