#!/bin/bash

trap cleanup SIGINT SIGTERM

cleanup() {
  set +e
  if ! [ -v PID_STRESS ]; then
    PID_STRESS=`pgrep producer`
  fi
  if [[ "$PID_STRESS" != '' ]]; then
    # shellcheck disable=SC2086
    kill -SIGTERM $PID_STRESS
    PID_STRESS=`pgrep producer`
    if [[ "$PID_STRESS" != '' ]]; then
      kill -SIGKILL "$PID_STRESS"
    fi
  fi
}

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/../_func.sh

VALID_ARGS=$(getopt -o u:d:r:p:h --long url:,delay:,run:,run-for:,parallel:,help -- "$@")
eval set -- "$VALID_ARGS"

HELP=false
URL=''
PARALLEL=10
DELAY=50
RUN_FOR=10
while true; do
  case "$1" in
    -u | --url)
        URL=$2
        shift
        shift
        ;;
    -d | --delay)
        DELAY=$2
        shift
        shift
        ;;
    -r | --run | --run-for)
        RUN_FOR=$2
        shift
        shift
        ;;
    -p | --parallel)
        PARALLEL=$2
        shift
        shift
        ;;
    -h | --help)
        HELP=true
        shift
        ;;
    --) shift;
        break
        ;;
  esac
done

# shellcheck disable=SC2003
if ! expr 0 + "$PARALLEL" + "$DELAY" + "$RUN_FOR" &> /dev/null; then
  die "PARALLEL, DELAY and RUN_FOR must be numeric"
fi

if $HELP; then
  echo "Usage: `basename "$0"` [options]

Options:
-u, --url <url>                   URL for the broker, required.
-d, --delay <seconds>             Delay between messages in milliseconds. Default is 50.
-r, --run, --run-for <seconds>    Run for this many seconds. Default is 10.
-p, --parallel <number>           Run this many parallel instances. Default is 10.
-h, --help                        Show this help message and exit.
"
  exit
fi

writeGreen "Running `basename "$0"` $ALL_ARGS
  DELAY is $DELAY.
  PARALLEL is $PARALLEL.
  URL is $URL.
  RUN_FOR is $RUN_FOR.
"

if [ "$URL" == '' ]; then
  die "URL is required."
fi

export KUBECONFIG=$HOME/.kube/knativetest

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TMP_PRODUCER_OUTPUT=`mktemp`
dotnet build -c Release --nologo "$DIR"/../func/producer/producer.csproj
writeBlue "Producer file is: $TMP_PRODUCER_OUTPUT"
cleanup
# shellcheck disable=SC2086
"$DIR"/../func/producer/bin/Release/net8.0/producer --url $URL --subject 'Test from Broker' --no-interactive --parallel $PARALLEL --delay $DELAY > $TMP_PRODUCER_OUTPUT &
PID_STRESS=$!
# shellcheck disable=SC2086
writeBlue "Will run for $RUN_FOR seconds, press Ctrl+C to stop..."
# shellcheck disable=SC2086
sleep $RUN_FOR
kill -SIGTERM $PID_STRESS
cleanup
writeBlue "Done."