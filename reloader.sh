#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_path="$script_dir/$(basename "${BASH_SOURCE[0]}")"

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

grafana_url=""
grafana_username=""
grafana_password=""
reupload=""
output=""
command=()

reloader="chromereloader"

function help_msg() {
  echo "sample usage: ${BASH_SOURCE[0]} -t http://localhost:3000 -u grafana-user -p grafana-pass -- jsonnet -J grafonnet dashboard.jsonnet"
  exit 1
}

function run_output() {
  "$@" >"$output"
}

function test_grafana_auth() {
    local code="$(curl -s -o /dev/null -w '%{http_code}' \
    --user "$grafana_username:$grafana_password" \
    "$grafana_url/api/org")"

    if [ "$code" -ne 200 ]; then
      echo 'failed to auth to grafana'
      exit 1
    fi
}

function grafana_reuploader() {
  local dash="$1"
  local dashold="$2"

  if [ -z "$(cat "$dash")" ]; then
    return
  fi

  if cmp "$dash" "$dashold" >/dev/null; then
    echo "dashboards are identical"
  else
    echo "override old content"
    cp "$dash" "$dashold"

    payload="$(jq --null-input --argjson dash "$(cat "$dash")" '{"dashboard": $dash ,"folderId": 0, "overwrite": true}')"
    curl -H "Content-Type: application/json" \
    --user "$grafana_username:$grafana_password" \
    "$grafana_url/api/dashboards/db" -d "$payload"
    curl_ret_val=$?
    echo
    curl -s -o /dev/null 'http://localhost:8686/reload'
    return $curl_ret_val
  fi
}

if [ "$#" -eq 0 ]; then
  help_msg
fi

while getopts "h?t:u:p:o:r" opt; do
  case "$opt" in
  h | \?)
    help_msg
    ;;
  t)
    grafana_url="$OPTARG"
    ;;
  u)
    grafana_username="$OPTARG"
    ;;
  p)
    grafana_password="$OPTARG"
    ;;
  o)
    output="$OPTARG"
    ;;
  r)
    reupload="true"
    ;;
  esac
done
shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

command=("$@") # during reupload mode, command contains the file path to dashboards.

if [ ${#command[@]} -eq 0 ]; then
  help_msg
fi

if [ -n "$reupload" ]; then
  grafana_reuploader "${command[@]}"
  exit $?
fi

if [ -n "$output" ]; then
  run_output "${command[@]}"
  exit $?
fi

test_grafana_auth

temp_dashboard="$(mktemp)"
temp_dashboardold="$(mktemp)"
echo "generate temp file @ $temp_dashboard"

function cleanup() {
    rm "$temp_dashboard"
    rm "$temp_dashboardold"
    curl 'http://localhost:8686/shutdown'
}

"$script_dir/$reloader" -target "$grafana_url" -user "$grafana_username" -pass "$grafana_password" &

fswatch -I -e '.*' -i '\.json$' -i '\.libsonnet$' -i '\.jsonnet$' . | xargs -n1 -I{} -- \
  "$script_path" -o "$temp_dashboard" \
  -- "${command[@]}" &

trap 'cleanup && echo Bye' SIGINT SIGTERM

fswatch "$temp_dashboard" | xargs -n1 -I{} -- \
  "$script_path" -r \
  -t "$grafana_url" \
  -u "$grafana_username" \
  -p "$grafana_password" \
  -- "$temp_dashboard" "$temp_dashboardold"
