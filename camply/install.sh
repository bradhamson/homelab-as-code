## -----------------------------------------------------------------------------
# Install Camply
## -----------------------------------------------------------------------------

apt update && apt upgrade -y
apt install sudo python3-pip python3-venv -y

sudo adduser camply --disabled-password --gecos ""
sudo usermod -aG sudo camply
su - camply

python3 -m venv venv
source /home/camply/venv/bin/activate
python3 -m pip install pipx
python3 -m pipx ensurepath
cat "export $(register-python-argcomplete pipx)" >> /home/camply/.bashrc

# relogin for PATH changes to take effect
logout
su - camply

pipx install camply
cat <<EOF >/home/camply/.camply
# CAMPLY CONFIGURATION FILE. 
# SEE https://github.com/juftin/camply/blob/main/docs/examples/example.camply

PUSHOVER_PUSH_USER=""
PUSHBULLET_API_TOKEN=""
SLACK_WEBHOOK=""
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
TWILIO_ACCOUNT_SID=""
TWILIO_AUTH_TOKEN=""
TWILIO_SOURCE_NUMBER=""
TWILIO_DEST_NUMBERS=""
EMAIL_TO_ADDRESS=""
EMAIL_USERNAME=""
EMAIL_PASSWORD=""
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT="465"
EMAIL_FROM_ADDRESS="camply@juftin.com"
EMAIL_SUBJECT_LINE="Camply Notification"
PUSHOVER_PUSH_TOKEN=""
NTFY_TOPIC=""
APPRISE_URL=""
RIDB_API_KEY=""
EOF

## -----------------------------------------------------------------------------
# Install crontab-ui
## -----------------------------------------------------------------------------
mkdir /home/camply/crontab-ui
mkdir /home/camply/crontab-ui/db
openssl rand -base64 32 > /home/camply/crontab-ui/.crontab-ui-auth

# create crontab-ui startup shell script
cat <<EOF >/home/camply/crontab-ui/start.sh
#!/bin/bash

HOST=0.0.0.0 \
PORT=5000 \
CRON_DB_PATH=/home/camply/crontab-ui/db \
ENABLE_AUTO_SAVE=true BASIC_AUTH_USER=camply \
BASIC_AUTH_PWD=$(cat /home/camply/crontab-ui/.crontab-ui-auth) \
crontab-ui
EOF

chown camply:camply -R /home/camply/crontab-ui
chmod +x /home/camply/crontab-ui/start.sh

su - root

apt install nodejs npm git -y
npm install crontab-ui

# create crontab-ui service file
cat <<EOF >/etc/systemd/system/crontab-ui.service
[Unit]
Description=Crontab UI
After=network.target

[Service]
Type=simple
User=camply
WorkingDirectory=/home/camply/crontab-ui
ExecStart=/home/camply/crontab-ui/start.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable crontab-ui.service
systemctl start crontab-ui.service
