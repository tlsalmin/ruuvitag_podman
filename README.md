# Ruuvitag-listener in podman.

Combined ruuvitag-listener, grafana, influxdb and telegraf to host gathering and
displaying of ruuvitag data on a single device. Tested on a raspberry pi 4.

Probably works on other architectures too. Downloads and compiles the
ruuvitag-listener. Generates systemd files to add the pod as a service.

Copied most of the stuff from https://gitlab.com/webziz/ruuvitag-docker and
changed it to podman format. Combined the telegraf and ruuvitag-listener to a
single container. The download method for ruuvitag-listener was changed to
compiling the ruuvitag-listener itself as the binary wasn't arm-based.

## Usage:

```
sudo ./create.sh
```

Due to the network parts and capabilities required by bluetooth.

Link and enable the service files to start automatically with systemd.
