#!/bin/bash

# <bitbar.title>Speedtest and Log</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>hann-solo</bitbar.author>
# <bitbar.author.github>hnsol</bitbar.author.github>
# <bitbar.desc>Displays the last 10 lines of speedtest. Keeps a log of speedtest results.</bitbar.desc>
# <bitbar.image>http://www.hosted-somewhere/pluginimage</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>http://url-to-about.com/</bitbar.abouturl>

resolve_script_path() {
  local source_path="${BASH_SOURCE[0]}"

  while [ -L "$source_path" ]; do
    local source_dir
    source_dir=$(cd -P "$(dirname "$source_path")" && pwd)
    source_path=$(readlink "$source_path")

    case "$source_path" in
      /*) ;;
      *) source_path="$source_dir/$source_path" ;;
    esac
  done

  cd -P "$(dirname "$source_path")" && pwd
}

value_or_na() {
  if [ -n "$1" ]; then
    printf "%s" "$1"
  else
    printf "N/A"
  fi
}

round_number() {
  awk -v num="$1" 'BEGIN { printf "%.0f", num }'
}

format_capacity() {
  local value="$1"

  if [ "$value" = "N/A" ]; then
    printf "%s" "$value"
    return
  fi

  if [[ "$value" =~ ^([0-9]+(\.[0-9]+)?)\ ([A-Za-z]+)$ ]]; then
    printf "%s %s" "$(round_number "${BASH_REMATCH[1]}")" "${BASH_REMATCH[3]}"
  else
    printf "%s" "$value"
  fi
}

format_duration() {
  local value="$1"

  if [[ "$value" =~ ^([0-9]+(\.[0-9]+)?)\ milliseconds$ ]]; then
    printf "%s ms" "$(round_number "${BASH_REMATCH[1]}")"
  elif [[ "$value" =~ ^([0-9]+(\.[0-9]+)?)\ seconds$ ]]; then
    printf "%s s" "$(round_number "${BASH_REMATCH[1]}")"
  else
    printf "%s" "$value"
  fi
}

format_latency_metric() {
  local value="$1"

  if [ "$value" = "N/A" ]; then
    printf "%s" "$value"
    return
  fi

  if [[ "$value" =~ ^(.+)\ \(([0-9]+(\.[0-9]+)?\ (milliseconds|seconds))\ \|\ ([0-9]+)\ RPM\)$ ]]; then
    printf "%s (%s / %s RPM)" \
      "${BASH_REMATCH[1]}" \
      "$(format_duration "${BASH_REMATCH[2]}")" \
      "${BASH_REMATCH[5]}"
  elif [[ "$value" =~ ^([0-9]+(\.[0-9]+)?\ (milliseconds|seconds))\ \|\ ([0-9]+)\ RPM$ ]]; then
    printf "%s / %s RPM" \
      "$(format_duration "${BASH_REMATCH[1]}")" \
      "${BASH_REMATCH[4]}"
  else
    printf "%s" "$value"
  fi
}

# 変数の設定
script_dir=$(resolve_script_path)
repo_dir=$(cd "$script_dir/.." && pwd)
current_month=$(date '+%Y-%m')
log_dir="$repo_dir/logs/current"
logfile="$log_dir/260331_speedtest_swiftbar_${current_month}.log"
icon=":wifi.square.fill: | sfsize=16"

get_current_ssid() {
  local helper_app="$repo_dir/helper/WiFiSSIDHelper/build/WiFiSSIDHelper.app"
  local helper_bin="$helper_app/Contents/MacOS/WiFiSSIDHelper"
  local wifi_device=""
  local ssid=""
  local swift_cache_dir="${TMPDIR:-/tmp}/swiftbar-speedtest-module-cache"

  mkdir -p "$log_dir"

  if [ -x "$helper_bin" ]; then
    ssid=$("$helper_bin" 2>/dev/null)
  fi

  if [ -z "$ssid" ]; then
    mkdir -p "$swift_cache_dir" 2>/dev/null

    ssid=$(swift -module-cache-path "$swift_cache_dir" -e 'import CoreWLAN
let ssid = CWWiFiClient.shared().interface()?.ssid()
print(ssid ?? "")
' 2>/dev/null)
  fi

  case "$ssid" in
    ""|"<unknown>"|"(null)"|"<SSID Redacted>"|"<redacted>")
      ssid=""
      ;;
  esac

  if [ -z "$ssid" ]; then
    ssid=$(ioreg -l 2>/dev/null | awk -F'"' '/"IO80211SSID"/ {print $(NF-1); exit}')

    case "$ssid" in
      ""|"<unknown>"|"(null)"|"<SSID Redacted>"|"<redacted>")
        ssid=""
        ;;
    esac
  fi

  if [ -z "$ssid" ]; then
    wifi_device=$(networksetup -listallhardwareports 2>/dev/null | awk '
      /Hardware Port: (Wi-Fi|AirPort)/ {
        getline
        if ($1 == "Device:") {
          print $2
          exit
        }
      }
    ')

    if [ -n "$wifi_device" ]; then
      ssid=$(networksetup -getairportnetwork "$wifi_device" 2>/dev/null | sed -E 's/^Current (Wi-Fi|AirPort) Network: //')

      case "$ssid" in
        ""|"You are not associated with an AirPort network."*|"<SSID Redacted>"|"<redacted>")
          ssid=""
          ;;
      esac
    fi
  fi

  if [ -z "$ssid" ]; then
    ssid=$(system_profiler SPAirPortDataType 2>/dev/null | awk '
      /Current Network Information:/ {
        getline
        gsub(/^ +|:$/, "", $0)
        print $0
        exit
      }
      /^ *SSID: / {
        sub(/^ *SSID: /, "", $0)
        print $0
        exit
      }
    ')
  fi

  if [ -z "$ssid" ]; then
    ssid="Unknown"
  fi

  printf "SSID: %s" "$ssid"
}

# Speedtestを実施して結果を変数に代入
ssid=$(get_current_ssid)
output=$(networkQuality 2>/dev/null || true)
uplink=$(echo "$output" | awk -F': ' '/Uplink capacity/{print $2}')
downlink=$(echo "$output" | awk -F': ' '/Downlink capacity/ {print $2}')
res=$(echo "$output" | awk -F': ' '/Responsiveness/ {print $2}')
idle=$(echo "$output" | awk -F': ' '/Idle Latency/ {print $2}')

uplink=$(value_or_na "$uplink")
downlink=$(value_or_na "$downlink")
res=$(value_or_na "$res")
idle=$(value_or_na "$idle")

uplink=$(format_capacity "$uplink")
downlink=$(format_capacity "$downlink")
res=$(format_latency_metric "$res")
idle=$(format_latency_metric "$idle")

# 現在時刻を取得して変数に代入
timestamp=$(date '+%Y-%m-%d %H:%M')

# 結果をログファイルに追記
printf "（%s） %s ↑ %s ↓ %s %s %s\n" "$timestamp" "$ssid" "$uplink" "$downlink" "$res" "$idle" >> "$logfile"

# メニューバーに表示する内容を出力
echo "$icon"
echo "---"

# 最新の10行を取得
latest_lines=$(tail -n 10 "$logfile")

# 各行をそのまま表示
while IFS= read -r line; do
  echo "${line// | / / }"
done <<< "$latest_lines"
