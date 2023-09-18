#!/bin/bash

# placeholder
declare ctid

# alternative was to do a big EOF block in pct enter, but this is easier for me to write, may fix later
pct exec $ctid -- bash -c "cp homeassistant.service /etc/systemd/system/homeassistant.service"
pct exec $ctid -- bash -c "systemctl enable homeassistant.service"