#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/_func.sh
source "$DIR"/use-cluster.sh

writeBlue "Observability: starting"

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
kubectl wait deployment --namespace cert-manager --for=condition=Available --all

kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.87.0/opentelemetry-operator.yaml
kubectl wait deployment --namespace opentelemetry-operator-system --for=condition=Available --all --timeout=120s

if ! kubectl get namespace observability &> /dev/null; then
  kubectl create namespace observability
fi
kubectl apply --namespace observability -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.49.0/jaeger-operator.yaml
kubectl wait deployment --namespace observability --for=condition=Available --all --timeout=120s
if ! kubectl get jaegers.jaegertracing.io --namespace observability simplest &> /dev/null; then
  kubectl apply -n observability -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: simplest
EOF
  kubectl wait deployment --namespace observability --for=condition=Available --all
fi

if ! kubectl get opentelemetrycollectors.opentelemetry.io otel --namespace observability &> /dev/null; then
  kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel
  namespace: observability
spec:
  config: |
    receivers:
      zipkin:
    exporters:
      logging:
      otlp:
        endpoint: "simplest-collector.observability:4317"
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [zipkin]
          processors: []
          exporters: [logging, otlp]
EOF
  kubectl wait deployment --namespace observability --for=condition=Available --all
fi

for ns in knative-eventing knative-serving; do
  kubectl patch --namespace "$ns" configmap/config-tracing \
   --type merge \
   --patch '{"data":{"backend":"zipkin","zipkin-endpoint":"http://otel-collector.observability:9411/api/v2/spans", "debug": "true"}}'
done

if ! kubectl get ingress --namespace observability jaeger-ingress &> /dev/null; then
  # add ingress so we can access jaeger from outside the cluster:
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jaeger-ingress
  namespace: observability
  labels:
    app.kubernetes.io/name: jaeger-ingress
spec:
  rules:
    - host: jaeger.knativetest.localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: simplest-query
                port:
                  name: http-query
EOF
fi

writeBlue "Observability: done"
