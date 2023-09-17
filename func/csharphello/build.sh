#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$DIR" > /dev/null
dotnet publish -r linux-x64 -t:PublishContainer -p:ContainerBaseImage=mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy-chiseled -c Release
VERSION_FILE="$DIR"/.version
if ! [ -f "$VERSION_FILE" ]; then echo 0000 > "$VERSION_FILE"; fi
VERSION=`cat "$VERSION_FILE"`
set +e
((VERSION++))
set -e
docker tag registry.knativetest.localhost:5000/helloworld-csharp:latest registry.knativetest.localhost:5000/helloworld-csharp:"`printf %04d "$VERSION"`"
echo "$VERSION" > "$VERSION_FILE"
popd > /dev/null