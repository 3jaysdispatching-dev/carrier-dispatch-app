# 🚀 AWS EC2 Deployment - Step by Step Guide

## Prerequisites

- ✅ AWS Account with EC2 access
- ✅ Domain name (optional but recommended)
- ✅ SSH key pair downloaded locally
- ✅ 30+ minutes to complete

---

## Step 1: Launch EC2 Instance

### Via AWS Console:

1. Go to **EC2 Dashboard** → **Instances** → **Launch Instances**
2. **Name**: `carrier-dispatch-prod`
3. **AMI**: Ubuntu 22.04 LTS (free tier eligible)
4. **Instance Type**: `t3.medium` (recommended for production)
   - Min for dev: `t3.small`
   - Min for production: `t3.medium`
5. **Key Pair**: Create or select existing key pair
   - Download and save safely: `carrier-dispatch-key.pem`
6. **Security Group**: Create new security group with:
   - SSH (22): Restricted to your IP
   - HTTP (80): 0.0.0.0/0
   - HTTPS (443): 0.0.0.0/0
7. **Storage**: 30+ GB (gp3 recommended)
8. Click **Launch Instance**

### Get Your Instance Details:

Once launched, note:
- **Public IP**: `xx.xx.xx.xx`
- **Instance ID**: `i-xxxxxxxxx`

---

## Step 2: Connect to Your Instance

```bash
# Make key readable (one-time)
chmod 400 carrier-dispatch-key.pem

# SSH into instance
ssh -i carrier-dispatch-key.pem ubuntu@<YOUR_PUBLIC_IP>
```

---

## Step 3: Run Deployment Script

```bash
# Download and run deployment script
curl -O https://raw.githubusercontent.com/3jaysdispatching-dev/carrier-dispatch-app/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

The script will:
- ✅ Update system packages
- ✅ Install Docker & Docker Compose
- ✅ Clone your repository
- ✅ Setup environment variables
- ✅ Deploy with Docker Compose
- ✅ Setup SSL with Let's Encrypt
- ✅ Configure auto-renewal

---

## Step 4: Configure Environment Variables

During deployment, you'll be prompted to edit `.env`:

```bash
nano /opt/carrier-dispatch-app/.env
```

**Required Variables:**

```env
# Backend
BACKEND_PORT=5000
DATABASE_URL=postgresql://dispatch_user:PASSWORD@localhost:5432/dispatch_db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_random_32_character_secret_key_here
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxx
GOOGLE_MAPS_API_KEY=AIzaXxxxxxxxxxxx
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxx
TWILIO_PHONE=+1234567890

# Frontend
VITE_API_URL=https://your-domain.com
VITE_MAPBOX_TOKEN=pk_xxxxxxxxxxxxxxx
VITE_GOOGLE_MAPS_KEY=AIzaXxxxxxxxxxxx
```

Save with `Ctrl+X` → `Y` → `Enter`

---

## Step 5: Verify Deployment

```bash
# Check running containers
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml ps

# View logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f

# Test health endpoint
curl http://localhost:5000/health
```

---

## Step 6: Setup Domain (Optional)

### Option A: Route53 (AWS)

1. Go to **Route53** → **Hosted Zones**
2. Create hosted zone for your domain
3. Add **A Record**:
   - Name: `dispatch.yourdomain.com`
   - Type: `A`
   - Value: Your EC2 Public IP
4. Update nameservers at your domain registrar

### Option B: Any Domain Registrar

1. Add **A Record**:
   - Host: `dispatch` (or your subdomain)
   - Type: `A`
   - Value: Your EC2 Public IP

---

## Step 7: Setup SSL Certificate

The deployment script handles this, but if you need to redo it:

```bash
# Request certificate
sudo certbot certonly --standalone -d dispatch.yourdomain.com --email your@email.com --agree-tos

# Copy to app directory
sudo cp /etc/letsencrypt/live/dispatch.yourdomain.com/fullchain.pem /opt/carrier-dispatch-app/ssl/
sudo cp /etc/letsencrypt/live/dispatch.yourdomain.com/privkey.pem /opt/carrier-dispatch-app/ssl/
sudo chown ubuntu:ubuntu /opt/carrier-dispatch-app/ssl/*

# Restart frontend
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml restart frontend
```

---

## Step 8: Setup GitHub Actions for Auto-Deployment

### Add Secrets to GitHub:

1. Go to **GitHub Repo** → **Settings** → **Secrets and Variables** → **Actions**
2. Add these secrets:

```
EC2_HOST = your-ec2-public-ip
EC2_USER = ubuntu
EC2_SSH_KEY = (paste content of carrier-dispatch-key.pem)
DOMAIN = dispatch.yourdomain.com
SLACK_WEBHOOK = https://hooks.slack.com/services/... (optional)
```

### How It Works:

```
git push main
    ↓
GitHub Actions builds Docker images
    ↓
Pushes to GitHub Container Registry
    ↓
SSH into EC2 and pulls latest code
    ↓
Restarts containers
    ↓
Runs health checks
```

---

## Step 9: Monitoring & Maintenance

### View Logs

```bash
# Real-time logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f backend

# Last 100 lines
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs backend | tail -100

# Filter by service
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs frontend
```

### Database Backups

```bash
# Manual backup
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml exec -T postgres pg_dump -U dispatch_user dispatch_db > backup.sql

# Restore from backup
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml exec -T postgres psql -U dispatch_user dispatch_db < backup.sql
```

### Check Disk Space

```bash
df -h

# Clean up old Docker images
docker image prune -a --force
```

### Restart Services

```bash
# Restart all services
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml restart

# Restart specific service
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml restart backend
```

---

## Step 10: Auto-Update SSL Certificate

The script enables auto-renewal. Verify:

```bash
# Check renewal status
sudo systemctl status certbot.timer

# Manual renewal (if needed)
sudo certbot renew --dry-run
```

---

## Troubleshooting

### Port 80/443 Already in Use

```bash
# Find process using the port
sudo lsof -i :80
sudo lsof -i :443

# Kill process if needed
sudo kill -9 <PID>
```

### Docker Compose Not Found

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Can't Connect to Database

```bash
# Check if postgres is running
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml ps postgres

# Check database logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs postgres

# Restart database
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml restart postgres
```

### SSL Certificate Issues

```bash
# Check certificate expiration
sudo certbot certificates

# Renew immediately
sudo certbot renew

# Restart with new certificate
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml restart frontend
```

---

## 📊 Estimated Costs (AWS)

**Monthly Estimate** (light usage):
- EC2 t3.medium: ~$30
- RDS (optional): ~$30-50
- Data transfer: ~$5-10
- **Total: ~$35-90/month**

---

## ✅ Deployment Checklist

- [ ] EC2 instance launched
- [ ] Security group configured
- [ ] SSH access verified
- [ ] Deployment script ran successfully
- [ ] Environment variables configured
- [ ] Services running (docker ps)
- [ ] Health checks passing
- [ ] Domain DNS updated
- [ ] SSL certificate working
- [ ] GitHub secrets added
- [ ] Test deployment via git push
- [ ] Monitoring/alerts configured

---

## 📞 Support

Need help?
- 📧 Email: support@3jaysdispatching.com
- 🐛 Issues: https://github.com/3jaysdispatching-dev/carrier-dispatch-app/issues
- 📚 Docs: Check DEPLOYMENT.md

---

**Your app is now production-ready! 🎉**
