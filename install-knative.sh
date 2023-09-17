#!/bin/bash

# see: https://knative.dev/docs/install/operator/knative-with-operators/

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/_func.sh
source "$DIR"/use-cluster.sh

writeBlue "KNative: starting"

kubectl apply -f https://github.com/knative/operator/releases/download/knative-v1.11.6/operator.yaml
wait_for_deployment default knative-operator "knative operator"
wait_for_deployment default operator-webhook "knative webhook"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: knative-serving
---
apiVersion: operator.knative.dev/v1beta1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  ingress:
    kourier:
      enabled: true
  config:
    network:
      ingress-class: kourier.ingress.networking.knative.dev
    domain:
      "knative.knativetest.localhost": ""
EOF
wait_for_resource knative-serving knative-serving knativeservings.operator.knative.dev '{ .status.conditions[?(@.type == "Ready")].status }' True 'knative serving to become ready'

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: knative-eventing
---
apiVersion: operator.knative.dev/v1beta1
kind: KnativeEventing
metadata:
  name: knative-eventing
  namespace: knative-eventing
EOF
wait_for_resource knative-eventing knative-eventing knativeeventings.operator.knative.dev '{ .status.conditions[?(@.type == "Ready")].status }' True 'knative eventing to become ready'

kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.11.4/in-memory-channel.yaml
if ! kubectl get ingress --namespace knative-eventing knative-ingress &> /dev/null; then
  # add ingress so we can post events to the broker from outside the cluster:
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: knative-ingress
  namespace: knative-eventing
  labels:
    app.kubernetes.io/name: knative-ingress
spec:
  rules:
    - host: broker-ingress.knativetest.localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: broker-ingress
                port:
                  name: http
EOF
fi

writeBlue "KNative: done"
