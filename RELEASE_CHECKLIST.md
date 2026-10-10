# Release checklist

- [x] Maintainer identity supplied by author.
- [x] Package structure, source, help, tests and synthetic tutorial prepared.
- [x] Manuscript implementation boundaries documented.
- [x] Separate software license and manuscript/source attribution.
- [x] Local source check, fresh Windows binary installation and installed example validated; see [docs/LOCAL_VALIDATION.md](docs/LOCAL_VALIDATION.md).
- [x] GitHub owner and repository selected: [yuqi77/causalmiss](https://github.com/yuqi77/causalmiss); URL and BugReports fields added.
- [x] README installation commands and Release links reference `yuqi77/causalmiss` and `v0.1.0`.
- [x] Inspect repository contents before upload and verify the public package file tree.
- [x] Push the complete package repository to public GitHub hosting.
- [x] Rebuild final release archives and publish matching SHA-256 checksums.
- [x] Verify Windows/macOS/Linux CI after first push: R 4.6.1, `Status: OK` on all three platforms.
- [x] Tag the tested commit as `v0.1.0` and publish its Release with archives.
- [x] Verify external installation from the public tag and source/Windows Release archives in three fresh libraries.

Publication and installation verification are complete. Exact tag/source identity,
hosted run links, measured environments, archive hashes and verification limits
are recorded in [docs/PUBLICATION_VALIDATION.md](docs/PUBLICATION_VALIDATION.md).
This completed checklist is a subsequent documentation-only update on `main`;
the `v0.1.0` archives retain the tagged release snapshot.
