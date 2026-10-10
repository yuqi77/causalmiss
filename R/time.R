lag_windows <- function(data, lags = 1L, step = 1L) {
  data <- .cm_data(data)
  if (!is.numeric(lags) || !length(lags) || anyNA(lags) ||
      any(!is.finite(lags)) || any(lags < 1 | lags != floor(lags)) ||
      anyDuplicated(lags))
    stop("lags must be distinct positive integers.", call. = FALSE)
  if (!is.numeric(step) || length(step) != 1L || !is.finite(step) ||
      step < 1 || step != floor(step))
    stop("step must be a positive integer.", call. = FALSE)
  offsets <- sort(lags) * step
  if (max(offsets) >= nrow(data))
    stop("The largest lag times step must be smaller than the number of rows.", call. = FALSE)
  lags <- c(0L, as.integer(sort(lags)))
  offsets <- c(0L, as.integer(offsets))
  rows <- seq.int(max(offsets) + 1L, nrow(data))
  blocks <- lapply(offsets, function(offset) data[rows - offset, , drop = FALSE])
  result <- do.call(cbind, blocks)
  node_names <- colnames(data)
  colnames(result) <- paste0(rep(node_names, length(lags)), "_lag",
                            rep(lags, each = ncol(data)))
  attr(result, "row_index") <- rows
  attr(result, "column_map") <- data.frame(
    column = colnames(result), variable = rep(node_names, length(lags)),
    lag = rep(lags, each = ncol(data)),
    offset = rep(offsets, each = ncol(data)), stringsAsFactors = FALSE)
  attr(result, "step") <- as.integer(step)
  result
}

graph_regression_impute <- function(data, graph, max_iter = 10L,
                                    tol = 1e-6, initial = NULL) {
  data <- .cm_data(data)
  graph <- .cm_graph(graph, colnames(data))
  if (!is.numeric(max_iter) || length(max_iter) != 1L || !is.finite(max_iter) ||
      max_iter < 1 || max_iter != floor(max_iter) || max_iter > .Machine$integer.max)
    stop("max_iter must be a positive integer.", call. = FALSE)
  if (!is.numeric(tol) || length(tol) != 1L || !is.finite(tol) || tol < 0)
    stop("tol must be a nonnegative finite number.", call. = FALSE)
  missing <- is.na(data)
  if (is.null(initial)) {
    complete <- mean_impute(data)
  } else {
    if (is.matrix(initial) && is.null(colnames(initial)))
      colnames(initial) <- colnames(data)
    complete <- .cm_data(initial, allow_na = FALSE)
    if (!identical(dim(complete), dim(data)) ||
        !setequal(colnames(complete), colnames(data)))
      stop("initial must have the same dimensions and columns as data.", call. = FALSE)
    complete <- complete[, colnames(data), drop = FALSE]
    dimnames(complete) <- dimnames(data)
    complete[!missing] <- data[!missing]
  }
  trace <- data.frame(iteration = integer(), max_change = numeric(),
                      fallback_count = integer())
  coefficients <- vector("list", ncol(data))
  names(coefficients) <- colnames(data)
  fallback_nodes <- character()
  if (!any(missing))
    return(list(data = complete, graph = graph, trace = trace,
                converged = TRUE, coefficients = coefficients,
                fallback_nodes = fallback_nodes))
  converged <- FALSE
  for (iteration in seq_len(as.integer(max_iter))) {
    next_complete <- complete
    fallback_count <- 0L
    for (j in which(colSums(missing) > 0L)) {
      observed <- !missing[, j]
      parents <- .cm_predictors(graph, j)
      design <- cbind("(Intercept)" = 1, complete[, parents, drop = FALSE])
      fit <- stats::lm.fit(design[observed, , drop = FALSE], data[observed, j])
      if (fit$rank < ncol(design)) {
        prediction <- rep(mean(data[observed, j]), sum(missing[, j]))
        fallback_count <- fallback_count + 1L
        fallback_nodes <- union(fallback_nodes, colnames(data)[j])
        coefficients[j] <- list(NULL)
      } else {
        coefficients[[j]] <- fit$coefficients
        prediction <- as.vector(design[missing[, j], , drop = FALSE] %*%
                                  fit$coefficients)
      }
      if (any(!is.finite(prediction)))
        stop("A regression update produced nonfinite predictions.", call. = FALSE)
      next_complete[missing[, j], j] <- prediction
    }
    change <- max(abs(next_complete[missing] - complete[missing]))
    if (!is.finite(change))
      stop("The imputation change is nonfinite; inspect data scale and graph.", call. = FALSE)
    trace <- rbind(trace, data.frame(iteration = iteration, max_change = change,
                                    fallback_count = fallback_count))
    complete <- next_complete
    if (change <= tol) {
      converged <- TRUE
      break
    }
  }
  if (length(fallback_nodes))
    warning("Rank-deficient observed designs used mean imputation for: ",
            paste(fallback_nodes, collapse = ", "), ".", call. = FALSE)
  list(data = complete, graph = graph, trace = trace, converged = converged,
       coefficients = coefficients, fallback_nodes = fallback_nodes)
}
