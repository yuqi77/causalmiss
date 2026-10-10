# Run: Rscript tools/build_release.R [output-directory]
if (.Platform$OS.type == "windows") {
  Sys.setenv(LC_ALL = "English_United States.utf8", LANG = "en_US.UTF-8")
  invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
}
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(file_arg) != 1L) stop("Run this script with Rscript.")
package_dir <- normalizePath(file.path(dirname(file_arg), ".."), winslash = "/", mustWork = TRUE)
trailing <- commandArgs(trailingOnly = TRUE)
out <- if (length(trailing)) trailing[1L] else file.path(dirname(package_dir), "release")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)
oldwd <- setwd(out)
rcmd <- if (.Platform$OS.type == "windows") file.path(R.home("bin"), "Rcmd.exe") else file.path(R.home("bin"), "R")
prefix <- if (.Platform$OS.type == "windows") character() else "CMD"
run <- function(command, options, logfile) {
  code <- system2(rcmd, c(prefix, command, options), stdout = logfile, stderr = logfile)
  if (code != 0L) stop(command, " failed; see ", file.path(out, logfile))
}
metadata <- read.dcf(file.path(package_dir, "DESCRIPTION"))
name <- metadata[1L, "Package"]; version <- metadata[1L, "Version"]
archive <- paste0(name, "_", version, ".tar.gz")
run("build", c(shQuote(package_dir), "--no-build-vignettes", "--no-manual"), "build.log")
run("check", c(shQuote(archive), "--no-manual"), "check.log")
check_log <- readLines(file.path(out, paste0(name, ".Rcheck"), "00check.log"), warn = FALSE)
if (any(grepl("Status:.*(ERROR|WARNING)", check_log)))
  stop("R CMD check reported errors or warnings; inspect 00check.log.")
library_dir <- file.path(out, "local-library")
dir.create(library_dir, showWarnings = FALSE)
run("INSTALL", c(paste0("--library=", shQuote(library_dir)), shQuote(archive)), "install.log")
if (.Platform$OS.type == "windows") {
  zip_archive <- file.path(out, paste0(name, "_", version, ".zip"))
  tar <- file.path(Sys.getenv("SystemRoot", unset = "C:/Windows"), "System32", "tar.exe")
  if (!file.exists(tar)) stop("Windows tar.exe is required for the binary archive; the source archive is ready.")
  code <- system2(tar, c("-a", "-c", "-f", shQuote(zip_archive), "-C",
                        shQuote(library_dir), name), stdout = "binary-build.log", stderr = "binary-build.log")
  if (code != 0L || !file.exists(zip_archive)) stop("Windows zip creation failed; inspect binary-build.log.")
  write("Windows archive created from the successfully installed package with tar.exe.",
        file = "binary-build.log", append = TRUE)
}
setwd(oldwd)
cat("Built, checked and installed", archive, "in", out, "\n")
