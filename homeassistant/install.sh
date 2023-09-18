#!/bin/bash

# placeholder
declare ctid

create_ct() {
    local ct_ip_address=$1
    local gateway_ip_address=$2
    local ip="${ct_ip_address}/24"
    local template_storage="vm-data"
    local template="debian-11-standard_11.6-1_amd64.tar.zst"
    local ct_template="${template_storage}/${template}"
    local ct_hostname="homeassistant"
    pct create $ctid $ct_template \
        --cores=2 \
        --memory=2048 \
        --hostname=$ct_hostname \
        --password="<STRONG PASSWORD GOES HERE AND PASSWD LATER :)>" \
        --net0 name=eth0,bridge=vmbr0,firewall=1,gw=$gateway_ip_address,ip=$ip,type=veth
}

################################################################################
# Install base dependencies for homeassistant from debian 11 repos.
# Some of these were not available in debian 12 repos at the time I wrote this,
# will install python3.11 from bookworm repos later.
################################################################################
install_base_dependencies() {
    pct exec $ctid -- bash -c "apt update && apt upgrade -y"
    pct exec $ctid -- bash -c "apt install -y bluez \
        libffi-dev \
        libssl-dev \
        libjpeg-dev \
        zlib1g-dev \
        autoconf \
        build-essential \
        libopenjp2-7 \
        libtiff5 \
        libturbojpeg0-dev \
        tzdata \
        ffmpeg \
        liblapack3 \
        liblapack-dev \
        libatlas-base-dev"
}

################################################################################
# Update the debian 11 sources.list to debian 12 and upgrade the container
################################################################################
update_ct_os() {
    # backup the sources.list
    pct exec $ctid -- bash -c "cp /etc/apt/sources.list /etc/apt/sources.list.bak"

    # replace bullseye with bookworm in sources.list
    pct exec $ctid -- bash -c "sed -i s/bullseye/bookworm/g /etc/apt/sources.list"

    # update
    pct exec $ctid -- bash -c "apt update && apt upgrade -y --without-new-pkgs"
    pct exec $ctid -- bash -c "apt full-upgrade -y"

    # reboot the container and clean up
    pct reboot $ctid
    pct exec $ctid -- bash -c "rm /etc/apt/sources.list.bak"
    pct exec $ctid -- bash -c "apt --purge autoremove -y"
    pct exec $ctid -- bash -c "apt update && apt upgrade -y && apt autoremove -y"
}

install_system_tools() {
    pct exec $ctid -- bash -c "apt install -y sudo vim git"
}

install_python() {
    # install python3.11 from bookworm repos since bullseye repos don't have it
    # later add option to do this with pyenv
    pct exec $ctid -- bash -c "apt install -y python3 python3-dev python3-venv python3-pip"
}

create_service_account() {
    pct exec $ctid -- bash -c "useradd -rm homeassistant"
    pct exec $ctid -- bash -c "mkdir /srv/homeassistant"
    pct exec $ctid -- bash -c "chown homeassistant:homeassistant /srv/homeassistant"
}

install_homeassistant_core() {
    # as homeassistant service account create the venv and install homeassistant
    pct exec $ctid -- bash -c "sudo -u homeassistant -H -s"
    cd /srv/homeassistant 
    python3 -m venv .
    source bin/activate
    python3 -m pip install wheel
    #latest version when writing this
    pip install homeassistant==2023.9.2
    # installing from source resolves https://github.com/home-assistant/core/issues/95192
    pip install git+https://github.com/boto/botocore
    # probs not the best way to do this, but it generates the base config files
    hass -v --debug
}

main () {
    # placeholders
    declare ct_ip_address
    declare gateway_ip_address
    create_ct $ct_ip_address $gateway_ip_address
    install_base_dependencies
    update_ct_os
    install_system_tools
    install_python
    create_service_account
    install_homeassistant_core
}

main