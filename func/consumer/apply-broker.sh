#!/bin/bash

set -euo pipefail

if ! kubectl get namespace consumerns &> /dev/null; then
  kubectl create namespace consumerns
fi

cat <<EOF | kubectl apply -f -
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    eventing.knative.dev/broker.class: MTChannelBasedBroker
  name: my-broker
  namespace: consumerns
# spec:
#   delivery:
#     deadLetterSink:
#       uri: /deadletter
#       ref:
#         apiVersion: serving.knative.dev/v1
#         kind: Service
#         name: xxx
#     retry: 9
#     backoffPolicy: exponential
#     backoffDelay: PT0.1S
EOF

# curl -X POST -H 'Host: broker-ingress.knativetest.localhost' 172.21.1.0/consumerns/my-broker --verbose -H "content-type: application/json" -H "ce-specversion: 1.0" -H "ce-source: my/curl/command" -H "ce-type: my.demo.event" -H "ce-id: 0815" -d '{"value":"Hello Knative"}'
# curl -X POST broker-ingress.knativetest.localhost/consumerns/my-broker --verbose -H "content-type: application/json" -H "ce-specversion: 1.0" -H "ce-source: my/curl/command" -H "ce-type: my.demo.event" -H "ce-id: 0815" -d '{"value":"Hello Knative"}'