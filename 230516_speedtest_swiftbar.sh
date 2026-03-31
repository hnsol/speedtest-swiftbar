#!/bin/bash

# <bitbar.title>Speedtest and Log</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>hann-solo</bitbar.author>
# <bitbar.author.github>hnsol</bitbar.author.github>
# <bitbar.desc>Displays the last 10 lines of speedtest. Keeps a log of speedtest results.</bitbar.desc>
# <bitbar.image>http://www.hosted-somewhere/pluginimage</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>http://url-to-about.com/</bitbar.abouturl>

# 変数の設定
# logfile="/Users/masatora/Documents/MyDevelop/230100/230516_SwiftBarPlugin/230516_speedtest_swiftbar.log"
current_month=$(date '+%Y-%m')
logfile="/Users/masatora/Documents/MyDevelop/230100/230516_SwiftBarPlugin/230516_speedtest_swiftbar_${current_month}.log"
icon=":wifi.square.fill: | sfsize=16"

get_current_ssid() {
  local wifi_device=""
  local ssid=""

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
      ""|"You are not associated with an AirPort network."*)
        ssid=""
        ;;
    esac
  fi

  if [ -z "$ssid" ]; then
    ssid=$(system_profiler SPAirPortDataType 2>/dev/null | awk '
      /Current Network Information:/ {
        getline
        gsub(/^ +|:$/, "")
        print
        exit
      }
      /^ *SSID: / {
        sub(/^ *SSID: /, "")
        print
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
output=$(networkQuality)
uplink=$(echo "$output" | awk -F': ' '/Uplink capacity/{print $2}')
downlink=$(echo "$output" | awk -F': ' '/Downlink capacity/ {print $2}')
res=$(echo "$output" | awk -F': ' '/Responsiveness/ {print $2}')
idle=$(echo "$output" | awk -F': ' '/Idle Latency/ {print $2}')

# 現在時刻を取得して変数に代入
timestamp=$(date '+%Y-%m-%d %H:%M')

# 結果をログファイルに追記
printf "（%s）\t%s\t%s\t%s\t%s\t%s\n" "$timestamp" "$ssid" "↑ $uplink" "↓ $downlink" "$res" "$idle" >> "$logfile"

# メニューバーに表示する内容を出力
echo "$icon"
echo "---"

# 最新の10行を取得
latest_lines=$(tail -n 10 "$logfile")

# 各行の内容を必要な情報に分割して表示
while IFS= read -r line; do
  timestamp=$(echo "$line" | awk -F '\t' '{print $1}')
  ssid=$(echo "$line" | awk -F '\t' '{print $2}' | sed 's/^SSID: //')
  uplink=$(echo "$line" | awk -F '\t' '{print $3}')
  downlink=$(echo "$line" | awk -F '\t' '{print $4}')
  res=$(echo "$line" | awk -F '\t' '{print $5}' | awk -F ' ' '{print $1}')
  idle=$(echo "$line" | awk -F '\t' '{print $6}' | awk -F ' ' '{print $1 "ms"}')
  echo "$timestamp $ssid $uplink $downlink $res $idle"
done <<< "$latest_lines"
