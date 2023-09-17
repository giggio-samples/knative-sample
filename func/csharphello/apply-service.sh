#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! kubectl get namespace hello-world &> /dev/null; then
  kubectl create namespace hello-world
fi

VERSION=`cat "$DIR"/.version`
VERSION_PADDED=`printf %04d "$VERSION"`

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-csharp
  namespace: hello-world
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
        autoscaling.knative.dev/target: "10"
        autoscaling.knative.dev/metric: concurrency
    spec:
      containers:
        - image: registry.knativetest.localhost:5000/helloworld-csharp:$VERSION_PADDED
          env:
            - name: TARGET
              value: C#
            - name: DelayInMs
              value: "100"
EOF
