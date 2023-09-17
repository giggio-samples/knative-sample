wait_for_deployment() {
  if ! [ -v 1 ]; then
    echo "ERROR: namespace is not set"
    return 1
  fi
  if ! [ -v 2 ]; then
    echo "ERROR: name is not set"
    return 1
  fi
  NS=$1
  NAME=$2
  if [ -v 3 ]; then
    MSG=" for $3"
  else
    MSG=''
  fi

  printf "Waiting%s to be created..." "$MSG"
  while true; do
    set +e
    CONTROLLER_REPLICAS=`kubectl get deployment --namespace "$NS" "$NAME" -ojsonpath='{ .status.replicas }' 2> /dev/null`
    set -e
    if [ "$CONTROLLER_REPLICAS" != '' ]; then break; fi
    printf .
    sleep 2
  done
  echo
  printf "Waiting%s to become available (equal to %s)..." "$MSG" "$CONTROLLER_REPLICAS"
  while true; do
    CONTROLLER_AVAILABLE=`kubectl get deployment --namespace "$NS" "$NAME" -ojsonpath='{ .status.availableReplicas }' 2> /dev/null`
    if [ "$CONTROLLER_REPLICAS" == "$CONTROLLER_AVAILABLE" ]; then break; fi
    printf .
    sleep 2
  done
  echo "done"
}

wait_for_daemonset() {
  if ! [ -v 1 ]; then
    echo "ERROR: namespace is not set"
    return 1
  fi
  if ! [ -v 2 ]; then
    echo "ERROR: name is not set"
    return 1
  fi
  NS=$1
  NAME=$2
  if [ -v 3 ]; then
    MSG=" for $3"
  else
    MSG=''
  fi

  printf "Waiting%s to be created..." "$MSG"
  while true; do
    set +e
    DESIRED=`kubectl get daemonset --namespace "$NS" "$NAME" -ojsonpath='{ .status.desiredNumberScheduled }' 2> /dev/null`
    set -e
    if [ "$DESIRED" != '' ] && [ "$DESIRED" != '0' ]; then break; fi
    printf .
    sleep 2
  done
  echo
  printf "Waiting%s to become available (equal to %s)..." "$MSG" "$DESIRED"
  while true; do
    set +e
    AVAILABLE=`kubectl get daemonset --namespace "$NS" "$NAME" -ojsonpath='{ .status.numberAvailable }' 2> /dev/null`
    set -e
    if [ "$DESIRED" == "$AVAILABLE" ]; then break; fi
    printf .
    sleep 2
  done
  echo "done"
}

wait_for_svc_has_ip() {
  if ! [ -v 1 ]; then
    echo "ERROR: namespace is not set"
    return 1
  fi
  NS=$1
  if ! [ -v 2 ]; then
    echo "ERROR: name is not set"
    return 1
  fi
  NAME=$2
  wait_for_resource "$NS" "$NAME" service '{ .status.loadBalancer.ingress[0].ip }' '' "service $NS/$NAME to have an IP" '!='
}

wait_for_resource() {
  if ! [ -v 1 ]; then
    echo "ERROR: namespace is not set"
    return 1
  fi
  NS=$1
  if ! [ -v 2 ]; then
    echo "ERROR: name is not set"
    return 1
  fi
  NAME=$2
  if ! [ -v 3 ]; then
    echo "ERROR: kind is not set"
    return 1
  fi
  KIND=$3
  if ! [ -v 4 ]; then
    echo "ERROR: jsonpath is not set"
    return 1
  fi
  JSONPATH=$4
  if ! [ -v 5 ]; then
    echo "ERROR: expected value is not set"
    return 1
  fi
  EXPECTED=$5
  if [ -v 6 ]; then
    MSG="Waiting for $6..."
  else
    MSG='Waiting...'
  fi
  if [ -v 7 ]; then
    OPERATOR='!='
  else
    OPERATOR='=='
  fi

  printf '%s' "$MSG"
  while true; do
    set +e
    VALUE=`kubectl get "$KIND" --namespace "$NS" "$NAME" -ojsonpath="$JSONPATH" 2> /dev/null`
    set -e
    if [ "$VALUE" $OPERATOR "$EXPECTED" ]; then break; fi
    printf .
    sleep 2
  done
  echo "done"
}

wait_for_resource_exists() {
  if ! [ -v 1 ]; then
    echo "ERROR: namespace is not set"
    return 1
  fi
  NS=$1
  if ! [ -v 2 ]; then
    echo "ERROR: name is not set"
    return 1
  fi
  NAME=$2
  if ! [ -v 3 ]; then
    echo "ERROR: kind is not set"
    return 1
  fi
  KIND=$3
  if [ -v 4 ]; then
    MSG="Waiting for $4..."
  else
    MSG='Waiting...'
  fi

  printf '%s' "$MSG"
  set +e
  while ! kubectl get "$KIND" --namespace "$NS" "$NAME" &> /dev/null; do
    printf .
    sleep 2
  done
  echo "done"
  set -e
}

writeYellow () {
  echo -e "\e[33m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeBlue () {
  echo -e "\e[34m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeGreen () {
  echo -e "\e[32m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeStdErrRed () {
  >&2 echo -e "\e[31m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

die () {
  writeStdErrRed "$@"
  exit 1
}

ALL_ARGS=$*