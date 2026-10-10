gaussian_ci_test <- function(data, x, y, given = character(), source = NULL) {
  data <- .cm_data(data, allow_na = FALSE)
  nodes <- colnames(data)
  x <- .cm_vars(x, nodes); y <- .cm_vars(y, nodes)
  given <- .cm_vars(given, nodes, empty = TRUE)
  if (length(x) != 1L || length(y) != 1L || x == y || any(c(x, y) %in% given))
    stop("x and y must be distinct single variables outside given.", call. = FALSE)
  conditioning <- cbind(data[, given, drop = FALSE], .cm_source(source, nrow(data)))
  if (ncol(conditioning)) {
    conditioning <- sweep(conditioning, 2L, colMeans(conditioning), "-")
    magnitude <- apply(abs(conditioning), 2L, max)
    magnitude[magnitude == 0] <- 1
    conditioning <- sweep(conditioning, 2L, magnitude, "/")
    spread <- sqrt(colSums(conditioning^2))
    spread[spread == 0] <- 1
    conditioning <- sweep(conditioning, 2L, spread, "/")
  }
  z <- cbind(1, conditioning)
  qr_z <- qr(z)
  k <- qr_z$rank - 1L
  variance <- 1 / (nrow(data) - k - 3)
  if (!is.finite(variance) || variance <= 0)
    stop("Insufficient rows for the conditioning rank.", call. = FALSE)
  centered_x <- data[, x] - mean(data[, x]); centered_y <- data[, y] - mean(data[, y])
  scale_x <- max(abs(centered_x)); scale_y <- max(abs(centered_y))
  if (!is.finite(scale_x) || !is.finite(scale_y) || scale_x == 0 || scale_y == 0)
    stop("Conditional variance is zero or numerically degenerate.", call. = FALSE)
  centered_x <- centered_x / scale_x; centered_y <- centered_y / scale_y
  a <- qr.resid(qr_z, centered_x); b <- qr.resid(qr_z, centered_y)
  if (sum(a^2) <= .Machine$double.eps * sum(centered_x^2) ||
      sum(b^2) <= .Machine$double.eps * sum(centered_y^2))
    stop("Conditional variance is zero or numerically degenerate.", call. = FALSE)
  r <- sum(a * b) / sqrt(sum(a^2) * sum(b^2))
  r <- max(-1 + 1e-15, min(1 - 1e-15, r))
  estimate <- atanh(r)
  statistic <- estimate / sqrt(variance)
  list(p.value = 2 * stats::pnorm(-abs(statistic)), statistic = statistic,
       estimate = estimate, variance = variance, correlation = r,
       n = nrow(data), conditioning_rank = k, method = "Gaussian Fisher-z")
}

discover_skeleton <- function(data, alpha = 0.05, max_cond = 2L, source = NULL) {
  is_mi <- is.list(data) && !is.data.frame(data)
  if (is_mi) {
    if (length(data) < 2L) stop("At least two imputations are required.", call. = FALSE)
    data <- lapply(data, .cm_data, allow_na = FALSE)
    ref <- data[[1L]]
    if (!all(vapply(data, function(z) identical(dim(z), dim(ref)) &&
                    identical(colnames(z), colnames(ref)), logical(1))))
      stop("Imputations must have identical dimensions and column order.", call. = FALSE)
  } else ref <- data <- .cm_data(data, allow_na = FALSE)
  if (length(alpha) != 1L || !is.numeric(alpha) || !is.finite(alpha) || alpha <= 0 || alpha >= 1)
    stop("alpha must lie strictly between zero and one.", call. = FALSE)
  if (length(max_cond) != 1L || !is.numeric(max_cond) || !is.finite(max_cond) ||
      max_cond < 0 || max_cond != floor(max_cond))
    stop("max_cond must be a nonnegative integer.", call. = FALSE)
  p <- ncol(ref); nodes <- colnames(ref)
  if (p < 2L) stop("Skeleton discovery requires at least two columns.", call. = FALSE)
  adjacency <- .cm_graph(NULL, nodes)
  sepsets <- vector("list", p * p); dim(sepsets) <- c(p, p)
  dimnames(sepsets) <- list(nodes, nodes)
  test_rows <- list(); counter <- 0L
  cap <- min(as.integer(max_cond), p - 2L)
  for (level in 0:cap) {
    frozen <- adjacency
    pairs <- which(upper.tri(frozen) & frozen == 1, arr.ind = TRUE)
    if (!nrow(pairs)) break
    eligible <- FALSE
    for (edge in seq_len(nrow(pairs))) {
      i <- pairs[edge, 1L]; j <- pairs[edge, 2L]
      candidates <- list()
      for (endpoint in c(i, j)) {
        neighbours <- setdiff(which(frozen[endpoint, ] == 1), c(i, j))
        if (length(neighbours) >= level) {
          eligible <- TRUE
          candidates <- c(candidates, if (level == 0L) list(integer()) else
            if (level == 1L) lapply(neighbours, function(v) v) else
              utils::combn(neighbours, level, simplify = FALSE))
        }
      }
      if (!length(candidates)) next
      keys <- vapply(candidates, function(z) paste(sort(z), collapse = ","), character(1))
      candidates <- candidates[!duplicated(keys)]
      for (conditioning in candidates) {
        result <- if (is_mi) pooled_ci_test(data, i, j, conditioning, source) else
          gaussian_ci_test(data, i, j, conditioning, source)
        counter <- counter + 1L
        test_rows[[counter]] <- data.frame(x = nodes[i], y = nodes[j],
           given = paste(nodes[conditioning], collapse = ","), level = level,
           p.value = result$p.value, stringsAsFactors = FALSE)
        if (result$p.value > alpha) {
          adjacency[i, j] <- adjacency[j, i] <- 0
          sepsets[[i, j]] <- sepsets[[j, i]] <- nodes[conditioning]
          break
        }
      }
    }
    if (!eligible) break
  }
  tests <- if (length(test_rows)) do.call(rbind, test_rows) else
    data.frame(x = character(), y = character(), given = character(), level = integer(), p.value = double())
  structure(list(adjacency = adjacency, sepsets = sepsets, tests = tests,
    alpha = alpha, max_cond = cap, n = nrow(ref), m = if (is_mi) length(data) else 1L,
    method = if (is_mi) "PC-stable skeleton with pooled Fisher-z tests" else "PC-stable Gaussian skeleton"),
    class = "cm_skeleton")
}

print.cm_skeleton <- function(x, ...) {
  cat(x$method, "\n", ncol(x$adjacency), "variables;", sum(x$adjacency) / 2,
      "undirected edges;", nrow(x$tests), "CI tests\n")
  invisible(x)
}

plot.cm_skeleton <- function(x, ...) {
  a <- x$adjacency; p <- ncol(a)
  angle <- seq(0, 2 * pi, length.out = p + 1L)[seq_len(p)]
  xx <- cos(angle); yy <- sin(angle)
  graphics::plot(xx, yy, type = "n", xlim = c(-1.35, 1.35), ylim = c(-1.35, 1.35),
    asp = 1, axes = FALSE, xlab = "", ylab = "", ...)
  edges <- which(upper.tri(a) & a == 1, arr.ind = TRUE)
  for (i in seq_len(nrow(edges))) graphics::segments(xx[edges[i, 1]], yy[edges[i, 1]],
    xx[edges[i, 2]], yy[edges[i, 2]], col = "grey50")
  graphics::points(xx, yy, pch = 21, bg = "white", cex = 4)
  graphics::text(xx * 1.18, yy * 1.18, colnames(a))
  invisible(x)
}
