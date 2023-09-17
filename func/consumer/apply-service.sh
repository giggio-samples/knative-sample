#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! kubectl get namespace consumerns &> /dev/null; then
  kubectl create namespace consumerns
fi

VERSION=`cat "$DIR"/.version`
VERSION_PADDED=`printf %04d "$VERSION"`

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: consumer
  namespace: consumerns
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
        autoscaling.knative.dev/target: "50"
        autoscaling.knative.dev/metric: concurrency
    spec:
      containers:
        - image: registry.knativetest.localhost:5000/consumer:$VERSION_PADDED
          env:
            - name: DelayInMs
              value: "500"
EOF
