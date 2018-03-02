#!/usr/bin/env bash
set -x
if [ ! -f containers/tengine.tar  ]; then
 packer build template.json
fi

docker import containers/tengine.tar tengine:latest
docker-compose up --build --remove-orphans -d
sleep 1