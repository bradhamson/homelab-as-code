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

