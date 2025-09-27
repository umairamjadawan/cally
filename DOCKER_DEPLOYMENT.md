# 🐳 Cally Docker Deployment Guide

This guide covers deploying Cally using Docker containers for easier management, isolation, and consistency across environments.

## 🎯 Why Docker?

- **✅ Consistent Environment**: Same environment everywhere (dev, staging, production)
- **✅ Easy Dependency Management**: No more RVM, Ruby version, or gem conflicts
- **✅ Resource Isolation**: Ollama AI and Rails run in separate containers
- **✅ Simple Updates**: Pull new images and restart containers
- **✅ Auto-scaling**: Easy to scale with load balancers
- **✅ Health Monitoring**: Built-in health checks for all services

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │────│   Cally Rails   │────│     Ollama      │
│   (Port 80)     │    │   (Port 3000)   │    │  (Port 11434)   │
│  Load Balancer  │    │  Web Application│    │   AI Service    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Requirements

### 💻 Local Machine:
- Docker & Docker Compose
- `sshpass` (for automated deployment)

### 🌐 DigitalOcean Droplet:
- **Minimum**: 2GB RAM, 1 vCPU ($12/month)
- **Recommended**: 4GB RAM, 2 vCPU ($24/month) for better AI performance
- Ubuntu 22.04 LTS

## 🚀 Quick Deployment

### Option 1: One-Command Deployment
```bash
./deploy_docker.sh 157.230.142.228 your_server_password
```

### Option 2: Manual Steps

1. **Upload to server:**
```bash
tar --exclude='.git' --exclude='storage/*.sqlite3' -czf cally-docker.tar.gz .
scp cally-docker.tar.gz root@YOUR_IP:/tmp/
```

2. **Deploy on server:**
```bash
ssh root@YOUR_IP
cd /opt && mkdir cally-docker && cd cally-docker
tar -xzf /tmp/cally-docker.tar.gz
docker-compose -f docker-compose.production.yml up --build -d
```

## 🔧 Docker Services

### 🤖 Ollama (AI Service)
- **Image**: `ollama/ollama:latest`
- **Memory**: 1.5GB limit, 512MB reserved
- **Models**: qwen2.5:0.5b (optimized for 2GB servers)
- **Port**: 11434 (internal only)
- **Health Check**: API version endpoint

### 🚂 Cally Rails App
- **Build**: Custom Dockerfile with Ruby 3.4.1
- **Memory**: 512MB limit, 256MB reserved  
- **Port**: 3000 (internal only)
- **Environment**: Production with optimizations
- **Health Check**: `/health` endpoint

### 🌐 Nginx (Load Balancer)
- **Image**: `nginx:alpine`
- **Port**: 80 (public)
- **Features**: Rate limiting, compression, static asset caching
- **Proxy**: Routes traffic to Cally app

## 🛠️ Management Commands

### View Real-time Logs:
```bash
cd /opt/cally-docker
docker-compose -f docker-compose.production.yml logs -f
```

### Restart Services:
```bash
systemctl restart cally-docker
# OR
docker-compose -f docker-compose.production.yml restart
```

### Update Cally:
```bash
cd /opt/cally-docker
git pull origin main
docker-compose -f docker-compose.production.yml up --build -d
```

### Check Status:
```bash
docker-compose -f docker-compose.production.yml ps
systemctl status cally-docker
```

### Access Containers:
```bash
# Rails console
docker exec -it cally-app rails console

# Ollama shell
docker exec -it cally-ollama bash

# Test AI directly
docker exec cally-ollama ollama run qwen2.5:0.5b "Hello!"
```

## 🔍 Troubleshooting

### Container Won't Start:
```bash
docker-compose -f docker-compose.production.yml logs service_name
```

### AI Model Issues:
```bash
# Check available models
docker exec cally-ollama ollama list

# Pull model manually
docker exec cally-ollama ollama pull qwen2.5:0.5b

# Test model
docker exec cally-ollama ollama run qwen2.5:0.5b "test"
```

### Memory Issues:
```bash
# Check container resource usage
docker stats

# Check server memory
free -h
```

### Reset Everything:
```bash
cd /opt/cally-docker
docker-compose -f docker-compose.production.yml down -v
docker system prune -a
docker-compose -f docker-compose.production.yml up --build -d
```

## 📊 Resource Usage

| Service | Memory | CPU | Storage |
|---------|--------|-----|---------|
| Ollama  | ~1GB   | 50% | 2GB (models) |
| Cally   | ~200MB | 20% | 100MB |
| Nginx   | ~10MB  | 5%  | 50MB |
| **Total** | **~1.2GB** | **75%** | **~2.2GB** |

## 🔒 Security Features

- **Non-root containers**: All services run as non-root users
- **Network isolation**: Services communicate via Docker network
- **Rate limiting**: Nginx prevents API abuse
- **Health checks**: Automatic restart of failed services
- **Resource limits**: Prevents containers from consuming all memory

## 🌟 Benefits over Manual Deployment

| Manual Deployment | Docker Deployment |
|-------------------|-------------------|
| Complex Ruby/RVM setup | ✅ Pre-built Ruby environment |
| Manual service management | ✅ Auto-restart with systemd |
| Dependency conflicts | ✅ Isolated containers |
| Manual backup/restore | ✅ Volume management |
| Difficult scaling | ✅ Easy horizontal scaling |
| Hard to update | ✅ Simple image updates |

## 💰 Cost Optimization

**Recommended DigitalOcean setup:**
- **$12/month** (2GB RAM) - Perfect for light usage
- **$24/month** (4GB RAM) - Better for heavier usage
- Add **monitoring** ($6/month) for production alerts

## 🔄 Auto-Updates

Set up automatic updates with cron:
```bash
# Add to crontab: crontab -e
0 3 * * 0 cd /opt/cally-docker && git pull && docker-compose -f docker-compose.production.yml up --build -d
```

## 🎉 Success!

Once deployed, your Cally AI assistant will be:
- 🌐 **Accessible** at your server IP
- 🤖 **AI-powered** with kid-friendly responses  
- 🔄 **Auto-restarting** if services fail
- 📈 **Monitored** with health checks
- 🛡️ **Secure** with proper isolation

Perfect for kids to safely chat with their AI friend! 🚀
