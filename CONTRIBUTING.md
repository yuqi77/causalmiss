# Contributing

Use a small, focused change and explain its method source and supported model.
Update function help and add a numerical test that can detect an actual error.
Run `R CMD build`, `R CMD check --no-manual`, and the installed-package example.
Report R version, operating system, a synthetic reproducible example and diagnostics
when opening a bug report. Do not attach confidential survey data.

The first release keeps base-R dependencies and does not promise complete
reproduction of the three manuscripts. Substantial model extensions should include
a source-to-code map and validation before being advertised in README or help.
