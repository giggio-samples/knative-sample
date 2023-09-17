#!/bin/bash

set -euo pipefail

if ! kubectl get namespace consumerns &> /dev/null; then
  kubectl create namespace consumerns
fi

cat <<EOF | kubectl apply -f -
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: consumer-trigger
  namespace: consumerns
spec:
  broker: my-broker
  filter:
    attributes:
      type: producer1
  subscriber:
    uri: /receive
    ref:
      apiVersion: serving.knative.dev/v1
      kind: Service
      name: consumer
  delivery:
    deadLetterSink:
      uri: /deadletter
      ref:
        apiVersion: serving.knative.dev/v1
        kind: Service
        name: consumer
    retry: 9
    backoffPolicy: exponential
    backoffDelay: PT0.1S
EOF
