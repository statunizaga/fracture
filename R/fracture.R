#' Convert decimals to a character vector of fractions
#'
#' @inheritParams frac_mat
#' @param x A vector of decimals or, for `as.fracture()`, a matrix created by
#'   [frac_mat()]
#'
#' @return A character vector.
#' @seealso [frac_mat()] to return a matrix of numerators and denominators.
#' @export
#'
#' @example examples/fracture.R

fracture <- function(
  x, base_10 = FALSE, common_denom = FALSE, mixed = FALSE, max_denom = 1e7
) {
  op <- options(scipen = 100)
  on.exit(options(op), add = TRUE)

  matrix <- frac_mat(
    x            = x,
    base_10      = base_10,
    common_denom = common_denom,
    mixed        = mixed,
    max_denom    = max_denom
  )

  as.fracture(matrix)
}

#' @rdname fracture
#' @export

as.fracture <- function(x) {
  if (is.frac_mat(x)) {
    numeric  <- as.fracture_numeric(x)
    fracture <- as.fracture_paste(x)
    x        <- structure(fracture, numeric = numeric)
    class(x) <- c("fracture", "character")
    x
  } else {
    fracture(x)
  }
}

as.fracture_numeric <- function(x) {
  if (nrow(x) == 3) {
    numeric <- x[1, ] + x[2, ] / x[3, ]
  } else {
    numeric <- x[1, ] / x[2, ]
  }

  as.numeric(numeric)
}

as.fracture_paste <- function(x) {
  if (nrow(x) == 3) {
    x              <- rbind(x[1, ], " ", x[2, ], "/", x[3, ])
    no_frac        <- which(x[3, ] == 0)
    x[-1, no_frac] <- ""
    no_int         <- which(x[1, ] == 0)
    x[1:2, no_int] <- ""

    as.character(apply(x, 2, paste0, collapse = ""))
  } else {
    paste0(x[1, ], "/", x[2, ])
  }
}

#' @rdname fracture
#' @export

is.fracture <- function(x) {
  inherits(x, "fracture")
}

#' @export

as.character.fracture <- function(x, ...) {
  attr(x, "numeric") <- NULL
  class(x)           <- "character"
  x
}

#' @export

as.double.fracture <- function(x, ...) {
  attr(x, "numeric")
}

#' @export

as.integer.fracture <- function(x, ...) {
  x <- attr(x, "numeric")
  NextMethod()
}

#' @export

print.fracture <- function(x, ...) {
  x <- as.character(x)
  NextMethod("print", quote = FALSE)
}

#' @export

Math.fracture <- function(x, ...) {
  args <- recover_fracture_args(x)
  x    <- as.numeric(x)

  do.call("fracture", c(list(NextMethod()), args))
}

#' @export

Ops.fracture <- function(e1, e2) {
  is.numericish <- function(x) {
    is.numeric(x) | is.logical(x) | !is.null(attr(x, "numeric"))
  }

  if (is.numericish(e1) && is.numericish(e2)) {
    args <- recover_fracture_args(e1, e2)

    e1 <- as.numeric(e1)
    if (!missing(e2)) {e2 <- as.numeric(e2)}

    result <- NextMethod(.Generic)

    if (is.numeric(result)) {
      return(do.call("fracture", c(list(result), args)))
    } else {
      return(result)
    }
  }

  if (is.character(e1) && is.character(e2)) {return(NextMethod(.Generic))}

  if (is.fracture(e1)) {
    e1 <- attr(e1, "numeric")
    if (!is.null(e2)) {mode(e1) <- mode(e2)}
    return(NextMethod(.Generic))
  }

  if (is.fracture(e2)) {
    e2 <- attr(e2, "numeric")
    if (!is.null(e1)) {mode(e2) <- mode(e1)}
    return(NextMethod(.Generic))
  }
}

recover_fracture_args <- function(e1, e2 = NULL) {
  if (!is.fracture(e1) && !is.fracture(e2)) {
    return(NULL)
  }

  if (is.fracture(e1)) {
    e1 <- as.frac_mat(e1)
  } else if (is.numeric(e1)) {
    e1 <- frac_mat(e1, base_10 = TRUE, common_denom = TRUE)
  } else {
    e1 <- NULL
  }

  if (is.fracture(e2)) {
    e2 <- as.frac_mat(e2)
  } else if (is.numeric(e2)) {
    e2 <- frac_mat(e2, base_10 = TRUE, common_denom = TRUE)
  } else {
    e2 <- NULL
  }

  if (is.null(e1)) {e1 <- e2}
  if (is.null(e2)) {e2 <- e1}

  list(
    mixed        = nrow(e1) == 3 || nrow(e2) == 3,
    common_denom = length(unique(e1["denominator", ])) == 1 &&
      length(unique(e2["denominator", ])) == 1,
    base_10      = all(log(e1["denominator", ], 10) == 0) &&
      all(log(e2["denominator", ], 10) == 0)
  )
}
