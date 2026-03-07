#!/usr/bin/env Rscript
# lint_stdin.R
# Read R source from stdin and run lintr::lint_text(), printing a concise summary.

# Minimal helper: reads stdin, runs lintr, prints human-readable results and optional JSON

suppressPackageStartupMessages({
  if (!requireNamespace("lintr", quietly = TRUE)) {
    stop("Please install the 'lintr' package: install.packages('lintr')")
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Please install the 'jsonlite' package: install.packages('jsonlite')")
  }
})

# Read all stdin
read_stdin <- function() {
  con <- file("stdin")
  on.exit(close(con))
  paste(readLines(con, warn = FALSE), collapse = "\n")
}

content <- tryCatch(read_stdin(), error = function(e) "")
if (nchar(content) == 0) {
  cat("No input received on stdin\n")
  quit(status = 1)
}

# Run lintr
lints <- lintr::lint_text(content)

# Convert lint objects to simple lists
lints_tbl <- lapply(lints, function(l) {
  list(
    filename = ifelse(is.null(l$filename) || l$filename == "", "<stdin>", l$filename),
    line = l$line_number,
    column = l$column_number,
    type = l$type,
    linter = l$linter,
    message = l$message
  )
})

# Print human-readable summary
if (length(lints_tbl) == 0) {
  cat("No lint issues found\n")
} else {
  for (li in lints_tbl) {
    cat(sprintf("%s:%s:%s: %s: %s\n", li$filename, li$line, li$column, li$type, li$message))
  }
}

# If LINT_JSON=true in environment, dump JSON after the human summary
if (tolower(Sys.getenv("LINT_JSON", "false")) %in% c("1", "true", "t")) {
  cat('\n--JSON-RESULT-START--\n')
  cat(jsonlite::toJSON(lints_tbl, pretty = TRUE, auto_unbox = TRUE))
  cat('\n--JSON-RESULT-END--\n')
}
