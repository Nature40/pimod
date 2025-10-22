# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## How to draft a release?
1. Update this `CHANGELOG.md` file:
    1. Add a new headline for the next release version below _Unreleased_.
    2. Add a link for the next release similar to the others to the bottom and update the _Unreleased_ URL.
2. Update the `version` within the `Dockerfile`.
3. Create a commit for the release.
4. Create a (signed) git tag in the form of `vX.Y.Z`, e.g., `v0.1.0` or `v1.2.3`.
5. Push both the commit and the tag.
6. Create a GitHub release via the web UI.
   The title should be `${VERSION} - ${YYYY-MM-DD}` and the description should contain the section from this `CHANGELOG.md`.

## [Unreleased]
## [0.7.0] - 2025-01-07
### Added
- New `ADDPART` command to add partitions of a given size, partition type and file system to the image.

### Changed
- Updated CI badges.
- Updated actions/checkout action to v5.

## [0.6.1] - 2024-07-08
### Added
- Building Docker images for linux/arm/v7.
- Configure Renovate for automated updates.
- Installed git in docker container to support git-based versioning

### Changed
- Reworked the README to ease readability and understanding of pimod's internals.

## [0.6.0] - 2022-02-12
### Added
- New -r/--resolv flag to select which /etc/resolv.conf to use.

### Fixed
- Apply `ENV` variables also to `HOST` commands.

## [0.5.0] - 2022-01-17
### Added
- New `ENV` command for environment variables.
- New `EXTRACT` command to copy files back to the host; @sensslen.

## [0.4.4] - 2021-11-09
### Added
- Bind /sys, allow the usage of docker inside pimod

## [0.4.3] - 2021-11-09
### Fixed
- PARTUUIDs got rewritten by parted - replaced by sfdisk

## [0.4.2] - 2021-11-04
### Fixed
- Limitedness of PUMP command

## [0.4.1] - 2021-11-02
### Fixed
- Shell-escaped RUN command strings by esceval

## [0.4.0] - 2021-10-07
### Added
- WORKDIR command to specify the working directory within the image.

### Fixed
- Brought latest version of pimod back to GitHub Marketplace.

## [0.3.1] - 2021-10-04
### Added
- pimod.sh -t: trace executed commands for debugging.
- Started a CHANGELOG.md with prior changes.

### Changed
- FROM: document PARTITION_NO argument.

### Fixed
- PUMP: fix behavior for bigger partition tables.
- Print Warning on QEMU binary fmt loading err.

## [0.3.0] - 2021-09-23
### Added
- Adjust GitHub Actions for Pull Requests.
- Add INCLUDE command; @aniongithub.

## [0.2.2] - 2021-05-02
### Changed
- Printing file system usage information, if PUMP was used.
- Warn for Windows/DOS newlines.

### Fixed
- qemu_setup: determine path by command -v
- from_remote_fetch: delete image if download failed.

## [0.2.1] - 2021-01-17
### Fixed
- Changed GitHub Action name for marketplace submission.
- Successful e2fsck lead to failing build.

## [0.2] - 2020-12-01
### Added
- Introducing shellcheck CI integration.
- Added paper to readme, <https://jonashoechst.de/assets/papers/hoechst2020pimod.pdf>.
- Implemented reusable GitHub Action.

### Changed
- Basing Docker container on debian:bullseye-slim.

### Fixed
- Disable bash error abort in file name parsing.
- Fixed a bug, where killing of remaining processes failed.
- Adjusted Dockerfile to reflect project structure.

## [0.1] - 2020-04-26
### Added
- Initial release of a working version of pimod.

[Unreleased]: https://github.com/Nature40/pimod/compare/v0.6.1...HEAD
[Unreleased]: https://github.com/Nature40/pimod/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/Nature40/pimod/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/Nature40/pimod/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/Nature40/pimod/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/Nature40/pimod/compare/v0.4.4...v0.5.0
[0.4.4]: https://github.com/Nature40/pimod/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/Nature40/pimod/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/Nature40/pimod/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/Nature40/pimod/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/Nature40/pimod/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/Nature40/pimod/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/Nature40/pimod/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/Nature40/pimod/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/Nature40/pimod/compare/v0.2...v0.2.1
[0.2]: https://github.com/Nature40/pimod/compare/v0.1...v0.2
[0.1]: https://github.com/Nature40/pimod/releases/tag/v0.1
