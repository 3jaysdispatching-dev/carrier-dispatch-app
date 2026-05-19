#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🚚 Carrier Dispatch App Setup${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check for Node.js
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo -e "${YELLOW}Please install Node.js 18+ from https://nodejs.org${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js $(node -v) installed${NC}"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm $(npm -v) installed${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker from https://www.docker.com${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker installed${NC}"

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose installed${NC}\n"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please edit .env and add your API keys before running the app${NC}\n"
else
    echo -e "${GREEN}✅ .env file already exists${NC}\n"
fi

# Install backend dependencies
echo -e "${YELLOW}Installing backend dependencies...${NC}"
cd backend
if npm install; then
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install backend dependencies${NC}"
    exit 1
fi
cd ..

# Install frontend dependencies
echo -e "${YELLOW}Installing frontend dependencies...${NC}"
cd frontend
if npm install; then
    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install frontend dependencies${NC}"
    exit 1
fi
cd ..

echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}✅ Setup Complete!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Edit ${YELLOW}.env${NC} with your API keys and settings"
echo -e "2. Start databases: ${YELLOW}docker-compose up -d${NC}"
echo -e "3. Start backend: ${YELLOW}cd backend && npm run dev${NC}"
echo -e "4. Start frontend (new terminal): ${YELLOW}cd frontend && npm run dev${NC}"
echo -e "\n${GREEN}Access the application:${NC}"
echo -e "Frontend: ${BLUE}http://localhost:5173${NC}"
echo -e "Backend:  ${BLUE}http://localhost:5000${NC}"
echo -e "pgAdmin:  ${BLUE}http://localhost:5050${NC}"
echo -e "\n${GREEN}pgAdmin Credentials:${NC}"
echo -e "Email: ${YELLOW}admin@example.com${NC}"
echo -e "Password: ${YELLOW}admin${NC}\n"
