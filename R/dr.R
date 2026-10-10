# Empirical-likelihood calibration for the continuous MAR prototype.
# The centered eta vector and the scalar residual correction are essential.

.cm_dr_graph <- function(graph, nodes) {
  if (is.null(graph)) return(NULL)
  if (!is.matrix(graph) || !is.numeric(graph) ||
      !identical(dim(graph), c(length(nodes), length(nodes))) ||
      anyNA(graph) || any(!graph %in% c(0, 1)) || any(diag(graph) != 0)) {
    stop("graph must be a square numeric 0/1 adjacency matrix with zero diagonal.",
         call. = FALSE)
  }
  if (!is.null(rownames(graph)) || !is.null(colnames(graph))) {
    if (is.null(rownames(graph)) || is.null(colnames(graph)) ||
        !setequal(rownames(graph), nodes) || !setequal(colnames(graph), nodes) ||
        anyDuplicated(rownames(graph)) || anyDuplicated(colnames(graph))) {
      stop("Both graph dimnames must match the data column names.", call. = FALSE)
    }
    graph <- graph[nodes, nodes, drop = FALSE]
  }
  graph
}

.cm_dr_predictors <- function(spec, defaults, nodes, label) {
  if (is.null(spec)) return(defaults)
  if (!is.list(spec) || is.null(names(spec)) || anyDuplicated(names(spec)) ||
      any(!names(spec) %in% nodes)) {
    stop(label, " must be a named list indexed by data column names.",
         call. = FALSE)
  }
  for (target in names(spec)) {
    value <- spec[[target]]
    if (!is.character(value) || anyNA(value) || anyDuplicated(value) ||
        any(!value %in% nodes) || target %in% value) {
      stop(label, " entries must contain unique other column names.",
           call. = FALSE)
    }
    defaults[[target]] <- value
  }
  defaults
}

.cm_dr_calibrate <- function(y, mu, w, observed, tol = 1e-6) {
  n <- length(y)
  nr <- sum(observed)
  fail <- function(reason, residual = NA_real_) {
    list(ok = FALSE, reason = reason, correction = 0,
         residual = residual, theta = NA_real_, xi = NA_real_,
         min_denominator = NA_real_, weight_sum = NA_real_)
  }
  if (nr < 2L || nr == n) return(fail("Calibration requires observed and missing rows."))
  if (length(mu) != n || length(w) != n || any(!is.finite(mu)) ||
      any(!is.finite(w)) || any(w <= 0 | w >= 1)) {
    return(fail("Nuisance predictions must be finite with 0 < propensity < 1."))
  }
  eta <- (1 - w) * mu
  eta_centered <- eta - mean(eta)
  if (any(!is.finite(eta_centered))) {
    return(fail("Centered calibration predictions overflowed."))
  }
  amplitude <- max(abs(eta_centered))
  eta_scale <- if (amplitude == 0) 0 else
    amplitude * sqrt(mean((eta_centered / amplitude)^2))
  zero_eta <- eta_scale <= sqrt(.Machine$double.eps) * max(abs(eta))
  z <- if (zero_eta) rep(0, n) else eta_centered / eta_scale
  zo <- z[observed]
  wo <- w[observed]
  if (!zero_eta && (min(zo) >= 0 || max(zo) <= 0)) {
    return(fail("Centered calibration target is outside the observed convex hull."))
  }
  r <- nr / n
  evaluate <- function(par, jacobian = FALSE) {
    theta <- par[1L]
    xi <- par[2L]
    if (!is.finite(theta) || theta <= 1e-10 || theta >= 1 - 1e-10 ||
        !is.finite(xi)) return(NULL)
    gamma <- (1 - r) / (r * (1 - theta))
    d <- 1 + gamma * (wo - theta) + xi * zo
    if (any(!is.finite(d)) || any(d <= 1e-10)) return(NULL)
    e <- c(mean(zo / d), mean((wo - theta) / d))
    p <- 1 / (nr * d)
    discrepancy <- max(abs(sum(p) - 1), abs(sum(p * zo)),
                       abs(sum(p * (wo - theta))))
    ans <- list(e = e, p = p, d = d, discrepancy = discrepancy)
    if (jacobian) {
      dtheta <- gamma * (wo - 1) / (1 - theta)
      ans$jacobian <- matrix(c(
        -mean(zo * dtheta / d^2),
        mean(-1 / d - (wo - theta) * dtheta / d^2),
        -mean(zo^2 / d^2),
        -mean((wo - theta) * zo / d^2)), 2L, 2L)
    }
    ans
  }
  # theta = observed fraction, xi = 0 gives d_i = w_i / r > 0.
  par <- c(r, 0)
  current <- evaluate(par, TRUE)
  if (is.null(current)) {
    return(fail("No numerically stable positive initial calibration denominators."))
  }
  for (iteration in seq_len(100L)) {
    if (current$discrepancy <= tol) break
    if (zero_eta) {
      denom <- current$jacobian[2L, 1L]
      if (!is.finite(denom) || abs(denom) < 1e-14) break
      step <- c(current$e[2L] / denom, 0)
    } else {
      step <- tryCatch(as.vector(solve(current$jacobian, current$e)),
                       error = function(e) NULL)
      if (is.null(step) || any(!is.finite(step))) break
    }
    accepted <- FALSE
    for (backtrack in 0:30) {
      candidate <- par - step * 2^(-backtrack)
      trial <- evaluate(candidate, TRUE)
      if (!is.null(trial) &&
          sum(trial$e^2) < sum(current$e^2)) {
        par <- candidate
        current <- trial
        accepted <- TRUE
        break
      }
    }
    if (!accepted) break
  }
  # A bounded second solver attempt; acceptance still requires all moments and
  # positive empirical-likelihood denominators, not optimizer status alone.
  if (current$discrepancy > tol) {
    objective <- function(candidate) {
      ev <- evaluate(candidate)
      if (is.null(ev)) return(1e10 + sum(pmin(abs(candidate), 1e8)))
      sum(ev$e^2) + (sum(ev$p) - 1)^2
    }
    opt <- tryCatch(stats::optim(par, objective, method = "Nelder-Mead",
                                 control = list(maxit = 2000L, reltol = 1e-12)),
                    error = function(e) NULL)
    if (!is.null(opt)) {
      trial <- evaluate(opt$par, TRUE)
      if (!is.null(trial) && trial$discrepancy < current$discrepancy) {
        par <- opt$par
        current <- trial
      }
    }
  }
  if (current$discrepancy > tol) {
    return(fail("Positive empirical-likelihood calibration did not meet tolerance.",
                current$discrepancy))
  }
  q <- (1 - wo) * current$p / (1 - par[1L])
  correction <- sum(q * (y[observed] - mu[observed]))
  if (!is.finite(correction) || any(!is.finite(mu[!observed] + correction))) {
    return(fail("Residual correction or missing predictions are not finite."))
  }
  list(ok = TRUE, reason = "", correction = correction,
       residual = current$discrepancy, theta = par[1L],
       xi = if (zero_eta) 0 else par[2L] / eta_scale,
       min_denominator = min(current$d), weight_sum = sum(current$p),
       p = current$p, q = q, eta_centered = eta_centered)
}

#' Calibrate supplied outcome means and observation probabilities
#' @export
dr_calibrate <- function(y, observed, mu, propensity, tol = 1e-6) {
  n <- length(y)
  if (!is.numeric(y) || n < 3L || length(observed) != n ||
      !is.logical(observed) || anyNA(observed) ||
      !is.numeric(mu) || length(mu) != n || any(!is.finite(mu)) ||
      !is.numeric(propensity) || length(propensity) != n ||
      any(!is.finite(propensity)) || any(propensity <= 0 | propensity >= 1) ||
      any(!is.finite(y[observed])) || length(tol) != 1L || !is.numeric(tol) ||
      !is.finite(tol) || tol <= 0) {
    stop("Supply numeric y, logical observed, finite mu, probabilities in (0, 1), and positive tol; vector lengths must agree.",
         call. = FALSE)
  }
  calibrated <- .cm_dr_calibrate(y, mu, propensity, observed, tol)
  calibrated$status <- if (calibrated$ok) "empirical_likelihood" else "regression_fallback"
  calibrated$observed_rows <- which(observed)
  calibrated$imputed <- mu + calibrated$correction
  calibrated$data <- y
  calibrated$data[!observed] <- calibrated$imputed[!observed]
  if (!calibrated$ok) {
    warning("Regression fallback: ", calibrated$reason, call. = FALSE)
  }
  calibrated
}

#' Graph-guided calibrated imputation for continuous data
#'
#' @param data Numeric data frame or matrix; missing values are NA.
#' @param graph Optional 0/1 adjacency matrix, row to column. Symmetric edges
#'   represent undirected links.
#' @param outcome_predictors,propensity_predictors Named lists of predictor
#'   column names, optionally overriding the defaults for particular targets.
#' @param clip Propensity clipping bound in (0, 0.5).
#' @param calibration_tol Maximum accepted empirical-likelihood moment error.
#' @param initial Optional complete starting values, with the data dimensions
#'   and column order. Observed entries are restored from data.
#' @return A list containing completed data, diagnostics, and fitted models.
#' @export
dr_impute <- function(data, graph = NULL, outcome_predictors = NULL,
                      propensity_predictors = NULL, clip = 0.01,
                      calibration_tol = 1e-6, initial = NULL) {
  raw <- .cm_data(data, allow_na = TRUE)
  nodes <- colnames(raw)
  if (length(clip) != 1L || !is.numeric(clip) || !is.finite(clip) || clip <= 0 || clip >= 0.5) {
    stop("clip must be a finite number strictly between 0 and 0.5.", call. = FALSE)
  }
  if (length(calibration_tol) != 1L || !is.numeric(calibration_tol) || !is.finite(calibration_tol) ||
      calibration_tol <= 0) {
    stop("calibration_tol must be a positive finite number.", call. = FALSE)
  }
  graph <- .cm_dr_graph(graph, nodes)
  complete <- nodes[colSums(is.na(raw)) == 0L]
  outcome <- propensity <- stats::setNames(vector("list", length(nodes)), nodes)
  for (j in seq_along(nodes)) {
    if (is.null(graph)) {
      outcome[[j]] <- setdiff(nodes, nodes[j])
      neighbors <- outcome[[j]]
    } else {
      outcome[[j]] <- nodes[graph[, j] == 1]
      neighbors <- nodes[graph[, j] == 1 | graph[j, ] == 1]
    }
    propensity[[j]] <- intersect(neighbors, complete)
  }
  outcome <- .cm_dr_predictors(outcome_predictors, outcome, nodes,
                               "outcome_predictors")
  propensity <- .cm_dr_predictors(propensity_predictors, propensity, nodes,
                                  "propensity_predictors")
  targets <- nodes[colSums(is.na(raw)) > 0L]
  if (any(colSums(!is.na(raw)) == 0L)) {
    stop("Each column must contain at least one observed value.", call. = FALSE)
  }
  for (target in targets) {
    if (any(!propensity[[target]] %in% complete)) {
      stop("Propensity predictors must be fully observed in this MAR prototype (target ",
           target, ").", call. = FALSE)
    }
  }
  if (is.null(initial)) {
    filled <- raw
    for (j in seq_along(nodes)) {
      filled[is.na(filled[, j]), j] <- mean(raw[, j], na.rm = TRUE)
    }
  } else {
    filled <- .cm_data(initial, allow_na = FALSE)
    if (!identical(dim(filled), dim(raw)) ||
        !identical(colnames(filled), nodes)) {
      stop("initial must have the data dimensions and column order.", call. = FALSE)
    }
    filled[!is.na(raw)] <- raw[!is.na(raw)]
  }
  targets <- targets[order(colMeans(is.na(raw))[targets])]
  diagnostics <- vector("list", length(targets))
  models <- stats::setNames(vector("list", length(targets)), targets)
  fallbacks <- character()
  design <- function(predictors) {
    cbind(`(Intercept)` = rep(1, nrow(raw)),
          filled[, predictors, drop = FALSE])
  }
  for (k in seq_along(targets)) {
    target <- targets[k]
    observed <- !is.na(raw[, target])
    xo <- design(outcome[[target]])
    if (sum(observed) <= ncol(xo) || qr(xo[observed, , drop = FALSE])$rank < ncol(xo)) {
      stop("Outcome model for ", target,
           " requires more observed rows than coefficients and a full-rank design.",
           call. = FALSE)
    }
    fit_out <- stats::lm.fit(xo[observed, , drop = FALSE], raw[observed, target])
    mu <- drop(xo %*% fit_out$coefficients)
    if (any(!is.finite(mu))) {
      stop("Outcome predictions for ", target, " are not finite.", call. = FALSE)
    }
    xp <- design(propensity[[target]])
    if (qr(xp)$rank < ncol(xp)) {
      stop("Propensity model for ", target, " has a rank-deficient design.",
           call. = FALSE)
    }
    fit_warnings <- character()
    fit_pr <- withCallingHandlers(
      stats::glm.fit(xp, as.numeric(observed), family = stats::binomial(),
                     control = stats::glm.control(maxit = 100L)),
      warning = function(warning) {
        fit_warnings <<- c(fit_warnings, conditionMessage(warning))
        invokeRestart("muffleWarning")
      })
    w_raw <- fit_pr$fitted.values
    w <- pmax(clip, pmin(1 - clip, w_raw))
    if (!isTRUE(fit_pr$converged) || any(!is.finite(fit_pr$coefficients)) ||
        any(!is.finite(w))) {
      calibrated <- list(ok = FALSE, reason = "Logistic propensity fit failed.",
                         correction = 0, residual = NA_real_, theta = NA_real_,
                         xi = NA_real_, min_denominator = NA_real_,
                         weight_sum = NA_real_)
    } else {
      calibrated <- .cm_dr_calibrate(raw[, target], mu, w, observed,
                                     calibration_tol)
    }
    status <- if (calibrated$ok) "empirical_likelihood" else "regression_fallback"
    if (!calibrated$ok) fallbacks <- c(fallbacks, target)
    filled[!observed, target] <- mu[!observed] + calibrated$correction
    diagnostics[[k]] <- data.frame(
      target = target, observed = sum(observed), missing = sum(!observed),
      status = status, correction = calibrated$correction,
      theta = calibrated$theta, xi = calibrated$xi,
      calibration_residual = calibrated$residual,
      min_denominator = calibrated$min_denominator,
      weight_sum = calibrated$weight_sum,
      clipped_fraction = mean(w_raw < clip | w_raw > 1 - clip),
      outcome_predictors = paste(outcome[[target]], collapse = ", "),
      propensity_predictors = paste(propensity[[target]], collapse = ", "),
      reason = calibrated$reason,
      model_warnings = paste(unique(fit_warnings), collapse = "; "),
      stringsAsFactors = FALSE)
    models[[target]] <- list(outcome = fit_out, propensity = fit_pr,
                             calibration = calibrated,
                             outcome_prediction = mu, observation_probability = w)
  }
  if (length(fallbacks)) {
    warning("Regression fallback for: ", paste(fallbacks, collapse = ", "),
            ". See diagnostics$reason; these targets were not calibrated.",
            call. = FALSE)
  }
  empty <- data.frame(target = character(), observed = integer(), missing = integer(),
                      status = character(), correction = numeric(), theta = numeric(),
                      xi = numeric(), calibration_residual = numeric(),
                      min_denominator = numeric(), weight_sum = numeric(),
                      clipped_fraction = numeric(), outcome_predictors = character(),
                      propensity_predictors = character(), reason = character(),
                      model_warnings = character(), stringsAsFactors = FALSE)
  ans <- list(data = as.data.frame(filled, optional = TRUE),
              diagnostics = if (length(diagnostics)) do.call(rbind, diagnostics) else empty,
              models = models)
  class(ans) <- "cm_dr_imputation"
  ans
}
