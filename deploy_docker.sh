#!/bin/bash

# 🐳 Cally Docker Deployment Script for DigitalOcean
# This script deploys Cally using Docker containers for easier management

set -e

SERVER_IP="${1:-157.230.142.228}"
SERVER_PASSWORD="${2:-0f65fbf94679333dff40877bef}"

if [ -z "$SERVER_IP" ] || [ -z "$SERVER_PASSWORD" ]; then
    echo "❌ Usage: $0 <server_ip> <server_password>"
    echo "Example: $0 157.230.142.228 mypassword"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info "🐳 Starting Cally Docker deployment to $SERVER_IP"

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    print_error "sshpass not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    else
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

# Create deployment package
print_info "📦 Creating deployment package..."
tar --exclude='storage/*.sqlite3' \
    --exclude='log/*.log' \
    --exclude='tmp/**' \
    --exclude='.git' \
    --exclude='node_modules' \
    -czf cally-docker.tar.gz .

print_status "Package created: cally-docker.tar.gz"

# Upload to server
print_info "📤 Uploading to server..."
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no cally-docker.tar.gz root@$SERVER_IP:/tmp/

# Create deployment script for server
cat > /tmp/docker_deploy_server.sh << 'EOF'
#!/bin/bash
set -e

echo "🐳 Installing Docker and Docker Compose..."

# Update system
apt-get update

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker root
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Start Docker service
systemctl enable docker
systemctl start docker

echo "✅ Docker installation complete"

# Extract Cally
echo "📦 Extracting Cally application..."
cd /opt
rm -rf cally-docker
mkdir -p cally-docker
cd cally-docker
tar -xzf /tmp/cally-docker.tar.gz

echo "🔧 Setting up environment..."

# Generate secret key
export SECRET_KEY_BASE=$(openssl rand -hex 64)

# Update Ollama URL in the application
sed -i "s|OLLAMA_URL = 'http://localhost:11434'|OLLAMA_URL = ENV.fetch('OLLAMA_URL', 'http://ollama:11434')|g" app/services/ollama_service.rb

echo "🐳 Starting Cally with Docker..."

# Stop any existing containers
docker-compose -f docker-compose.production.yml down || true

# Build and start services
docker-compose -f docker-compose.production.yml up --build -d

echo "⏳ Waiting for services to start..."
sleep 30

# Pull the AI model
echo "🤖 Setting up AI model..."
docker exec cally-ollama ollama pull qwen2.5:0.5b

# Test the model
echo "🧪 Testing AI model..."
docker exec cally-ollama ollama run qwen2.5:0.5b "Hello, introduce yourself briefly" || echo "Model test failed, but continuing..."

# Run database migrations
echo "🗄️  Setting up database..."
docker exec cally-app bundle exec rails db:create db:migrate db:seed

echo "🔥 Testing Cally..."
sleep 10

# Test the application
if curl -f http://localhost:80/health; then
    echo "✅ Cally is running successfully!"
    echo "🌐 Access your app at: http://$(curl -s ifconfig.me)"
    echo "🤖 Chat interface: http://$(curl -s ifconfig.me)/"
else
    echo "❌ Health check failed"
    echo "📋 Docker status:"
    docker-compose -f docker-compose.production.yml ps
    echo "📋 Logs:"
    docker-compose -f docker-compose.production.yml logs --tail=20
fi

# Set up auto-start
echo "🔄 Setting up auto-start..."
cat > /etc/systemd/system/cally-docker.service << 'EOL'
[Unit]
Description=Cally Docker Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/cally-docker
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL

systemctl enable cally-docker.service
systemctl start cally-docker.service

echo "🎉 Cally Docker deployment complete!"
echo "📝 Management commands:"
echo "   View logs: docker-compose -f /opt/cally-docker/docker-compose.production.yml logs -f"
echo "   Restart: systemctl restart cally-docker"
echo "   Stop: systemctl stop cally-docker"
echo "   Update: cd /opt/cally-docker && docker-compose -f docker-compose.production.yml pull && docker-compose -f docker-compose.production.yml up --build -d"
EOF

# Upload server script
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no /tmp/docker_deploy_server.sh root@$SERVER_IP:/tmp/
rm /tmp/docker_deploy_server.sh

# Execute deployment on server
print_info "🚀 Running deployment on server..."
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER_IP 'chmod +x /tmp/docker_deploy_server.sh && /tmp/docker_deploy_server.sh'

# Test the deployment
print_info "🧪 Testing deployment..."
sleep 30

if curl -f http://$SERVER_IP/health; then
    print_status "🎉 Cally Docker deployment successful!"
    echo "🌐 Your Cally AI is running at: http://$SERVER_IP"
    echo "🤖 Kids can now chat with Cally!"
else
    print_error "❌ Deployment verification failed"
    print_info "📋 Checking server status..."
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER_IP 'cd /opt/cally-docker && docker-compose -f docker-compose.production.yml ps && docker-compose -f docker-compose.production.yml logs --tail=10'
fi

# Cleanup
rm -f cally-docker.tar.gz

print_info "🧹 Deployment package cleaned up"
print_status "✨ Docker deployment complete!"
