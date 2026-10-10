iterative_discovery <- function(data, max_iter = 5L, tol = 1e-5, alpha = 0.05,
                               max_cond = 2L, imputation = c("regression", "dr"), clip = 0.01) {
  raw <- .cm_data(data)
  imputation <- match.arg(imputation)
  if (length(max_iter) != 1L || !is.numeric(max_iter) || !is.finite(max_iter) ||
      max_iter < 1 || max_iter != floor(max_iter))
    stop("max_iter must be a positive integer.", call. = FALSE)
  if (length(tol) != 1L || !is.numeric(tol) || !is.finite(tol) || tol <= 0)
    stop("tol must be positive.", call. = FALSE)
  current <- mean_impute(raw)
  previous_graph <- discover_skeleton(current, alpha, max_cond)
  trace <- vector("list", max_iter)
  fits <- vector("list", max_iter)
  converged <- FALSE
  for (iteration in seq_len(max_iter)) {
    fitted <- if (imputation == "regression")
      graph_regression_impute(raw, previous_graph$adjacency, max_iter = 1L, tol = tol, initial = current) else
      dr_impute(raw, previous_graph$adjacency, clip = clip, initial = current)
    updated <- as.matrix(fitted$data)
    graph <- discover_skeleton(updated, alpha, max_cond)
    change <- max(abs(updated - current))
    edge_changes <- sum(graph$adjacency != previous_graph$adjacency) / 2
    fallback <- if (imputation == "dr") sum(fitted$diagnostics$status == "regression_fallback") else
      length(fitted$fallback_nodes)
    trace[[iteration]] <- data.frame(iteration = iteration, max_change = change,
      edge_changes = edge_changes, edges = sum(graph$adjacency) / 2, fallbacks = fallback)
    fits[[iteration]] <- fitted
    current <- updated
    previous_graph <- graph
    if (change <= tol && edge_changes == 0) { converged <- TRUE; break }
  }
  structure(list(data = current, graph = previous_graph,
    trace = do.call(rbind, trace[seq_len(iteration)]), converged = converged,
    imputation = imputation, fits = fits[seq_len(iteration)]), class = "cm_iterative")
}

print.cm_iterative <- function(x, ...) {
  cat("Iterative Gaussian skeleton discovery (", x$imputation, ")\n", sep = "")
  cat(nrow(x$trace), "iterations; convergence criterion met:", x$converged, "\n")
  print(x$graph)
  invisible(x)
}
