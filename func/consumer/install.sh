#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/../../_func.sh
source "$DIR"/../../use-cluster.sh
writeBlue "Consumer service: starting"

"$DIR"/build.sh
"$DIR"/push.sh
"$DIR"/apply-service.sh
"$DIR"/apply-broker.sh
"$DIR"/apply-trigger.sh

writeBlue "Consumer service: done"
