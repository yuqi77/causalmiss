# Local validation of version 0.1.0

Date: 2026-10-10. Environment: Windows 11 x64, R 4.5.0, UTF-8 session.

* Source tarball built with `R CMD build --no-build-vignettes --no-manual`.
* `R CMD check --no-manual` finished with `Status: OK` (no check errors, warnings or notes).
* Five installed-package test scripts passed: core, DR calibration, outer iteration,
  pooled/FCS imputation, and time-window/regression modules.
* Source installed in a local workspace library.
* Windows binary zip installed into a fresh separate library and the installed
  tutorial ran successfully; eleven exported functions were available.
* Citation output and a synthetic skeleton graphic were inspected.
* Only base/recommended R namespaces are runtime dependencies; no compilation.

The tutorial's five-iteration regression loop returned `converged=FALSE`, as its
value threshold had not yet been met. Its graph was stable in the last iterations.
This is recorded rather than relabeled as convergence. The known-graph calibration
example accepted both target calibrations with residuals below 1e-6; the pooled
test used the documented approximate inference. These are implementation examples,
not estimates of the methods' operating performance.

PDF manual generation was omitted. Rd help, usage consistency, examples, installed
documentation and tests were checked. macOS/Linux CI is prepared but has not run;
minimum R 4.1.0 compatibility has not been independently exercised on that version.
Public repository creation and external GitHub installation are pending.

The delivery's `release/` directory contains full logs, `VALIDATION.md`, a checksum
manifest, source/binary archives and a repository archive. The repository archive
includes development documents and CI; R build excludes those repository-only files.
