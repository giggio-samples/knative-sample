#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

dotnet run --project "$DIR" -- --ip broker-ingress.knativetest.localhost --subject 'Test from Memory Broker'
# KNATIVE_EVENTING_IP=`kubectl get ingress --namespace knative-eventing knative-ingress -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
# echo "Knative eventing IP is $KNATIVE_EVENTING_IP"
# dotnet run --project "$DIR" -- --ip "$KNATIVE_EVENTING_IP" --host broker-ingress.knativetest.localhost
