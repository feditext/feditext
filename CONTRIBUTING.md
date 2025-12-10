# Contribution Guidelines

See the [architecture section](https://github.com/feditext/feditext/blob/main/README.md#architecture) of Feditext's README for an overview of Feditext's code.

## Formatting

There's a [`.swift-format`](.swift-format) file at the repo root. Currently the only difference from [`swift-format`](https://github.com/swiftlang/swift-format)'s default config is that it uses 120 columns instead of 100. (Note that this is Apple's standard `swift-format` tool, not `swiftformat`, the other one without the dash in the name. Do not use `swiftformat`.)

The project may be reformatted by running:

```bash
swift format --in-place --parallel --recursive .
```

## Linting

Feditext also uses `swift-format` for linting:

```bash
swift format --strict --parallel --recursive .
```
