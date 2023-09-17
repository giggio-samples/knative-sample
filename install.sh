#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/_func.sh

VALID_ARGS=$(getopt -o s --long skip,skip-install -- "$@")
eval set -- "$VALID_ARGS"

SKIP_INSTALL=false
while true; do
  case "$1" in
    -s | --skip | --skip-install)
        SKIP_INSTALL=true
        shift
        ;;
    --) shift;
        break
        ;;
  esac
done

export KUBECONFIG=$HOME/.kube/knativetest
if ! $SKIP_INSTALL; then
  pushd "$DIR" > /dev/null
  ./create-cluster.sh
  ./install-metallb.sh
  ./install-knative.sh
  ./proxy/start.sh
  ./func/csharphello/install.sh
  ./func/consumer/install.sh
  ./install-observability.sh
  popd > /dev/null
fi

writeBlue "Producer build: starting"
dotnet build "$DIR"/func/producer/ -v q --nologo
writeBlue "Producer build: done"

writeBlue "Making a request to KNative serving ip"
KNATIVE_SERVING_IP=`kubectl get service --namespace knative-serving kourier -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
echo "Knative serving IP is $KNATIVE_SERVING_IP"
curl -H 'Host: helloworld-csharp.hello-world.knative.knativetest.localhost' "$KNATIVE_SERVING_IP" --verbose
echo

"$DIR"/func/producer/run_once.sh

writeBlue "Pods in consumer namespace:"
kubectl get pod --namespace consumerns
wait_for_resource consumerns --selector=serving.knative.dev/service=consumer pod '{ .items[0].status.conditions[?(@.type=="Ready")].status }' True 'consumer pod to become ready'
kubectl get pod --namespace consumerns
writeBlue "Logs in consumer namespace:"
kubectl logs --namespace consumerns --selector serving.knative.dev/service=consumer -c user-container

writeBlue "Access the tracing dashboard at http://jaeger.knativetest.localhost"
