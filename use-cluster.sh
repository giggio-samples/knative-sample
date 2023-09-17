#!/bin/bash

if ! (return 0 2>/dev/null); then
  >&2 echo  -e "\e[31mThis script should be sourced.\e[0m"
  exit 1
fi

if ! [ "`kubectl config current-context 2> /dev/null`" = k3d-knativetest ]; then
  export KUBECONFIG=$HOME/.kube/knativetest
  kubectl config use-context k3d-knativetest --namespace default
fi
