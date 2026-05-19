# Carrier Dispatch App - Deployment Guide

## 🚀 Production Deployment Options

### Option 1: AWS EC2 Deployment (Recommended)

#### Prerequisites
- AWS Account with EC2 access
- Domain name (Route53 optional)
- SSL certificate (ACM or Let's Encrypt)
- Docker Hub account for image registry

#### Step 1: Launch EC2 Instance

```bash
# Launch Ubuntu 22.04 LTS t3.medium instance
# Security Group: Allow ports 22, 80, 443
# Key Pair: Download and save securely
```

#### Step 2: Connect and Setup Server

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Git
sudo apt install -y git

# Create app directory
sudo mkdir -p /opt/carrier-dispatch-app
sudo chown -R $USER:$USER /opt/carrier-dispatch-app
```

#### Step 3: Clone Repository

```bash
cd /opt/carrier-dispatch-app
git clone https://github.com/3jaysdispatching-dev/carrier-dispatch-app.git .
cp .env.example .env
```

#### Step 4: Configure Environment Variables

```bash
# Edit .env with production values
nano .env

# Important variables to set:
# - DATABASE_URL (use RDS if available)
# - JWT_SECRET (strong 32+ char secret)
# - STRIPE_SECRET_KEY
# - GOOGLE_MAPS_API_KEY
# - Twilio credentials
# - Redis password
# - Domain name for CORS
```

#### Step 5: Deploy with Docker Compose

```bash
# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Verify services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f backend
```

#### Step 6: Setup SSL/TLS with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Copy to Nginx directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/carrier-dispatch-app/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/carrier-dispatch-app/ssl/

# Uncomment SSL section in frontend/nginx.conf
nano frontend/nginx.conf

# Restart frontend container
docker-compose -f docker-compose.prod.yml restart frontend

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

### Option 2: AWS ECS/Fargate Deployment

#### Step 1: Create ECR Repositories

```bash
# Create backend repository
aws ecr create-repository --repository-name carrier-dispatch-backend

# Create frontend repository
aws ecr create-repository --repository-name carrier-dispatch-frontend

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

#### Step 2: Build and Push Images

```bash
# Tag and push backend
docker build -t carrier-dispatch-backend ./backend
docker tag carrier-dispatch-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-backend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-backend:latest

# Tag and push frontend
docker build -t carrier-dispatch-frontend ./frontend
docker tag carrier-dispatch-frontend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-frontend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-frontend:latest
```

#### Step 3: Create RDS PostgreSQL Database

```bash
# In AWS Console:
# 1. Go to RDS > Create Database
# 2. Engine: PostgreSQL 15
# 3. Instance class: db.t3.micro (or higher for production)
# 4. Storage: 100GB with auto-scaling
# 5. VPC: Same as ECS cluster
# 6. Database name: dispatch_db
# 7. Master username: dispatch_user
# 8. Enable automated backups (7 days)
# 9. Enable Multi-AZ for production
# 10. Create database

# Get endpoint from AWS Console
# Update .env: DATABASE_URL=postgresql://dispatch_user:password@your-rds-endpoint:5432/dispatch_db
```

#### Step 4: Create ElastiCache Redis

```bash
# In AWS Console:
# 1. Go to ElastiCache > Redis > Create
# 2. Engine version: 7.x
# 3. Node type: cache.t3.micro (or higher)
# 4. Number of nodes: 1 (or 3 for cluster mode)
# 5. VPC: Same as ECS cluster
# 6. Enable automatic failover
# 7. Enable encryption in transit
# 8. Create cluster

# Get endpoint from AWS Console
# Update .env: REDIS_URL=redis://your-redis-endpoint:6379
```

#### Step 5: Create ECS Cluster

```bash
# In AWS Console:
# 1. Go to ECS > Create Cluster
# 2. Cluster name: carrier-dispatch-prod
# 3. Infrastructure: Fargate
# 4. Create

# Create Task Definition:
# 1. Task family: carrier-dispatch-backend
# 2. Container: carrier-dispatch-backend
# 3. Image: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-backend:latest
# 4. Port: 5000
# 5. Memory: 512 MB
# 6. CPU: 256
# 7. Environment variables: (from .env)
# 8. Log: /ecs/carrier-dispatch-backend

# Create Service:
# 1. Service name: carrier-dispatch-backend-service
# 2. Task definition: carrier-dispatch-backend
# 3. Service type: REPLICA
# 4. Desired count: 2 (for high availability)
# 5. Load balancer: Application Load Balancer
# 6. Create
```

#### Step 6: Configure Application Load Balancer

```bash
# In AWS Console:
# 1. Go to EC2 > Load Balancers
# 2. Create ALB
# 3. Name: carrier-dispatch-alb
# 4. Scheme: Internet-facing
# 5. IP address type: IPv4
# 6. VPC: Same as ECS
# 7. Subnets: Select 2+ availability zones
# 8. Security group: Allow 80, 443
# 9. Create

# Add listeners:
# 1. HTTP (80) → Forward to backend target group
# 2. HTTPS (443) → Forward to backend target group (add SSL cert)

# Create target groups:
# 1. Backend target group: Port 5000
# 2. Frontend target group: Port 80
```

---

### Option 3: AWS App Runner Deployment

#### Step 1: Configure App Runner

```bash
# In AWS Console:
# 1. Go to App Runner > Create service
# 2. Source: ECR
# 3. Container image URI: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carrier-dispatch-backend:latest
# 4. Deployment trigger: Automatic
# 5. Service name: carrier-dispatch-backend
# 6. Port: 5000
# 7. CPU: 1 vCPU
# 8. Memory: 2 GB
# 9. Environment variables: (from .env)
# 10. Create service

# Repeat for frontend:
# 1. Container image: frontend repository
# 2. Port: 80
# 3. Service name: carrier-dispatch-frontend
```

---

## 📊 Monitoring & Logging

### CloudWatch Setup

```bash
# View logs
aws logs tail /ecs/carrier-dispatch-backend --follow

# Create alarms
aws cloudwatch put-metric-alarm \
  --alarm-name carrier-dispatch-cpu \
  --alarm-description "Alert on high CPU usage" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### Health Checks

```bash
# Monitor endpoint health
curl -I https://your-domain.com/health

# Check database
psql -h your-rds-endpoint -U dispatch_user -d dispatch_db -c "SELECT NOW();"

# Check Redis
redis-cli -h your-redis-endpoint PING
```

---

## 🔄 Continuous Deployment

### GitHub Actions Integration

GitHub Actions pipeline (configured in `.github/workflows/deploy.yml`) will:

1. ✅ Run tests on every push
2. ✅ Build Docker images
3. ✅ Push to ECR/Docker Hub
4. ✅ Deploy to production (on main branch)
5. ✅ Send Slack notifications

### Required GitHub Secrets

```
DOCKER_USERNAME = docker-hub-username
DOCKER_PASSWORD = docker-hub-password
DEPLOY_HOST = ec2-public-ip
DEPLOY_USER = ubuntu
DEPLOY_SSH_KEY = (SSH private key)
SLACK_WEBHOOK = (Slack webhook URL)
```

---

## 📈 Scaling & Performance

### Auto-Scaling (ECS)

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/carrier-dispatch-prod/carrier-dispatch-backend-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name carrier-dispatch-scaling \
  --service-namespace ecs \
  --resource-id service/carrier-dispatch-prod/carrier-dispatch-backend-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

### Database Optimization

```sql
-- Create indexes for performance
CREATE INDEX idx_shipments_status_date ON shipments(status, created_at);
CREATE INDEX idx_drivers_location ON drivers USING GIST(current_location);
CREATE INDEX idx_shipments_customer_driver ON shipments(customer_id, driver_id);

-- Enable query logging for slow queries
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();
```

### Redis Caching

```typescript
// Example caching pattern
const getShipment = async (id: string) => {
  const cached = await redis.get(`shipment:${id}`);
  if (cached) return JSON.parse(cached);
  
  const shipment = await db.shipments.findById(id);
  await redis.setex(`shipment:${id}`, 3600, JSON.stringify(shipment));
  return shipment;
};
```

---

## 🔒 Security Best Practices

### Network Security

```bash
# Restrict security groups
# Backend: Allow only from ALB (port 5000)
# Database: Allow only from backend (port 5432)
# Redis: Allow only from backend (port 6379)
# Frontend: Allow from internet (ports 80, 443)
```

### Secrets Management

```bash
# Use AWS Secrets Manager
aws secretsmanager create-secret \
  --name carrier-dispatch-prod \
  --secret-string file://secrets.json

# Or use Parameter Store
aws ssm put-parameter \
  --name /carrier-dispatch/jwt-secret \
  --value "your-secret-key" \
  --type SecureString
```

### SSL/TLS

```bash
# Generate strong certificates
# Use AWS Certificate Manager (free)
# Or Let's Encrypt with Certbot (free)

# Enable HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

---

## 🔄 Backup & Recovery

### Database Backups

```bash
# Enable automated backups in RDS (7+ days)
# Enable Multi-AZ for automatic failover
# Test recovery regularly

# Manual backup
pg_dump -h your-rds-endpoint -U dispatch_user -d dispatch_db > backup.sql

# Restore
psql -h new-rds-endpoint -U dispatch_user -d dispatch_db < backup.sql
```

### Redis Snapshots

```bash
# Enable RDB persistence
redis-cli CONFIG SET save "900 1 300 10 60 10000"

# Enable AOF
redis-cli CONFIG SET appendonly yes
```

---

## ✅ Pre-Launch Checklist

- [ ] SSL/TLS certificate installed
- [ ] Environment variables configured
- [ ] Database initialized and verified
- [ ] Redis cache working
- [ ] Health checks passing
- [ ] Backups configured
- [ ] Monitoring/logging setup
- [ ] Security groups configured
- [ ] Auto-scaling policies set
- [ ] CDN configured (optional)
- [ ] Domain DNS updated
- [ ] Load testing completed
- [ ] Disaster recovery tested

---

## 📞 Support

For deployment assistance:
- 📧 Email: support@3jaysdispatching.com
- 🐛 Issues: https://github.com/3jaysdispatching-dev/carrier-dispatch-app/issues
- 💬 Slack: Join our community channel

---

**Your production deployment is ready! 🚀**
