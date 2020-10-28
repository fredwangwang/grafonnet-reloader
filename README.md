

automatically reloads the generated Grafana dashboard after grafonnet file changes

![a cool demo showing here that you are missing](pic/reduced-rec.gif)


## Usage

`reloader.sh -t 'http://localhost:3000' -u admin-user -p admin-pass -- jsonnet -J grafonnet dashboard.jsonnet`

## Install
clone the repo and run `./build.sh`

### Dependencies

- go
- jq
- fswatch

install dependencies on mac:
`brew install go jq fswatch`
