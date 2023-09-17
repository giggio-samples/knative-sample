#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/../_func.sh
source "$DIR"/../use-cluster.sh

writeBlue "Proxy: starting"

wait_for_resource_exists kube-system traefik svc "traefik service to be ready"
wait_for_resource_exists knative-serving kourier svc "kourier service (knative) to be ready"
wait_for_svc_has_ip kube-system traefik
TRAEFIK_IP=`kubectl get svc --namespace kube-system traefik -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
wait_for_svc_has_ip knative-serving kourier
KNATIVE_IP=`kubectl get svc --namespace knative-serving kourier -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
echo -e "TRAEFIK_IP=$TRAEFIK_IP\nKNATIVE_IP=$KNATIVE_IP" > "$DIR"/.env
docker compose --project-directory "$DIR" up -d


writeBlue "Proxy: done"
