# Capistrano Deployment Guide

## Prerequisites

### Local machine
```bash
bundle install
```

### Server setup (one-time, as root on 178.62.101.24)

**1. Create deploy user**
```bash
adduser deploy
usermod -aG sudo deploy
# Allow deploy to reload/restart puma service without password
echo "deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart fleet_core_engine, /bin/systemctl reload fleet_core_engine, /bin/systemctl start fleet_core_engine, /bin/systemctl stop fleet_core_engine" >> /etc/sudoers.d/deploy
```

**2. Add your SSH public key**
```bash
su - deploy
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "<your-public-key>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**3. Install rbenv + Ruby 3.3.0**
```bash
su - deploy
git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv
git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build
echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
source /etc/profile.d/rbenv.sh
rbenv install 3.3.0
rbenv global 3.3.0
gem install bundler
```

**4. Install Node.js + Yarn**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g yarn
```

**5. Install system packages**
```bash
sudo apt-get install -y git nginx redis-server sqlite3 libsqlite3-dev \
  libpq-dev build-essential libssl-dev libreadline-dev zlib1g-dev
```

**6. Create deploy directory**
```bash
sudo mkdir -p /var/www/fleet_core_engine
sudo chown deploy:deploy /var/www/fleet_core_engine
```

**7. Create shared files**
```bash
su - deploy
mkdir -p /var/www/fleet_core_engine/shared/config
mkdir -p /var/www/fleet_core_engine/shared/log
mkdir -p /var/www/fleet_core_engine/shared/tmp/{pids,cache,sockets}
mkdir -p /var/www/fleet_core_engine/shared/storage
mkdir -p /var/www/fleet_core_engine/shared/public/uploads

# Copy master.key from local to server
scp config/master.key deploy@178.62.101.24:/var/www/fleet_core_engine/shared/config/master.key
scp config/credentials.yml.enc deploy@178.62.101.24:/var/www/fleet_core_engine/shared/config/credentials.yml.enc

# Create .env on server
touch /var/www/fleet_core_engine/shared/.env
# Edit it with your production env vars: DATABASE_URL, REDIS_URL, etc.
```

**8. Nginx reverse proxy (port 3000 → 80)**

`/etc/nginx/sites-available/fleet_core_engine`:
```nginx
upstream fleet_puma {
  server 127.0.0.1:3000;
}

server {
  listen 80;
  server_name 178.62.101.24 fleet.matean.online;

  root /var/www/fleet_core_engine/current/public;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  location / {
    try_files $uri @puma;
  }

  location @puma {
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header  Host $http_host;
    proxy_set_header  X-Forwarded-Proto $scheme;
    proxy_redirect    off;
    proxy_pass        http://fleet_puma;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/fleet_core_engine /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**9. Puma systemd service**

`/etc/systemd/system/fleet_core_engine.service`:
```ini
[Unit]
Description=Fleet Core Engine Puma Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/fleet_core_engine/current
ExecStart=/usr/local/rbenv/bin/rbenv exec bundle exec puma -C config/puma.rb
ExecReload=/bin/kill -SIGUSR2 $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5
Environment=RAILS_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable fleet_core_engine
sudo systemctl start fleet_core_engine
```

---

## First deploy

```bash
# Check connectivity and directory structure
bundle exec cap production deploy:check

# Full deploy
bundle exec cap production deploy
```

## Subsequent deploys

```bash
bundle exec cap production deploy
```

## Useful tasks

```bash
# Deploy a specific branch
BRANCH=feature/my-branch bundle exec cap production deploy

# Run migrations only
bundle exec cap production deploy:migrate

# Rollback
bundle exec cap production deploy:rollback

# Restart Puma
bundle exec cap production puma:restart

# Tail logs
bundle exec cap production deploy:log_revision
ssh deploy@178.62.101.24 tail -f /var/www/fleet_core_engine/current/log/production.log
```
