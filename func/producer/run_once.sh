#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/../../_func.sh

writeBlue "Sending one event via producer"
dotnet run --project "$DIR" -- --ip broker-ingress.knativetest.localhost --subject 'Test from Memory Broker' --exit
writeBlue "Event sent"
