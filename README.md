# speedtest_swiftbar

A macOS [SwiftBar](https://swiftbar.app/) plugin that runs `networkQuality`, records the result with the current Wi-Fi SSID, and shows the latest entries in the menu bar.

Japanese README: [README.ja.md](./README.ja.md)

## Features

- Runs on a SwiftBar schedule such as every 10 minutes
- Records `networkQuality` results together with the active SSID
- Uses a small macOS helper app to request location permission so SSID lookup works on recent macOS versions
- Keeps current logs separate from archived logs

## Repository Layout

```text
plugin/
  260331_speedtest_swiftbar.sh
helper/
  WiFiSSIDHelper/
    main.swift
    Info.plist
    build.sh
    build/
      WiFiSSIDHelper.app
logs/
  current/
  archive/
```

## Requirements

- macOS
- SwiftBar
- Xcode command line tools
- `networkQuality` available on the system

## Setup

1. Build the helper app.

```bash
cd /path/to/speedtest_swiftbar
./helper/WiFiSSIDHelper/build.sh
```

2. Launch the helper once and allow location access.

```bash
open ./helper/WiFiSSIDHelper/build/WiFiSSIDHelper.app
```

3. Link the plugin into your SwiftBar plugins directory.

```bash
ln -sf "$PWD/plugin/260331_speedtest_swiftbar.sh" \
  "$HOME/.swiftbar/speedtest_swiftbar.10m.sh"
```

4. Refresh SwiftBar.

## Notes

- The helper app is needed because plain shell commands may only return `<SSID Redacted>` or no SSID at all on recent macOS versions.
- The plugin resolves symlinks, so running it through `~/.swiftbar/` still finds the helper app and log directories.
- Current logs are written under `logs/current/`.
- Older historical logs are stored under `logs/archive/`.

## Troubleshooting

If SSID still shows as `Unknown`:

1. Open the helper app again.
2. Check that the app appears in `System Settings > Privacy & Security > Location Services`.
3. Confirm the helper is built at `helper/WiFiSSIDHelper/build/WiFiSSIDHelper.app`.
4. Run the plugin directly once:

```bash
"$HOME/.swiftbar/speedtest_swiftbar.10m.sh"
```

If `networkQuality` does not return a result, the plugin logs `N/A` instead of leaving empty fields.
