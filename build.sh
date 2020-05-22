#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v go; then
  echo need golang
  exit 1
fi
if ! command -v jq; then
  echo need jq
  exit 1
fi
if ! command -v fswatch; then
  echo need fswatch
  exit 1
fi

go mod download
go build -o chromereloader "$script_dir/cmd/"
