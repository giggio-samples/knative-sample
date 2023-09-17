#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

VERSION_FILE="$DIR"/.version
VERSION=`cat "$VERSION_FILE"`
docker push registry.knativetest.localhost:5000/consumer:"`printf %04d "$VERSION"`"
