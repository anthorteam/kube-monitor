#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Make sure to start with a clean 'manifests' dir
if [ -f anthor-kube-monitor.zip ]; then
  rm anthor-kube-monitor.zip
fi
rm -rf manifests
mkdir -p manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests --ext-str "GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID" --ext-str "GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET" "${1-main.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization

zip -r anthor-kube-monitor.zip manifests
