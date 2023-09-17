#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ! "$PATH" == */$HOME/.dotnet/tools* ]]; then
  export PATH="$PATH:$HOME/.dotnet/tools"
fi
if ! hash dotnet-cross 2>/dev/null; then
  dotnet tool install --global dotnet-cross
fi

pushd "$DIR" > /dev/null
dotnet cross publish -r linux-musl-x64 -t:PublishContainer -p:ContainerBaseImage=mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine -c Release
VERSION_FILE="$DIR"/.version
if ! [ -f "$VERSION_FILE" ]; then echo 0000 > "$VERSION_FILE"; fi
VERSION=`cat "$VERSION_FILE"`
set +e
((VERSION++))
set -e
docker tag registry.knativetest.localhost:5000/consumer:latest registry.knativetest.localhost:5000/consumer:"`printf %04d "$VERSION"`"
echo "$VERSION" > "$VERSION_FILE"
popd > /dev/null