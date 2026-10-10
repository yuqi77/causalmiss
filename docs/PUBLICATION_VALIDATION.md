# Public publication validation of causalmiss 0.1.0

Verified on 2026-10-10. Author and maintainer: Yuqi Qiu,
yqqiu@fem.ecnu.edu.cn.

The complete package is available in the public
[yuqi77/causalmiss repository](https://github.com/yuqi77/causalmiss), with its
[v0.1.0 Release](https://github.com/yuqi77/causalmiss/releases/tag/v0.1.0).
Source, function help, tests, synthetic tutorials, method audits, development
guides, citation, license and workflows were checked in the public repository.
Manuscript PDFs, original research data/code and local installed/check libraries
are excluded.

## Exact release identity

| Object | Identity |
|---|---|
| Package version | `0.1.0` |
| Public tag | `v0.1.0` |
| Annotated tag object | `adcb4347dcc75e9e7673adefcac539ab9c2739fe` |
| Tagged source commit | `9565f195091dcfbf49c074b7c7e2565aff73be6d` |
| Commit link | [Tagged source](https://github.com/yuqi77/causalmiss/commit/9565f195091dcfbf49c074b7c7e2565aff73be6d) |

The archives preserve the `v0.1.0` tagged snapshot and were not changed after
publication. This report, the completed checklist and the linked check logs are
a subsequent documentation-only update on `main`. They record measured results
after publication; the tag and its archives retain their release-time snapshot.
The source archive files matched the final package source, allowing for
R-generated `DESCRIPTION` and build metadata. The Windows binary was created
from that installed source package and verified by fresh installation and the
installed tutorial.

## Hosted checks and release builds

The [R-CMD-check run 38044796087](https://github.com/yuqi77/causalmiss/actions/runs/38044796087)
completed successfully on all three platforms with R 4.6.1. Each check log ends
with `Status: OK`, including all five test scripts: `core.R`, `dr.R`,
`iterative.R`, `mi.R` and `time.R`.

| Platform | R / architecture | Observed result | Saved check log |
|---|---|---|---|
| Linux, Ubuntu 24.04.5 LTS | R 4.6.1, x86_64 | `Status: OK` | [Linux log](check-logs/linux-4.6.1.log) |
| macOS Tahoe 26.6.2 | R 4.6.1, arm64 | `Status: OK` | [macOS log](check-logs/macos-4.6.1.log) |
| Windows Server 2022 x64 | R 4.6.1, x86_64 | `Status: OK` | [Windows log](check-logs/windows-4.6.1.log) |

The [release-build run 38044797179](https://github.com/yuqi77/causalmiss/actions/runs/38044797179)
also completed successfully for Linux and Windows, including the Windows binary
archive step. The public Release contains the installable source tarball,
Windows binary ZIP, full tagged repository ZIP, `manifest.json` and
`SHA256SUMS.txt`.

## Download and installation verification

Release assets were downloaded through unauthenticated public requests. The
downloaded manifest and all archive SHA-256 values matched the publication
files; ZIP integrity checks passed. The full repository ZIP retains development
material and workflows, while the installable R source archive excludes those
repository-only files according to `.Rbuildignore`.

Three separate fresh libraries on Windows 11 x64 with R 4.5.0 were used for:

1. `remotes::install_github("yuqi77/causalmiss", ref = "v0.1.0")`.
2. Installation of the source tarball downloaded from the public Release.
3. Installation of the Windows binary ZIP downloaded from the public Release.

All three installations passed the version, namespace and repository-metadata
assertions, exposed eleven public functions, and ran the complete installed
`toy_workflow.R` tutorial. Observed-cell preservation assertions for DR and
multiple imputation passed, and the pooled test returned a finite p value.
The GitHub installation's `RemoteSha` was
`9565f195091dcfbf49c074b7c7e2565aff73be6d`, matching the tagged source commit.

## Published archive hashes

Values below reproduce the published `manifest.json` and `SHA256SUMS.txt`.

| Release asset | Bytes | SHA-256 |
|---|---:|---|
| [causalmiss_0.1.0.tar.gz](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.tar.gz) | 34973 | `03fc520cca9fae91f14b479b8eef7a8c09b6621c0b58064b9d4c3885e567294b` |
| [causalmiss_0.1.0.zip](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.zip) | 135634 | `74047c9edf397fdca9a4cb72a9bebdc7b81204f943746ee240676ef87242a56b` |
| [causalmiss_repository_0.1.0.zip](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_repository_0.1.0.zip) | 77418 | `360d5aa9298b300fccba603be291eab21c0f45710539f4f5ed013e4415f137d2` |

The [published manifest](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/manifest.json)
records the source commit and build evidence. The
[published checksum file](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/SHA256SUMS.txt)
provides the archive hashes for independent download verification.

## Verified scope

The package implements selected continuous linear Gaussian components and
returns an undirected skeleton. Full orientation/CPDAG construction, GES,
time-series proxy orientation, complex-survey extensions and discrete/nonlinear
models remain outside version 0.1.0. Installation, formula checks and executable
examples verify implementation behavior; they do not establish general graph
recovery or application performance.

Checks used `--no-manual`; PDF help-manual generation was omitted. Rd help,
usage consistency, examples, code analysis and installed-package tests were
checked. The declared minimum R 4.1.0 has not been independently tested; measured
environments were local R 4.5.0 and hosted R 4.6.1. The historical local example
and its numerical stopping diagnostics remain recorded in
[LOCAL_VALIDATION.md](LOCAL_VALIDATION.md).
