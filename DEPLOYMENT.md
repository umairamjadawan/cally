# 🌊 DigitalOcean Deployment Guide for Cally

## 🎯 Quick Start

**Option 1: Automated Script** (Recommended)
```bash
# Upload and run the deployment script
scp deploy_digitalocean.sh root@your-droplet-ip:~/
ssh root@your-droplet-ip
chmod +x deploy_digitalocean.sh
./deploy_digitalocean.sh
```

**Option 2: Manual Step-by-Step** (See detailed guide below)

## 💰 Pricing Overview

| Plan | RAM | CPU | Storage | Monthly Cost | Recommended For |
|------|-----|-----|---------|--------------|-----------------|
| Basic | 1GB | 1 vCPU | 25GB SSD | $6/month | Testing only |
| **Recommended** | 2GB | 1 vCPU | 50GB SSD | $12/month | **Family use** |
| Performance | 2GB | 2 vCPUs | 60GB SSD | $18/month | Multiple users |

## 🚀 Detailed Manual Deployment

### 1. Create DigitalOcean Droplet

1. **Sign up/Login** to [DigitalOcean](https://digitalocean.com)
2. **Create Droplet**:
   - Click "Create" → "Droplets"
   - **Image**: Ubuntu 22.04 (LTS) x64
   - **Plan**: Basic $12/month (2GB RAM, 1 vCPU)
   - **Datacenter**: Choose closest region
   - **Authentication**: 
     - Upload SSH key (recommended)
     - Or use root password
   - **Hostname**: `cally-ai-server`
   - Click "Create Droplet"

3. **Wait** for droplet to be ready (~2 minutes)
4. **Note the IP address** shown in your DigitalOcean dashboard

### 2. Initial Server Configuration

```bash
# Connect to your server
ssh root@YOUR_DROPLET_IP

# Update the system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl git build-essential libssl-dev libreadline-dev \
               zlib1g-dev libsqlite3-dev nodejs npm nginx ufw fail2ban

# Create application user
adduser cally --disabled-password --gecos ""
usermod -aG sudo cally
echo "cally ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to cally user
su - cally
cd ~
```

### 3. Install Ruby Environment

```bash
# Install RVM (Ruby Version Manager)
curl -sSL https://get.rvm.io | bash
source ~/.rvm/scripts/rvm

# Install Ruby 3.4.1
rvm install ruby-3.4.1
rvm use ruby-3.4.1@cally --create --default

# Verify installation
ruby --version   # Should show ruby 3.4.1
gem --version    # Should show gem version
rvm gemset name  # Should show 'cally'

# Install bundler
gem install bundler
```

### 4. Install and Configure Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Create Ollama service (as root)
exit  # Exit back to root user

# Create systemd service for Ollama
tee /etc/systemd/system/ollama.service << EOF
[Unit]
Description=Ollama Server
After=network.target

[Service]
Type=simple
User=cally
WorkingDirectory=/home/cally
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment=HOME=/home/cally

[Install]
WantedBy=multi-user.target
EOF

# Start Ollama service
systemctl daemon-reload
systemctl enable ollama
systemctl start ollama

# Wait and check status
sleep 10
systemctl status ollama

# Switch back to cally user to pull model
su - cally
ollama pull phi3:mini

# Verify model is available
ollama list
```

### 5. Deploy Cally Application

```bash
# As cally user, clone the repository
cd /home/cally
git clone https://github.com/umairamjadawan/cally.git
cd cally

# Setup Ruby environment
source ~/.rvm/scripts/rvm
rvm use ruby-3.4.1@cally

# Install dependencies
bundle install

# Setup production database
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed

# Generate and set production secret
SECRET_KEY_BASE=$(RAILS_ENV=production rails secret)
echo "export SECRET_KEY_BASE=$SECRET_KEY_BASE" >> ~/.bashrc
export SECRET_KEY_BASE=$SECRET_KEY_BASE

# Precompile assets
RAILS_ENV=production rails assets:precompile

# Test the application
RAILS_ENV=production rails server -b 127.0.0.1 -p 3000 &
sleep 10
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}

# Stop test server
pkill -f "rails server"
```

### 6. Configure Nginx Reverse Proxy

```bash
# As root user
exit  # Exit back to root

# Remove default Nginx site
rm -f /etc/nginx/sites-enabled/default

# Create Cally Nginx configuration
tee /etc/nginx/sites-available/cally << 'EOF'
upstream cally_app {
    server 127.0.0.1:3000 fail_timeout=0;
}

server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    location / {
        proxy_pass http://cally_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 8k;
        proxy_buffers 8 8k;
    }
    
    # Serve static assets directly
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri @cally_app;
    }
    
    location @cally_app {
        proxy_pass http://cally_app;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/cally /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl status nginx
```

### 7. Create Production Service

```bash
# Create Cally systemd service
tee /etc/systemd/system/cally.service << EOF
[Unit]
Description=Cally Rails Application
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=cally
Group=cally
WorkingDirectory=/home/cally/cally
ExecStart=/home/cally/.rvm/wrappers/ruby-3.4.1@cally/rails server -b 127.0.0.1 -p 3000 -e production
Restart=always
RestartSec=10
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=SECRET_PLACEHOLDER

[Install]
WantedBy=multi-user.target
EOF

# Update the service file with actual secret
SECRET_KEY_BASE=$(su - cally -c "cd cally && RAILS_ENV=production rails secret")
sed -i "s/SECRET_PLACEHOLDER/$SECRET_KEY_BASE/" /etc/systemd/system/cally.service

# Enable and start services
systemctl daemon-reload
systemctl enable cally
systemctl start cally

# Check status
sleep 15
systemctl status cally
systemctl status ollama
```

### 8. Configure Firewall

```bash
# Setup UFW firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Check firewall status
ufw status

# Optional: Install fail2ban for additional security
systemctl enable fail2ban
systemctl start fail2ban
```

### 9. Verify Deployment

```bash
# Check all services
systemctl status ollama cally nginx

# Test the application
DROPLET_IP=$(curl -s ifconfig.me)
curl -I http://$DROPLET_IP
curl http://$DROPLET_IP/health

echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo "🌐 Your Cally app is available at: http://$DROPLET_IP"
echo "📊 Monitor with: sudo journalctl -u cally -f"
echo "🔄 Restart with: sudo systemctl restart cally"
```

## 🔒 Optional: SSL Certificate Setup

```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Get SSL certificate (replace yourdomain.com with your actual domain)
certbot --nginx -d yourdomain.com

# Setup auto-renewal
systemctl enable certbot.timer
systemctl start certbot.timer

# Test renewal
certbot renew --dry-run
```

## 📊 Monitoring and Maintenance

### Service Management
```bash
# Check status
sudo systemctl status cally ollama nginx

# View logs
sudo journalctl -u cally -f          # Cally logs
sudo journalctl -u ollama -f         # Ollama logs
sudo journalctl -u nginx -f          # Nginx logs

# Restart services
sudo systemctl restart cally
sudo systemctl restart ollama
sudo systemctl restart nginx
```

### Application Updates
```bash
# SSH into your server
ssh cally@your-droplet-ip
cd ~/cally

# Pull latest changes
git pull origin main

# Update dependencies
source ~/.rvm/scripts/rvm
rvm use ruby-3.4.1@cally
bundle install

# Run any new migrations
RAILS_ENV=production rails db:migrate

# Precompile new assets
RAILS_ENV=production rails assets:precompile

# Restart application
sudo systemctl restart cally
```

### Database Backup
```bash
# Create backup script
tee ~/backup_cally.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/cally/backups"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)

# Backup SQLite database
cp /home/cally/cally/db/production.sqlite3 $BACKUP_DIR/cally_db_$DATE.sqlite3

# Keep only last 7 backups
ls -t $BACKUP_DIR/cally_db_*.sqlite3 | tail -n +8 | xargs rm -f

echo "Backup completed: cally_db_$DATE.sqlite3"
EOF

chmod +x ~/backup_cally.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /home/cally/backup_cally.sh") | crontab -
```

## 🔧 Troubleshooting

### Common Issues

**1. Service Won't Start**
```bash
# Check detailed logs
sudo journalctl -u cally -n 50
sudo journalctl -u ollama -n 50

# Check if ports are available
sudo lsof -i :3000
sudo lsof -i :11434
```

**2. Ollama Model Issues**
```bash
# Re-pull the model
sudo -u cally ollama pull phi3:mini
sudo -u cally ollama list
```

**3. Database Issues**
```bash
# Reset database (⚠️ This will delete all data)
sudo -u cally bash -c "cd /home/cally/cally && RAILS_ENV=production rails db:drop db:create db:migrate db:seed"
```

**4. Permission Issues**
```bash
# Fix file permissions
sudo chown -R cally:cally /home/cally/cally
sudo chmod -R 755 /home/cally/cally
```

### Performance Monitoring

```bash
# Check resource usage
htop
df -h                    # Disk usage
free -h                  # Memory usage
sudo iotop               # I/O usage

# Check application performance
curl -w "Time: %{time_total}s\n" http://localhost:3000/health
```

## 🌐 Domain Setup (Optional)

### Configure Custom Domain

1. **Buy a domain** (e.g., from Namecheap, GoDaddy)
2. **Update DNS**:
   - Create A record: `@` → `YOUR_DROPLET_IP`
   - Create A record: `www` → `YOUR_DROPLET_IP`
3. **Update Nginx**:
   ```bash
   sudo nano /etc/nginx/sites-available/cally
   # Change: server_name _;
   # To: server_name yourdomain.com www.yourdomain.com;
   sudo systemctl restart nginx
   ```
4. **Get SSL Certificate**:
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

## 📱 Mobile Access

Once deployed, Cally works perfectly on mobile devices:
- **iPhone/iPad**: Open Safari, go to your domain
- **Android**: Open Chrome, go to your domain
- **Install as App**: Use browser's "Add to Home Screen" feature

## 🔄 Continuous Deployment (Optional)

### Setup GitHub Actions

Create `.github/workflows/deploy.yml` in your repository:

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.SERVER_HOST }}
        username: cally
        key: ${{ secrets.SERVER_SSH_KEY }}
        script: |
          cd ~/cally
          git pull origin main
          source ~/.rvm/scripts/rvm
          rvm use ruby-3.4.1@cally
          bundle install
          RAILS_ENV=production rails db:migrate
          RAILS_ENV=production rails assets:precompile
          sudo systemctl restart cally
```

Add these secrets to your GitHub repository:
- `SERVER_HOST`: Your droplet IP
- `SERVER_SSH_KEY`: Your private SSH key

## 💡 Pro Tips

### Cost Optimization
- **Resize droplet** if you need more power later
- **Enable monitoring** to track resource usage
- **Setup alerts** for high CPU/memory usage

### Security Best Practices
- **Regular updates**: `apt update && apt upgrade`
- **SSH key only**: Disable password authentication
- **Firewall**: Only open necessary ports
- **Fail2ban**: Protect against brute force attacks

### Performance Optimization
- **Monitor logs**: `sudo journalctl -u cally -f`
- **Database maintenance**: Regular SQLite VACUUM
- **Asset optimization**: Use CDN for static files (if needed)

## 🆘 Support Commands

```bash
# Quick health check
curl http://your-domain-or-ip/health

# Restart everything
sudo systemctl restart ollama cally nginx

# Check resource usage
htop
df -h

# View recent logs
sudo journalctl -u cally --since "1 hour ago"
```

---

**🎉 Once deployed, your family can access Cally from anywhere in the world!**

**Access URLs**:
- `http://your-droplet-ip` (immediate access)
- `http://yourdomain.com` (if you setup a domain)

**Total setup time**: ~15-30 minutes  
**Monthly cost**: $12-18  
**Supports**: Unlimited family members, worldwide access
