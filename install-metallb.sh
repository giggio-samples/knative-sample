#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/_func.sh
source "$DIR"/use-cluster.sh

writeBlue "Metallb: starting"

if ! kubectl get crd ipaddresspools.metallb.io &> /dev/null; then
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
fi
wait_for_daemonset metallb-system speaker "metallb speaker daemonset"
wait_for_deployment metallb-system controller "metallb controller"

function create_address_range () {
  BASE_IP=${1%/*}
  IP_CIDR=${1#*/}

  if [ "$IP_CIDR" -lt 8 ]; then
      echo "Max range is /8."
      return
  fi
  IP_MASK=$((0xFFFFFFFF << (32 - IP_CIDR)))
  IFS=. read A B C D <<<"$BASE_IP"
  IP=$(((B << 16) + (C << 8) + D))
  IPSTARTNUM=$(((IP & IP_MASK) + 257))
  IPSTART="$A".$(((IPSTARTNUM & 0xFF0000) >> 16)).$(((IPSTARTNUM & 0xFF00) >> 8)).$((IPSTARTNUM & 0x00FF))
  IPENDNUM=$(((IPSTARTNUM | ~IP_MASK) & 0x7FFFFFFF))
  IPEND="$A".$(((IPENDNUM & 0xFF0000) >> 16)).$(((IPENDNUM & 0xFF00) >> 8)).$((IPENDNUM & 0x00FF))
  echo "$IPSTART-$IPEND"
}

if kubectl get ipaddresspools.metallb.io --namespace metallb-system default-pool &> /dev/null; then
  echo 'IP Address Pool already exists.'
else
  CIDR_BLOCK=`docker network inspect k3d-knativetest --format '{{ (index .IPAM.Config 0).Subnet }}'`
  ADDRESS_RANGE=`create_address_range "$CIDR_BLOCK"`
  cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - $ADDRESS_RANGE
EOF
fi

if kubectl get l2advertisements.metallb.io --namespace metallb-system default-advertisement &> /dev/null; then
  echo 'L2 Advertesement already exists.'
else
  cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-advertisement
  namespace: metallb-system
EOF
fi

writeBlue "Metallb: done"
