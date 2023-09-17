#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/_func.sh

writeBlue "Create cluster: starting"

if k3d cluster ls knativetest &> /dev/null; then
  exit 0
fi
export K3D_FIX_DNS=1 # remove when flag is removed from k3d, see https://github.com/k3d-io/k3d/issues/209
k3d cluster create --volume "$DIR"'/data/agents:/data@agent:*' --volume "$DIR"'/data/servers:/data@server:*' --config "$DIR"/k3d-config.yml
k3d kubeconfig write knativetest --output "$HOME"/.kube/knativetest
export KUBECONFIG=$HOME/.kube/config:$HOME/.kube/knativetest
kubectl config use-context k3d-knativetest --namespace default
export KUBECONFIG=$HOME/.kube/knativetest
kubectl config use-context k3d-knativetest --namespace default

writeBlue "Create cluster: done"