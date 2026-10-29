fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios check_auth

```sh
[bundle exec] fastlane ios check_auth
```

Validate local Apple API key configuration

### ios check_release

```sh
[bundle exec] fastlane ios check_release
```

Validate version and localized release metadata

### ios build

```sh
[bundle exec] fastlane ios build
```

Build Flutter IPA

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Upload existing IPA and localized metadata to App Store Connect

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and upload AlgoBot to App Store Connect

### ios retry_release

```sh
[bundle exec] fastlane ios retry_release
```

Retry upload using existing IPA

### ios verify_ipa

```sh
[bundle exec] fastlane ios verify_ipa
```

Verify existing IPA version and bundle identifier

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
