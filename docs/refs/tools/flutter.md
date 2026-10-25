# Notes for Flutter tools

## pub

Add development dependencies:

```sh
flutter pub add --dev <package_name>
# e.g. flutter pub add --dev flutter_lints
```

## formatter

`dart format` is a built-in formatter in the Dart SDK. No need to install a separate formatter.

```sh
# format the entire project
dart format .

# format the lib directory only
dart format lib/

# format a specific file
dart format lib/main.dart

# check the differences (without changing the files)
dart format --output=none --show=all .

# fail if the files are not formatted (for CI)
dart format --output=none --set-exit-if-changed .
```
