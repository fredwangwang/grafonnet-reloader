# blahblahgrafana

automatically uploads the generated Grafana json after file changes

## Binary Dependencies

- jq
- fswatch

install dependencies on mac:
`brew install jq fswatch`

## Usage

`reloader.sh -t http://localhost:3000 -u grafana-user -p grafana-pass -- jsonnet -J grafonnet dashboard.jsonnet`
