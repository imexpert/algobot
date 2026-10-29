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

Prepare next shared version (Patch / Minor / Major)

### android build

```sh
[bundle exec] fastlane android build
```

Build Flutter Android App Bundle

### android check_release

```sh
[bundle exec] fastlane android check_release
```

Validate Android release metadata

### android check_store_version

```sh
[bundle exec] fastlane android check_store_version
```

Check Google Play for an existing build number

### android verify_aab

```sh
[bundle exec] fastlane android verify_aab
```

Verify the existing Android AAB

### android upload

```sh
[bundle exec] fastlane android upload
```

Upload existing AAB to Google Play Production

### android release

```sh
[bundle exec] fastlane android release
```

Build and upload current shared version

### android retry_release

```sh
[bundle exec] fastlane android retry_release
```

Retry uploading existing AAB without rebuilding

### android max_version_code

```sh
[bundle exec] fastlane android max_version_code
```

Read-only: print the highest versionCode on Google Play tracks

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
