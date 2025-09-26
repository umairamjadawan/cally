#!/bin/bash

echo "🌊 Cally - DigitalOcean Deployment Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please don't run this script as root. Run as a regular user with sudo access."
    exit 1
fi

print_info "This script will deploy Cally on your DigitalOcean droplet"
print_warning "Make sure you've already created a droplet with Ubuntu 22.04"
echo ""

# Update system
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_status "System updated"

# Install essential packages
print_info "Installing essential packages..."
sudo apt install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev nodejs npm nginx ufw
print_status "Essential packages installed"

# Install RVM and Ruby
print_info "Installing RVM and Ruby 3.4.1..."
curl -sSL https://get.rvm.io | bash
source ~/.rvm/scripts/rvm
rvm install ruby-3.4.1
rvm use ruby-3.4.1@cally --create --default
print_status "Ruby environment ready"

# Install Ollama
print_info "Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
print_status "Ollama installed"

# Start Ollama and pull model
print_info "Starting Ollama and pulling phi3:mini model..."
nohup ollama serve > ~/ollama.log 2>&1 &
sleep 10
ollama pull phi3:mini
print_status "Ollama configured with phi3:mini"

# Clone and setup Cally
print_info "Cloning and setting up Cally..."
if [ ! -d "cally" ]; then
    git clone https://github.com/umairamjadawan/cally.git
fi
cd cally

# Setup Ruby environment for the project
source ~/.rvm/scripts/rvm
rvm use ruby-3.4.1@cally

# Install gems and setup database
bundle install
RAILS_ENV=production rails db:create db:migrate db:seed
RAILS_ENV=production rails assets:precompile

# Generate production secret
export SECRET_KEY_BASE=$(rails secret)
echo "export SECRET_KEY_BASE=$SECRET_KEY_BASE" >> ~/.bashrc
print_status "Cally application setup complete"

# Configure Nginx
print_info "Configuring Nginx reverse proxy..."
sudo tee /etc/nginx/sites-available/cally << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/cally /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
print_status "Nginx configured"

# Setup systemd services
print_info "Creating systemd services..."

# Ollama service
sudo tee /etc/systemd/system/ollama.service << EOF
[Unit]
Description=Ollama Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment=HOME=/home/$USER

[Install]
WantedBy=multi-user.target
EOF

# Cally service
sudo tee /etc/systemd/system/cally.service << EOF
[Unit]
Description=Cally Rails Application
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/cally
ExecStart=/home/$USER/.rvm/wrappers/ruby-3.4.1@cally/rails server -b 0.0.0.0 -p 3000 -e production
Restart=always
RestartSec=10
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=$SECRET_KEY_BASE

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable ollama cally nginx
sudo systemctl start ollama
sleep 15  # Wait for Ollama to fully start
sudo systemctl start cally

print_status "Services configured and started"

# Configure firewall
print_info "Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
print_status "Firewall configured"

# Final status check
print_info "Checking service status..."
sleep 10

if sudo systemctl is-active --quiet ollama; then
    print_status "Ollama service is running"
else
    print_error "Ollama service failed to start"
fi

if sudo systemctl is-active --quiet cally; then
    print_status "Cally service is running"
else
    print_error "Cally service failed to start"
fi

if sudo systemctl is-active --quiet nginx; then
    print_status "Nginx service is running"
else
    print_error "Nginx service failed to start"
fi

echo ""
echo "🎉 Deployment Complete!"
echo "================================="
print_status "Cally is now running on your DigitalOcean droplet"
echo ""
echo "🌐 Access your app at:"
echo "   http://$(curl -s ifconfig.me)"
echo ""
echo "📊 Service management commands:"
echo "   sudo systemctl status cally"
echo "   sudo systemctl restart cally"
echo "   sudo systemctl logs -f cally"
echo ""
echo "🔍 Check logs:"
echo "   sudo journalctl -u cally -f"
echo "   sudo journalctl -u ollama -f"
echo ""
print_warning "Remember to:"
print_warning "1. Point your domain to this droplet's IP if you have one"
print_warning "2. Setup SSL certificate with 'sudo certbot --nginx -d yourdomain.com'"
print_warning "3. Update DNS A record to point to: $(curl -s ifconfig.me)"
