apt update && apt upgrade -y

apt install nodejs npm git python3-dev python3-venv sudo -y
npm install -g yarn sass

apt install apache2 libapache2-mod-wsgi-py3 -y
sed -i "/^# . \/etc\/default\/locale/c\. \/etc\/default\/locale" /etc/apache2/envvars
cat <<EOF >/etc/apache2/sites-available/wger.conf
<Directory /home/wger/src>
    <Files wsgi.py>
        Require all granted
    </Files>
</Directory>


<VirtualHost *:80>
    WSGIApplicationGroup %{GLOBAL}
    WSGIDaemonProcess wger python-path=/home/wger/src python-home=/home/wger/venv
    WSGIProcessGroup wger
    WSGIScriptAlias / /home/wger/src/wger/wsgi.py
    WSGIPassAuthorization On

    Alias /static/ /home/wger/static/
    <Directory /home/wger/static>
        Require all granted
    </Directory>

    Alias /media/ /home/wger/media/
    <Directory /home/wger/media>
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/wger-error.log
    CustomLog ${APACHE_LOG_DIR}/wger-access.log combined
</VirtualHost>
EOF

#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

a2dissite 000-default.conf
a2ensite wger
systemctl reload apache2.service

sudo adduser wger --disabled-password --gecos ""
sudo usermod -aG sudo wger

sudo su - wger -c "mkdir /home/wger/db"
touch /home/wger/db/database.sqlite
chown :www-data -R /home/wger/db
chmod g+w /home/wger/db /home/wger/db/database.sqlite

sudo su - wger -c "mkdir /home/wger/static"
sudo su - wger -c "mkdir /home/wger/media"
chmod o+w /home/wger/media

sudo su - wger
git clone https://github.com/wger-project/wger.git /home/wger/src
python -m venv /home/wger/venv
source /home/wger/venv/bin/activate
cd /home/wger/src/
pip install -r requirements_prod.txt
pip install -e .

wger create-settings --database-path /home/wger/db/database.sqlite
sed -i "/^SITE_URL/c\SITE_URL = 'http:\/\/192.168.1.121:8000'" settings.py
sed -i "/^MEDIA_ROOT/c\MEDIA_ROOT = '\/home\/wger\/media'" settings.py
echo "STATIC_ROOT = '/home/wger/static'" >> settings.py

wger bootstrap
python manage.py collectstatic
python manage.py runserver 192.168.1.121:8000