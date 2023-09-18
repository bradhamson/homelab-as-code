#!/bin/bash

# placeholder
declare ctid
declare templateid;

################################################################################
# Clone a container from a template
################################################################################
clone() {
    local hostname=$1
    pct clone $templateid $ctid \
        --full \
        --hostname $hostname \
}

################################################################################
# Configure the network for the container
# Arguments:
#   $1: ct_ip_address - the ip address for the container
#   $2: gateway_ip_address - the ip address for the gateway
################################################################################
configure_network() {
    local ct_ip_address=$1
    local gateway_ip_address=$2
    local ip="${ct_ip_address}/24"
    pct set $ctid \
        --net0 name=eth0,bridge=vmbr0,ip=$ip,gw=$gateway_ip_address,type=veth,firewall=1
}

################################################################################
# Install system tools/utilities for the container
################################################################################
install_system_tools() {
    pct exec $ctid -- bash -c "apt update && apt upgrade -y"
    pct exec $ctid -- bash -c "apt install -y /
        sudo /
        vim /
        unattended-upgrades /
        apt-listchanges"
}

################################################################################
# Create a container from a template, configure the network, and install system
# tools/utilities.
# Arguments:
#   $1: ct_ip_address - the ip address for the container
#   $2: gateway_ip_address - the ip address for the gateway
################################################################################
create_ct() {
    # placeholders
    declare ct_ip_address
    declare gateway_ip_address
    clone "homeassistant"
    configure_network $ct_ip_address $gateway_ip_address
    install_system_tools
}

install_mariadb() {
    pct exec $ctid -- bash -c "apt install -y mariadb-server"
}

################################################################################
# Configure mariadb and automate secure installation script steps without
# prompting for input.
################################################################################
configure_mariadb() {
    local mariadb_root_pw=$(cat /dev/urandom | tr -dc "[:print:]" | fold -w 32 | head -n 1)
    pct exec $ctid -- bash -c "mysql -u root <<EOF
        UPDATE mysql.user SET Password=PASSWORD('${mariadb_root_pw}') WHERE User='root';
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        FLUSH PRIVILEGES;
        EOF"
}

main() {
    create_ct
    install_mariadb
    configure_mariadb
}

