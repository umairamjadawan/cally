#!/bin/bash

echo "🌊 Cally Quick Deploy - Copy and paste these commands into your server"
echo "======================================================================"

echo ""
echo "🔥 STEP 1: Connect to your server and run as ROOT:"
echo "ssh root@157.230.142.228"
echo "Password: 0f65fbf94679333dff40877bef"
echo ""

echo "📋 STEP 2: Copy and paste this block (Part 1 - System Setup):"
cat << 'EOF'

# System setup
apt update && apt upgrade -y
apt install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev nodejs npm nginx ufw

# Create cally user
adduser cally --disabled-password --gecos ""
usermod -aG sudo cally
echo "cally ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "✅ System setup complete. Now switching to cally user..."
su - cally

EOF

echo ""
echo "📋 STEP 3: Copy and paste this block (Part 2 - Ruby & Ollama):"
cat << 'EOF'

# Install RVM and Ruby
curl -sSL https://get.rvm.io | bash
source ~/.rvm/scripts/rvm
rvm install ruby-3.4.1
rvm use ruby-3.4.1@cally --create --default

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama and pull model
nohup ollama serve > ~/ollama.log 2>&1 &
sleep 15
ollama pull phi3:mini

echo "✅ Ruby and Ollama ready!"

EOF

echo ""
echo "📋 STEP 4: Copy and paste this block (Part 3 - Cally App):"
cat << 'EOF'

# Clone and setup Cally
git clone https://github.com/umairamjadawan/cally.git
cd cally

# Install gems and setup database
bundle install
RAILS_ENV=production rails db:create db:migrate db:seed
RAILS_ENV=production rails assets:precompile

# Generate and save production secret
export SECRET_KEY_BASE=$(rails secret)
echo "export SECRET_KEY_BASE=$SECRET_KEY_BASE" >> ~/.bashrc

echo "✅ Cally app setup complete!"
echo "🔑 Secret key generated and saved"

# Test the app
echo "🧪 Testing Cally..."
RAILS_ENV=production rails server -b 0.0.0.0 -p 3000 &
sleep 10

# Check if it's working
curl -s http://localhost:3000/health || echo "❌ App not responding yet"

# Stop test server
pkill -f "rails server"

echo "✅ Ready for production setup!"

EOF

echo ""
echo "📋 STEP 5: Exit back to ROOT and copy this block (Part 4 - Production Services):"
echo "Type: exit"
echo ""
cat << 'EOF'

# Get the secret key from cally user
SECRET_KEY_BASE=$(su - cally -c "cd cally && source ~/.rvm/scripts/rvm && rvm use ruby-3.4.1@cally && RAILS_ENV=production rails secret")

# Configure Nginx
tee /etc/nginx/sites-available/cally << NGINX_EOF
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
NGINX_EOF

ln -sf /etc/nginx/sites-available/cally /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Setup systemd services
tee /etc/systemd/system/ollama.service << OLLAMA_EOF
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
OLLAMA_EOF

tee /etc/systemd/system/cally.service << CALLY_EOF
[Unit]
Description=Cally Rails Application
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=cally
WorkingDirectory=/home/cally/cally
ExecStart=/home/cally/.rvm/wrappers/ruby-3.4.1@cally/rails server -b 0.0.0.0 -p 3000 -e production
Restart=always
RestartSec=10
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=$SECRET_KEY_BASE

[Install]
WantedBy=multi-user.target
CALLY_EOF

# Start everything
systemctl daemon-reload
systemctl enable ollama cally nginx
systemctl start ollama
sleep 15
systemctl start cally

# Configure firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================"
echo "🌐 Access Cally at: http://$(curl -s ifconfig.me)"
echo "📊 Check status: systemctl status cally ollama nginx"
echo "📝 View logs: journalctl -u cally -f"

EOF

echo ""
echo "🚀 FINAL CHECK:"
echo "Visit: http://157.230.142.228"
echo ""
echo "If you see Cally's interface, you're DONE! 🎉"
