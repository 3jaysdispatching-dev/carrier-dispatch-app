# 🚀 Complete AWS EC2 Deployment Guide - Step by Step

## Phase 1: Create AWS EC2 Instance

### Step 1.1: Launch EC2 Instance

```bash
# Using AWS CLI (install from: https://aws.amazon.com/cli/)
# Configure first: aws configure

aws ec2 run-instances \
  --image-id ami-0c02fb55731490381 \
  --instance-type t3.small \
  --key-name your-key-pair \
  --security-groups default \
  --region us-east-1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CarrierDispatch}]'
```

**OR via AWS Console:**
1. Go to EC2 Dashboard → Instances → Launch instances
2. Choose: **Ubuntu Server 22.04 LTS**
3. Instance type: **t3.small** (recommended for production)
4. Storage: **30GB** (gp3)
5. Security Group: Allow ports **22, 80, 443**
6. Create/Select key pair and download `.pem` file
7. Launch

### Step 1.2: Get Your EC2 Public IP

```bash
# After instance is running, get the public IP:
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=CarrierDispatch" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Save this IP! You'll need it as `EC2_HOST`**

---

## Phase 2: Initial EC2 Server Setup

### Step 2.1: Connect to Your Server

```bash
# SSH into your EC2 instance
# Replace YOUR_IP with your actual EC2 public IP
ssh -i ~/Downloads/your-key-pair.pem ubuntu@YOUR_IP

# Example:
ssh -i ~/Downloads/carrier-dispatch.pem ubuntu@54.123.45.67
```

### Step 2.2: Verify Connection and System

```bash
# Check Ubuntu version (should be 22.04)
lsb_release -a

# Check available disk space
df -h

# Update system
sudo apt update && sudo apt upgrade -y
```

---

## Phase 3: Automated Deployment

### Step 3.1: Download and Run Deployment Script

```bash
# Still logged into EC2...

# Download deployment script
cd /tmp
curl -O https://raw.githubusercontent.com/3jaysdispatching-dev/carrier-dispatch-app/main/deploy.sh

# Make executable
chmod +x deploy.sh

# Run the script (this automates everything!)
./deploy.sh
```

**What the script does:**
- ✅ Installs Docker & Docker Compose
- ✅ Clones your repository
- ✅ Creates `.env` file
- ✅ Sets up SSL with Let's Encrypt
- ✅ Configures firewall
- ✅ Starts all services
- ✅ Health checks

### Step 3.2: During Script Execution, You'll Be Prompted:

```
1. Edit .env file
   - Set JWT_SECRET to something random
   - Set STRIPE_SECRET_KEY
   - Set GOOGLE_MAPS_API_KEY
   - Press Ctrl+X to save in nano

2. Enter your domain name
   - Example: dispatch.example.com
   
3. Enter your email
   - For Let's Encrypt SSL certificate
```

---

## Phase 4: GitHub Actions Setup

### Step 4.1: Generate SSH Key for GitHub Deployments

```bash
# Still on your EC2 instance...

# Generate a deploy key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""

# Display the public key (copy this)
cat ~/.ssh/github_deploy.pub
```

### Step 4.2: Add Public Key to EC2's Authorized Keys

```bash
# Add it to authorized keys
cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys

# Verify
cat ~/.ssh/authorized_keys
```

### Step 4.3: Display Private Key for GitHub

```bash
# Display the private key (you'll copy this to GitHub secrets)
cat ~/.ssh/github_deploy
```

**Copy the entire output** (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`)

---

## Phase 5: Configure GitHub Secrets

### Step 5.1: Add Secrets to GitHub

Go to: **Your Repository → Settings → Secrets and variables → Actions**

Click **"New repository secret"** and add these:

#### Secret 1: EC2_HOST
- **Name:** `EC2_HOST`
- **Value:** Your EC2 public IP (e.g., `54.123.45.67`)

#### Secret 2: EC2_USER
- **Name:** `EC2_USER`
- **Value:** `ubuntu`

#### Secret 3: EC2_SSH_KEY
- **Name:** `EC2_SSH_KEY`
- **Value:** Paste the entire private key (from `~/.ssh/github_deploy`)

#### Secret 4: SLACK_WEBHOOK (Optional)
- **Name:** `SLACK_WEBHOOK`
- **Value:** Your Slack webhook URL (optional for notifications)

---

## Phase 6: Update Your Deployment Workflow

### Step 6.1: Edit `.github/workflows/deploy.yml`

Replace the file content with:

```yaml
name: Production Deployment

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: SSH Deploy to EC2
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd /opt/carrier-dispatch-app
            git pull origin main
            
            # Update environment if needed
            if [ ! -f ".env" ]; then
              cp .env.example .env
              echo "⚠️  .env created - please configure it on the server"
            fi
            
            # Stop existing services
            docker-compose -f docker-compose.prod.yml down || true
            
            # Pull latest images
            docker-compose -f docker-compose.prod.yml pull
            
            # Start services
            docker-compose -f docker-compose.prod.yml up -d
            
            # Wait for services to be ready
            sleep 10
            
            # Health check
            if curl -f http://localhost:5000/health > /dev/null 2>&1; then
              echo "✅ Deployment successful!"
            else
              echo "❌ Health check failed"
              docker-compose -f docker-compose.prod.yml logs backend
              exit 1
            fi

      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Deployment to EC2: ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          fields: repo,message,commit,author
```

---

## Phase 7: Configure Domain DNS

### Step 7.1: Update Your Domain Records

In your domain registrar (GoDaddy, Route53, Cloudflare, etc.):

Create an **A Record:**
- **Name:** `dispatch` (or subdomain)
- **Type:** A
- **Value:** Your EC2 public IP (e.g., `54.123.45.67`)
- **TTL:** 300 (5 minutes)

Example:
```
dispatch.example.com → 54.123.45.67
```

Allow 15-30 minutes for DNS propagation.

---

## Phase 8: Verify Deployment

### Step 8.1: Check Services Status

```bash
# SSH into EC2 again
ssh -i ~/Downloads/carrier-dispatch.pem ubuntu@YOUR_IP

# Check running containers
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml ps

# View logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f backend
```

### Step 8.2: Test Application

```bash
# Health check
curl -I http://localhost:5000/health

# Frontend (once domain is propagated)
curl -I https://dispatch.example.com

# API
curl -I https://dispatch.example.com/api
```

### Step 8.3: Access Your Application

Once domain DNS propagates:
- **Web App:** https://dispatch.example.com
- **API:** https://dispatch.example.com/api
- **Default Login:** Check your frontend for test credentials

---

## Phase 9: Continuous Deployment Workflow

### Now Every Push to `main` Will:

1. ✅ GitHub Actions triggers
2. ✅ SSH connects to EC2
3. ✅ Pulls latest code
4. ✅ Restarts Docker services
5. ✅ Runs health checks
6. ✅ Notifies Slack

**To deploy:**
```bash
git add .
git commit -m "feat: New feature"
git push origin main
```

Watch deployment progress at: **Your Repo → Actions**

---

## Phase 10: Monitoring & Maintenance

### Step 10.1: View Application Logs

```bash
# SSH into EC2
ssh -i ~/Downloads/carrier-dispatch.pem ubuntu@YOUR_IP

# Tail backend logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f backend

# Tail frontend logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f frontend

# View database logs
docker-compose -f /opt/carrier-dispatch-app/docker-compose.prod.yml logs -f postgres
```

### Step 10.2: Manual Updates

```bash
# SSH into EC2
ssh -i ~/Downloads/carrier-dispatch.pem ubuntu@YOUR_IP

# Pull latest code
cd /opt/carrier-dispatch-app
git pull origin main

# Restart services
docker-compose -f docker-compose.prod.yml restart

# View updated logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Step 10.3: Environment Variables Update

```bash
# SSH into EC2
ssh -i ~/Downloads/carrier-dispatch.pem ubuntu@YOUR_IP

# Edit .env
nano /opt/carrier-dispatch-app/.env

# Restart to apply changes
cd /opt/carrier-dispatch-app
docker-compose -f docker-compose.prod.yml restart backend
```

---

## ✅ Complete Checklist

- [ ] EC2 instance created (t3.small recommended)
- [ ] EC2 public IP noted
- [ ] SSH key pair downloaded
- [ ] Connected to EC2 via SSH
- [ ] `deploy.sh` executed successfully
- [ ] `.env` file configured with production values
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] GitHub SSH keys generated and added
- [ ] GitHub Secrets configured (EC2_HOST, EC2_USER, EC2_SSH_KEY)
- [ ] `.github/workflows/deploy.yml` updated
- [ ] Domain DNS A record pointing to EC2 IP
- [ ] DNS propagated (tested with `nslookup`)
- [ ] Application accessible via domain HTTPS
- [ ] Health checks passing
- [ ] Test deployment by pushing to `main`
- [ ] Slack notifications working (if configured)

---

## 🆘 Troubleshooting

### Can't SSH to EC2
```bash
# Check key permissions
chmod 400 ~/Downloads/your-key.pem

# Try verbose connection
ssh -v -i ~/Downloads/your-key.pem ubuntu@YOUR_IP
```

### Services not starting
```bash
# Check Docker logs
docker logs $(docker ps -a -q) --tail 50

# Restart services
cd /opt/carrier-dispatch-app
docker-compose -f docker-compose.prod.yml restart

# Check .env file
cat .env | grep -E "DATABASE_URL|JWT_SECRET"
```

### Domain not working
```bash
# Check DNS resolution
nslookup dispatch.example.com

# Check if port 443 is open
curl -I https://YOUR_IP

# Check firewall
sudo ufw status
```

### SSL certificate issues
```bash
# Renew certificate manually
sudo certbot renew

# Check certificate expiry
sudo certbot certificates
```

---

## 📞 Support

- **Deployment Issues:** Check logs with `docker-compose logs`
- **GitHub Actions Failures:** Check repo → Actions tab for detailed logs
- **Email:** support@3jaysdispatching.com

---

**Your production app is now fully automated! 🎉**
