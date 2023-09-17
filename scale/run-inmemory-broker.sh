#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
"$DIR"/run-generic-broker.sh --url broker-ingress.knativetest.localhost/consumerns/my-broker "$@"
