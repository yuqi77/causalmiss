.cm_data <- function(data, allow_na = TRUE) {
  if (is.data.frame(data)) {
    if (!all(vapply(data, is.numeric, logical(1))))
      stop("All data columns must be numeric.", call. = FALSE)
    data <- as.matrix(data)
  }
  if (!is.matrix(data) || !is.numeric(data) || nrow(data) < 5L || ncol(data) < 1L)
    stop("data must be a numeric matrix or data frame with at least 5 rows.", call. = FALSE)
  if (any(is.infinite(data))) stop("Infinite values are not supported.", call. = FALSE)
  if (!allow_na && anyNA(data)) stop("Complete data are required.", call. = FALSE)
  if (any(colSums(!is.na(data)) == 0L))
    stop("Every column must have at least one observed value.", call. = FALSE)
  if (is.null(colnames(data))) colnames(data) <- paste0("V", seq_len(ncol(data)))
  if (anyNA(colnames(data)) || any(!nzchar(colnames(data))) || anyDuplicated(colnames(data)))
    stop("Column names must be nonempty and unique.", call. = FALSE)
  storage.mode(data) <- "double"
  data
}

.cm_graph <- function(graph, nodes) {
  p <- length(nodes)
  if (is.null(graph)) {
    graph <- matrix(1, p, p, dimnames = list(nodes, nodes))
    diag(graph) <- 0
    return(graph)
  }
  if (!is.matrix(graph) || !all(dim(graph) == c(p, p)) || anyNA(graph) ||
      !all(graph %in% c(0, 1)) || any(diag(graph) != 0))
    stop("graph must be a square 0/1 adjacency matrix with a zero diagonal.", call. = FALSE)
  if (!is.null(rownames(graph)) || !is.null(colnames(graph))) {
    if (!setequal(rownames(graph), nodes) || !setequal(colnames(graph), nodes))
      stop("Both graph dimension names must match data columns.", call. = FALSE)
    graph <- graph[nodes, nodes, drop = FALSE]
  }
  dimnames(graph) <- list(nodes, nodes)
  storage.mode(graph) <- "double"
  graph
}

.cm_predictors <- function(graph, node) {
  j <- if (is.character(node)) match(node, colnames(graph)) else node
  which(graph[, j] == 1)
}

.cm_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(force(expr))
  if (length(seed) != 1L || !is.numeric(seed) || !is.finite(seed) ||
      seed < 0 || seed > .Machine$integer.max || seed != floor(seed))
    stop("seed must be NULL or a nonnegative integer.", call. = FALSE)
  exists_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (exists_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (exists_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(as.integer(seed))
  force(expr)
}

.cm_source <- function(source, n) {
  if (is.null(source)) return(matrix(numeric(), n, 0L))
  if (is.data.frame(source)) source <- as.matrix(source)
  if (is.matrix(source)) {
    if (!is.numeric(source) || nrow(source) != n || anyNA(source) || any(!is.finite(source)))
      stop("source matrix must have n complete numeric rows.", call. = FALSE)
    return(source)
  }
  if (length(source) != n || anyNA(source))
    stop("source must have one nonmissing label per row.", call. = FALSE)
  source <- droplevels(factor(source))
  if (nlevels(source) == 1L) return(matrix(numeric(), n, 0L))
  stats::model.matrix(~ source)[, -1L, drop = FALSE]
}

.cm_vars <- function(vars, nodes, empty = FALSE) {
  if (empty && length(vars) == 0L) return(integer())
  if (is.character(vars)) vars <- match(vars, nodes)
  if (!is.numeric(vars) || anyNA(vars) || any(!is.finite(vars)) ||
      any(vars != floor(vars)) || any(vars < 1L | vars > length(nodes)) || anyDuplicated(vars))
    stop("Variables must be unique column names or valid column indices.", call. = FALSE)
  as.integer(vars)
}

mean_impute <- function(data) {
  data <- .cm_data(data)
  for (j in seq_len(ncol(data))) data[is.na(data[, j]), j] <- mean(data[, j], na.rm = TRUE)
  data
}
