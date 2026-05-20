#!/bin/bash

# 🚀 Carrier Dispatch App - AWS EC2 Automated Deployment Script
# This script automates the entire deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Start deployment
print_header "Carrier Dispatch App - EC2 Deployment"

# Step 1: Update system
print_info "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_step "System updated"

# Step 2: Install Docker
print_info "Step 2: Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    print_step "Docker installed"
else
    print_step "Docker already installed"
fi

# Step 3: Install Docker Compose
print_info "Step 3: Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_step "Docker Compose installed"
else
    print_step "Docker Compose already installed"
fi

# Step 4: Add user to docker group
print_info "Step 4: Configuring Docker permissions..."
sudo usermod -aG docker $USER
newgrp docker
print_step "Docker permissions configured"

# Step 5: Install Git
print_info "Step 5: Installing Git..."
sudo apt install -y git
print_step "Git installed"

# Step 6: Create app directory
print_info "Step 6: Creating application directory..."
sudo mkdir -p /opt/carrier-dispatch-app
sudo chown -R $USER:$USER /opt/carrier-dispatch-app
cd /opt/carrier-dispatch-app
print_step "Directory created: /opt/carrier-dispatch-app"

# Step 7: Clone repository
print_info "Step 7: Cloning repository..."
if [ ! -d ".git" ]; then
    git clone https://github.com/3jaysdispatching-dev/carrier-dispatch-app.git .
    print_step "Repository cloned"
else
    print_info "Repository already exists, pulling latest changes..."
    git pull origin main
    print_step "Repository updated"
fi

# Step 8: Copy environment template
print_info "Step 8: Setting up environment file..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_step ".env file created from template"
else
    print_warning ".env already exists, skipping"
fi

# Step 9: Create SSL directory
print_info "Step 9: Creating SSL directory..."
mkdir -p /opt/carrier-dispatch-app/ssl
print_step "SSL directory ready"

# Step 10: Create data directories
print_info "Step 10: Creating data directories..."
mkdir -p /opt/carrier-dispatch-app/data/postgres
mkdir -p /opt/carrier-dispatch-app/data/redis
print_step "Data directories created"

# Step 11: Edit environment variables
print_info "Step 11: Environment Configuration"
echo ""
echo -e "${YELLOW}Please edit .env with your production values:${NC}"
echo ""
echo "Required variables:"
echo "  - DATABASE_URL (PostgreSQL connection string)"
echo "  - JWT_SECRET (strong 32+ character secret)"
echo "  - STRIPE_SECRET_KEY"
echo "  - GOOGLE_MAPS_API_KEY"
echo "  - TWILIO credentials (if using notifications)"
echo "  - VITE_API_URL (set to your domain)"
echo ""
read -p "Press Enter to open .env editor, or Ctrl+C to skip..."
nano .env
print_step ".env configured"

# Step 12: Start Docker services
print_info "Step 12: Starting Docker services..."
docker-compose -f docker-compose.prod.yml up -d
sleep 10
print_step "Services started"

# Step 13: Verify services
print_info "Step 13: Verifying services..."
docker-compose -f docker-compose.prod.yml ps
print_step "Services verification complete"

# Step 14: Health check
print_info "Step 14: Running health checks..."
sleep 5
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    print_step "Backend health check passed"
else
    print_warning "Backend health check failed, containers may still be starting"
fi

# Step 15: Setup SSL Certificate
print_info "Step 15: SSL Certificate Setup"
read -p "Enter your domain (e.g., dispatch.yourdomain.com) or press Enter to skip: " DOMAIN

if [ ! -z "$DOMAIN" ]; then
    read -p "Enter your email address for Let's Encrypt: " EMAIL
    
    # Install Certbot
    sudo apt install -y certbot python3-certbot-nginx
    
    # Get certificate
    print_info "Requesting SSL certificate from Let's Encrypt..."
    sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --expand
    
    # Copy certificates
    print_info "Copying certificates..."
    sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/carrier-dispatch-app/ssl/
    sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/carrier-dispatch-app/ssl/
    sudo chown $USER:$USER /opt/carrier-dispatch-app/ssl/*
    
    # Setup auto-renewal
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer
    
    print_step "SSL certificate installed and auto-renewal configured"
    print_step "Certificate will auto-renew 30 days before expiration"
fi

# Step 16: Setup firewall rules
print_info "Step 16: Configuring firewall..."
sudo apt install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
print_step "Firewall configured"

# Step 17: Setup log rotation
print_info "Step 17: Setting up log rotation..."
cat > /tmp/docker-logrotate << 'EOF'
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  missingok
  delaycompress
  copytruncate
}
EOF
sudo mv /tmp/docker-logrotate /etc/logrotate.d/docker
print_step "Log rotation configured"

# Summary
print_header "🎉 Deployment Complete!"

echo ""
echo -e "${GREEN}Your Carrier Dispatch App is now running!${NC}"
echo ""
echo "📝 Next Steps:"
echo "  1. Add GitHub Secrets for CI/CD:"
echo "     - EC2_HOST: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "     - EC2_USER: ubuntu"
echo "     - EC2_SSH_KEY: (contents of your SSH key)"
if [ ! -z "$DOMAIN" ]; then
    echo "  2. Update your domain DNS A record to point to this server"
    echo ""
    echo "🌐 Access your app:"
    echo "     - Web: https://$DOMAIN"
    echo "     - API: https://$DOMAIN/api"
else
    echo "  2. Point your domain DNS to: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    echo ""
    echo "🌐 Access your app (via IP):"
    echo "     - Web: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    echo "     - API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000"
fi

echo ""
echo "📊 Check logs:"
echo "     docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🔄 Update deployment:"
echo "     git pull origin main"
echo "     docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "📧 Support: support@3jaysdispatching.com"
echo ""
