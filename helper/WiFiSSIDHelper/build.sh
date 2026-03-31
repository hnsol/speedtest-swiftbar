#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
build_dir="$script_dir/build"
app_dir="$build_dir/WiFiSSIDHelper.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
module_cache_dir="$build_dir/.module-cache"

rm -rf "$app_dir"
mkdir -p "$macos_dir"
mkdir -p "$module_cache_dir"

swiftc \
  -parse-as-library \
  -module-cache-path "$module_cache_dir" \
  -framework AppKit \
  -framework CoreLocation \
  -framework CoreWLAN \
  "$script_dir/main.swift" \
  -o "$macos_dir/WiFiSSIDHelper"

cp "$script_dir/Info.plist" "$contents_dir/Info.plist"

echo "Built $app_dir"
