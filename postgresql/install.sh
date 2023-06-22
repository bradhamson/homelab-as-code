apt update && apt upgrade -y

echo 'Installing base dependencies'
apt install vim curl sudo gnupg wget -y

echo 'Installing postgresql 15'
apt install postgresql -y

echo 'Enabling and starting postgresql'
systemctl enable postgresql
systemctl start postgresql

echo 'Updating pg_hba.conf'
cat <<EOF >/etc/postgresql/15/main/pg_hba.conf
# local reocrds match connection attempts using unix domain sockets. Unix-domain socket connections are disallowed without these records.
# host matches attempts using TCP/IP connections. match ssl or non-ssl connections as well as gssapi encrypted or non-gssapi encrypted connections.
# TYPE  DATABASE        USER            ADDRESS                 AUTHMETHOD
local   all             postgres                                peer
# IPv4 local connections:
host    all             all             <HOST_INTERNAL_IP_ADDRESS>/32        scram-sha-256
host    all             all             <LAN SUBNET>/24          md5
EOF

echo 'Updating postgresql.conf'
cat <<EOF >/etc/postgresql/15/main/postgresql.conf
# -----------------------------
# PostgreSQL configuration file
# -----------------------------

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = '/var/lib/postgresql/15/main'
hba_file = '/etc/postgresql/15/main/pg_hba.conf'
ident_file = '/etc/postgresql/15/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/15-main.pid'

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -
listen_addresses = '<HOST_INTERNAL_IP_ADDRESS>'
port = 5432
max_connections = 100
unix_socket_directories = '/var/run/postgresql'

# - SSL -

#ssl = on
#ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
#ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

shared_buffers = 128MB
dynamic_shared_memory_type = posix

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

max_wal_size = 1GB
min_wal_size = 80MB

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - What to Log -

log_line_prefix = '%m [%p] %q%u@%d '
log_timezone = 'Etc/UTC'

#------------------------------------------------------------------------------
# PROCESS TITLE
#------------------------------------------------------------------------------

cluster_name = '15/main'

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Locale and Formatting -

datestyle = 'iso, mdy'
timezone = 'Etc/UTC'
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
default_text_search_config = 'pg_catalog.english'

#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------

include_dir = 'conf.d'
EOF

systemctl restart postgresql

# Install pgadmin4

echo 'Adding pgadmin repo key & repo config file'
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/bookworm pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
apt update && apt upgrade -y

echo 'Creating pgadmin user'
adduser pgadmin
usermod -aG sudo pgadmin
su - pgadmin

echo 'Installing pgadmin4'
sudo apt install pgadmin4 pgadmin4-web -y

echo 'Configuring pgadmin4 webserver'
sudo /usr/pgadmin4/bin/setup-web.sh

# Cleanup installation

echo 'Cleaning up...'
su - root
apt autoremove
apt autoclean
echo 'Installation complete'