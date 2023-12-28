#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

k3d cluster start knativetest
k3d kubeconfig write knativetest --output "$HOME"/.kube/knativetest
"$DIR"/proxy/start.sh
