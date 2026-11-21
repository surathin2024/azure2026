#!/usr/bin/env bash
set -euo pipefail
 
export DEBIAN_FRONTEND=noninteractive
 
apt-get update
apt-get install -y python3-venv nginx curl
 
cd /opt/studentapp
 
if [ ! -x venv/bin/python ]; then
    python3 -m venv venv
fi
 
venv/bin/python -m pip install -r requirements.txt
venv/bin/python -c "from app import app"
 
cat > /etc/systemd/system/studentapp.service <<'SERVICE'
[Unit]
Description=Student Flask Application
After=network.target
 
[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/studentapp
Environment=PYTHONDONTWRITEBYTECODE=1
ExecStart=/opt/studentapp/venv/bin/gunicorn --workers 1 --bind 127.0.0.1:8000 app:app
Restart=on-failure
RestartSec=5
 
[Install]
WantedBy=multi-user.target
SERVICE
 
cat > /etc/nginx/sites-available/studentapp <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
 
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        add_header Cache-Control "no-store" always;
    }
}
NGINX
 
rm -f /etc/nginx/sites-enabled/default
 
ln -sfn /etc/nginx/sites-available/studentapp \
    /etc/nginx/sites-enabled/studentapp
 
systemctl daemon-reload
systemctl enable studentapp
systemctl restart studentapp
 
nginx -t
systemctl enable nginx
systemctl restart nginx
 
for attempt in {1..30}; do
    if curl --fail --silent --max-time 5 \
http://127.0.0.1/ > /tmp/studentapp-response.html; then
        cat /tmp/studentapp-response.html
        echo
        echo "STUDENTAPP_DEPLOY_OK"
        exit 0
    fi
 
    sleep 2
done
 
journalctl -u studentapp -n 30 --no-pager
exit 1
