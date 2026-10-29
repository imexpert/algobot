fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android prepare_version

```sh
[bundle exec] fastlane android prepare_version
```

Prepare next version (Patch / Minor / Major)

### android build

```sh
[bundle exec] fastlane android build
```

Build Flutter Android App Bundle

### android release

```sh
[bundle exec] fastlane android release
```

Prepare and release current version

### android retry_release

```sh
[bundle exec] fastlane android retry_release
```

Retry current version without bumping versionCode

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
