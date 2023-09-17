#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/../../_func.sh
source "$DIR"/../../use-cluster.sh
writeBlue "Hello service: starting"

"$DIR"/build.sh
"$DIR"/push.sh
"$DIR"/apply-service.sh

writeBlue "Hello service: done"
