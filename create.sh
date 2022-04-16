#!/bin/bash

set -e
GITROOT=$(git rev-parse --show-toplevel)
source ./environment

podman pod create --name="$PODNAME" --publish=3000 --replace=true

# Options
# 1: Container name
# 2: options
# 3: image
# 4: command
add_to_pod()
{
  # Unfortunately bluetooth requires network mode to be host.
  podman container create --network=host --env-file="${GITROOT}/environment" \
    --systemd=true --name="$1" --pod="$PODNAME" --replace=true $2 "$3" $4
}

add_to_pod "db" "--mount=type=volume,source=data,destination=/var/lib/influxdb" "docker.io/library/influxdb:1.8"
add_to_pod "grafana" "--mount=type=volume,source=storage,destination=/var/lib/grafana" "docker.io/grafana/grafana"

teleimg=$(buildah from --pull docker.io/library/alpine)
BASETELENAME="telegoodbase"

# Incremental step to avoid recompiling everything when iterting config.
if ! buildah inspect $BASETELENAME &> /dev/null ; then
  buildah run "$teleimg" /bin/sh -c "apk add --no-cache telegraf bluez gcc git rustup musl-dev"
  buildah run "$teleimg" /bin/sh -c "rustup-init --profile minimal -q -y"
  buildah config --workingdir /usr/src/app "$teleimg"
  buildah run "$teleimg" /bin/sh -c "source /root/.cargo/env && cargo install ruuvitag-listener"
  buildah commit "$teleimg" $BASETELENAME
  buildah rm "$teleimg"
fi
teleimg=$(buildah from "localhost/$BASETELENAME")
buildah add "$teleimg" ./telegraf.conf /etc/telegraf.conf
buildah commit "$teleimg" $BASETELENAME
buildah rm "$teleimg"
add_to_pod "telepod" "--cap-add=NET_ADMIN --cap-add=NET_RAW" \
  "$BASETELENAME" "/usr/bin/telegraf --config /etc/telegraf.conf"

podman generate systemd -f --new --name --restart-policy=always "$PODNAME"

podman pod start "$PODNAME"
