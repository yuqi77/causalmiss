# Source-aware linear multiple imputation and pooled Gaussian CI tests.
# These are original, small implementations of the specified paper components.

#' Pool Gaussian Conditional Independence Tests Across Imputations
#'
#' @param imputations A list of at least two complete numeric data sets.
#' @param x,y Column names or indices of the tested variables.
#' @param given Column names or indices in the conditioning set.
#' @param source Complete source labels or a numeric conditioning design matrix.
#' @return A list containing the pooled statistic, p-value and variance components.
#' @export
pooled_ci_test <- function(imputations, x, y, given = character(), source = NULL) {
  if (!is.list(imputations) || is.data.frame(imputations) || length(imputations) < 2L) {
    stop("imputations must be a list of at least two complete data sets.", call. = FALSE)
  }
  completed <- lapply(imputations, .cm_data, allow_na = FALSE)
  reference <- completed[[1L]]
  if (!all(vapply(completed, function(z) {
    identical(dim(z), dim(reference)) && identical(colnames(z), colnames(reference))
  }, logical(1L)))) {
    stop("All imputations must have identical dimensions, column names and ordering.",
         call. = FALSE)
  }
  ix <- .cm_vars(x, colnames(reference))
  iy <- .cm_vars(y, colnames(reference))
  ig <- .cm_vars(given, colnames(reference), empty = TRUE)
  if (length(ix) != 1L || length(iy) != 1L || ix == iy || any(c(ix, iy) %in% ig)) {
    stop("x and y must be distinct single columns outside given.", call. = FALSE)
  }
  parts <- lapply(completed, gaussian_ci_test, x = ix, y = iy,
                  given = ig, source = source)
  z <- vapply(parts, `[[`, numeric(1L), "estimate")
  variances <- vapply(parts, `[[`, numeric(1L), "variance")
  m <- length(z)
  estimate <- mean(z)
  within <- mean(variances)
  between <- stats::var(z)
  total <- within + (1 + 1 / m) * between
  statistic <- estimate / sqrt(total)
  df <- if (between == 0) Inf else
    (m - 1) * (1 + m * within / ((m + 1) * between))^2
  p_value <- if (is.infinite(df)) {
    2 * stats::pnorm(abs(statistic), lower.tail = FALSE)
  } else {
    2 * stats::pt(abs(statistic), df = df, lower.tail = FALSE)
  }
  list(p.value = p_value, statistic = statistic, df = df, estimate = estimate,
       within = within, between = between, total = total,
       n = nrow(reference), m = m,
       conditioning_rank = vapply(parts, `[[`, integer(1L), "conditioning_rank"),
       correlations = vapply(parts, `[[`, numeric(1L), "correlation"),
       transformed = z, variances = variances)
}

.cm_mi_propensity <- function(completed, missing, j, graph) {
  neighbors <- which(graph[j, ])
  response <- as.numeric(missing[, j])
  design <- cbind(intercept = 1, completed[, neighbors, drop = FALSE],
                  missing[, neighbors, drop = FALSE] * 1)
  # Standardization preserves the logistic model and prevents a change of units
  # from causing a nonconstant neighbor to be treated as numerically redundant.
  if (ncol(design) > 1L) {
    for (column in seq.int(2L, ncol(design))) {
      spread <- stats::sd(design[, column])
      if (is.finite(spread) && spread > 0) {
        design[, column] <- (design[, column] - mean(design[, column])) / spread
      }
    }
  }
  fit_warnings <- character()
  fit <- withCallingHandlers(stats::glm.fit(design, response,
                                           family = stats::binomial()),
    warning = function(w) {
      fit_warnings <<- c(fit_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  if (any(!is.finite(fit$fitted.values))) {
    stop("A missingness propensity fit produced nonfinite values.", call. = FALSE)
  }
  list(score = pmin(1 - 1e-6, pmax(1e-6, fit$fitted.values)),
       converged = isTRUE(fit$converged), boundary = isTRUE(fit$boundary),
       clipped = sum(fit$fitted.values < 1e-6 | fit$fitted.values > 1 - 1e-6),
       warnings = paste(unique(fit_warnings), collapse = "; "), rank = fit$rank)
}

.cm_mi_linear_draw <- function(y, predictors, observed) {
  # Scale the design before QR rank reduction, preserving the fitted linear model.
  response_center <- mean(y[observed])
  response_scale <- stats::sd(y[observed])
  if (!is.finite(response_scale) || response_scale <= 0) {
    stop("A linear imputation target has no observed variation.", call. = FALSE)
  }
  observed_response <- (y[observed] - response_center) / response_scale
  if (ncol(predictors)) {
    center <- colMeans(predictors[observed, , drop = FALSE])
    spread <- apply(predictors[observed, , drop = FALSE], 2L, stats::sd)
    keep <- is.finite(spread) & spread > 0
    predictors <- predictors[, keep, drop = FALSE]
    if (any(keep)) {
      predictors <- sweep(sweep(predictors, 2L, center[keep], "-"),
                          2L, spread[keep], "/")
    }
  }
  design <- cbind(intercept = 1, predictors)
  observed_design <- design[observed, , drop = FALSE]
  decomposition <- qr(observed_design, tol = 1e-7)
  retained <- decomposition$pivot[seq_len(decomposition$rank)]
  observed_design <- observed_design[, retained, drop = FALSE]
  design <- design[, retained, drop = FALSE]
  decomposition <- qr(observed_design)
  coefficients <- qr.coef(decomposition, observed_response)
  residuals <- qr.resid(decomposition, observed_response)
  degrees <- sum(observed) - decomposition$rank
  residual_sum <- sum(residuals^2)
  if (degrees < 1L || !is.finite(residual_sum) || residual_sum <= .Machine$double.eps) {
    stop("A linear imputation model has no residual degrees of freedom or variation; reduce predictors or provide more observed rows.",
         call. = FALSE)
  }
  sigma <- sqrt(residual_sum / stats::rchisq(1L, degrees))
  perturbation <- numeric(decomposition$rank)
  perturbation[decomposition$pivot] <- as.vector(
    backsolve(qr.R(decomposition), stats::rnorm(decomposition$rank))) * sigma
  coefficient_draw <- coefficients + perturbation
  means <- as.vector(design[!observed, , drop = FALSE] %*% coefficient_draw)
  draw <- stats::rnorm(length(means), mean = means, sd = sigma) *
    response_scale + response_center
  if (any(!is.finite(draw))) {
    stop("A linear imputation draw produced nonfinite values.", call. = FALSE)
  }
  draw
}

#' Source-Aware Linear Multiple Imputation
#'
#' @param data Numeric data with missing entries represented by NA.
#' @param source Complete source labels or a numeric predictor design matrix.
#' @param m Number of completed data sets, at least two.
#' @param max_iter Number of fully conditional specification sweeps.
#' @param graph Optional fixed adjacency matrix for missingness propensity models.
#' @param seed Optional local random seed, restored after completion.
#' @return A list of completed numeric matrices with imputation diagnostics.
#' @export
source_mi <- function(data, source = NULL, m = 5, max_iter = 5,
                      graph = NULL, seed = NULL) {
  original <- .cm_data(data, allow_na = TRUE)
  if (ncol(original) < 2L) {
    stop("source_mi requires at least two data variables.", call. = FALSE)
  }
  for (argument in c("m", "max_iter")) {
    value <- get(argument)
    lower <- if (argument == "m") 2L else 1L
    if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
        !is.finite(value) || value < lower || value > .Machine$integer.max ||
        value != as.integer(value)) {
      stop(argument, " must be an integer >= ", lower, ".", call. = FALSE)
    }
  }
  m <- as.integer(m)
  max_iter <- as.integer(max_iter)
  missing <- is.na(original)
  if (any(colSums(!missing) == 0L)) {
    stop("Every variable needs observed values; an entirely missing column cannot be imputed.",
         call. = FALSE)
  }
  targets <- which(colSums(missing) > 0L)
  if (any(colSums(!missing)[targets] < 3L)) {
    stop("Every incomplete variable needs at least three observed values.", call. = FALSE)
  }
  source_design <- .cm_source(source, nrow(original))
  if (!is.null(graph)) {
    if (!is.matrix(graph) || !(is.numeric(graph) || is.logical(graph)) ||
        !identical(dim(graph), c(ncol(original), ncol(original))) ||
        anyNA(graph) || any(!is.finite(graph))) {
      stop("graph must be a finite p by p numeric or logical adjacency matrix.",
           call. = FALSE)
    }
    if (!is.null(rownames(graph)) || !is.null(colnames(graph))) {
      if (is.null(rownames(graph)) || is.null(colnames(graph)) ||
          anyDuplicated(rownames(graph)) || anyDuplicated(colnames(graph)) ||
          !setequal(rownames(graph), colnames(original)) ||
          !setequal(colnames(graph), colnames(original))) {
        stop("Named graph rows and columns must match the data variables.", call. = FALSE)
      }
      graph <- graph[colnames(original), colnames(original), drop = FALSE]
    }
    graph <- (graph != 0) | t(graph != 0)
    diag(graph) <- FALSE
  }
  call <- match.call()
  result <- .cm_with_seed(seed, {
    completed_list <- vector("list", m)
    diagnostics <- list()
    diagnostic_index <- 0L
    for (imputation in seq_len(m)) {
      completed <- original
      for (j in targets) {
        observed <- !missing[, j]
        completed[!observed, j] <- sample(completed[observed, j], sum(!observed),
                                         replace = TRUE)
      }
      for (iteration in seq_len(max_iter)) {
        for (j in targets) {
          observed <- !missing[, j]
          predictors <- cbind(completed[, -j, drop = FALSE], source_design)
          if (!is.null(graph)) {
            propensity <- .cm_mi_propensity(completed, missing, j, graph)
            predictors <- cbind(predictors, propensity = propensity$score)
            diagnostic_index <- diagnostic_index + 1L
            diagnostics[[diagnostic_index]] <- data.frame(
              imputation = imputation, iteration = iteration,
              variable = colnames(original)[j],
              converged = propensity$converged, boundary = propensity$boundary,
              clipped = propensity$clipped, warnings = propensity$warnings,
              rank = propensity$rank, stringsAsFactors = FALSE)
          }
          completed[!observed, j] <- .cm_mi_linear_draw(completed[, j], predictors,
                                                       observed)
        }
      }
      completed_list[[imputation]] <- completed
    }
    attr(completed_list, "diagnostics") <- if (length(diagnostics)) {
      do.call(rbind, diagnostics)
    } else {
      data.frame(imputation = integer(), iteration = integer(),
                 variable = character(), converged = logical(),
                 boundary = logical(), clipped = integer(), warnings = character(),
                 rank = integer())
    }
    completed_list
  })
  attr(result, "method") <- if (is.null(graph)) "source-aware linear FCS" else
    "source-aware linear FCS with fixed-neighborhood propensity augmentation"
  attr(result, "iterations") <- max_iter
  attr(result, "graph") <- graph
  attr(result, "call") <- call
  diagnostics <- attr(result, "diagnostics")
  if (nrow(diagnostics) && any(!diagnostics$converged | diagnostics$boundary |
                               diagnostics$clipped > 0 | nzchar(diagnostics$warnings))) {
    warning("Some propensity regressions did not converge, reached a boundary, or required clipping; inspect attr(result, 'diagnostics') before analysis.",
            call. = FALSE)
  }
  result
}
