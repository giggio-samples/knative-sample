#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# k6 run --vus 50 --duration 120s "$DIR"/k6.js
k6 run "$DIR"/k6.js

