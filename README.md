# 🚚 Carrier Dispatch App - Enterprise Edition

A fully-featured, production-ready carrier dispatch system with real-time tracking, route optimization, driver management, and advanced analytics.

## 🎯 Features

### Core Features
- ✅ **Real-time GPS Tracking** - Live driver location updates
- ✅ **Shipment Management** - Create, track, and manage shipments
- ✅ **Driver Management** - Manage drivers, assignments, and performance
- ✅ **Route Optimization** - AI-powered route planning
- ✅ **WebSocket Real-time Updates** - Live notifications
- ✅ **Mobile Responsive** - Works on all devices
- ✅ **Authentication & Authorization** - Secure access control
- ✅ **Advanced Analytics** - Performance dashboards
- ✅ **Notifications** - Email, SMS, and push notifications
- ✅ **Payment Processing** - Integrated billing system

### Advanced Features
- 📊 Dashboard with KPIs
- 🗺️ Interactive Google Maps integration
- 📱 Mobile app support
- 🔔 Real-time alerts & notifications
- 💳 Stripe payment integration
- 📈 Historical analytics & reporting
- 🔐 Role-based access control (RBAC)
- 📞 Customer support portal
- 🚗 Fleet management
- 📋 Compliance & documentation

## 🏗️ Tech Stack

### Frontend
- React 18 + TypeScript
- Vite (lightning-fast build)
- Zustand (state management)
- TailwindCSS (styling)
- Mapbox GL (mapping)
- Socket.io Client (real-time)

### Backend
- Node.js + Express
- TypeScript
- PostgreSQL (primary database)
- Redis (caching & real-time)
- Socket.io (WebSocket)
- JWT (authentication)

### DevOps
- Docker & Docker Compose
- GitHub Actions (CI/CD)
- AWS deployment ready

## 📦 Project Structure

```
carrier-dispatch-app/
├── frontend/                 # React web application
│   ├── src/
│   │   ├── components/      # Reusable React components
│   │   ├── pages/           # Page components
│   │   ├── store.ts         # Zustand state management
│   │   ├── api.ts           # API client
│   │   └── App.tsx
│   ├── package.json
│   └── vite.config.ts
├── backend/                  # Express API server
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── models/          # Database models
│   │   ├── routes/          # API routes
│   │   ├── middleware/      # Express middleware
│   │   ├── services/        # Business logic
│   │   ├── utils/           # Helper functions
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
├── docker-compose.yml       # Database & cache setup
├── .env.example             # Environment variables template
└── setup.sh                 # Installation script
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Docker & Docker Compose
- Git

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/3jaysdispatching-dev/carrier-dispatch-app.git
cd carrier-dispatch-app

# 2. Run setup script
chmod +x setup.sh
./setup.sh

# 3. Configure environment
cp .env.example .env
# Edit .env with your settings

# 4. Start databases
docker-compose up -d

# 5. Start backend
cd backend
npm install
npm run dev

# 6. Start frontend (new terminal)
cd frontend
npm install
npm run dev
```

### Access the Application
- **Web App**: http://localhost:5173
- **API**: http://localhost:5000
- **API Docs**: http://localhost:5000/api/docs

## 🔐 Environment Variables

```env
# Backend
BACKEND_PORT=5000
DATABASE_URL=postgresql://user:password@localhost:5432/dispatch_db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_jwt_secret_key
STRIPE_SECRET_KEY=sk_test_xxxx
GOOGLE_MAPS_API_KEY=your_api_key

# Frontend
VITE_API_URL=http://localhost:5000
VITE_MAPBOX_TOKEN=your_mapbox_token
```

## 📚 API Endpoints

### Shipments
- `GET /api/shipments` - List all shipments
- `POST /api/shipments` - Create new shipment
- `GET /api/shipments/:id` - Get shipment details
- `PATCH /api/shipments/:id` - Update shipment
- `DELETE /api/shipments/:id` - Delete shipment

### Drivers
- `GET /api/drivers` - List all drivers
- `POST /api/drivers` - Create new driver
- `GET /api/drivers/:id` - Get driver details
- `PATCH /api/drivers/:id` - Update driver
- `PATCH /api/drivers/:id/location` - Update GPS location
- `GET /api/drivers/:id/performance` - Get performance metrics

### Routes
- `GET /api/routes` - List all routes
- `POST /api/routes/optimize` - Optimize route with waypoints
- `GET /api/routes/:id` - Get route details

### Auth
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - User logout

### Analytics
- `GET /api/analytics/dashboard` - Dashboard KPIs
- `GET /api/analytics/drivers` - Driver analytics
- `GET /api/analytics/shipments` - Shipment analytics

## 🗄️ Database Schema

### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  role ENUM('admin', 'manager', 'driver', 'customer'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Drivers
```sql
CREATE TABLE drivers (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  license_number VARCHAR UNIQUE,
  vehicle_id UUID,
  status ENUM('available', 'on_duty', 'off_duty', 'on_break'),
  current_location POINT,
  total_miles DECIMAL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Shipments
```sql
CREATE TABLE shipments (
  id UUID PRIMARY KEY,
  origin_address VARCHAR NOT NULL,
  destination_address VARCHAR NOT NULL,
  status ENUM('pending', 'assigned', 'in_transit', 'delivered', 'cancelled'),
  driver_id UUID REFERENCES drivers(id),
  weight DECIMAL,
  dimensions VARCHAR,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMP
);
```

### Routes
```sql
CREATE TABLE routes (
  id UUID PRIMARY KEY,
  driver_id UUID REFERENCES drivers(id),
  waypoints JSONB,
  total_distance DECIMAL,
  estimated_duration INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔗 Real-time Events (WebSocket)

```javascript
// Connect to WebSocket
const socket = io('http://localhost:5000');

// Listen for events
socket.on('driver_location_updated', (data) => {
  console.log('Driver location:', data);
});

socket.on('shipment_status_changed', (data) => {
  console.log('Shipment status:', data);
});

socket.on('route_optimized', (data) => {
  console.log('Optimized route:', data);
});
```

## 📊 Dashboard Features

- **Real-time Map** - Live driver locations
- **Performance Metrics** - On-time delivery rate, average speed
- **Active Shipments** - Status overview
- **Driver Stats** - Hours worked, miles driven
- **Revenue Chart** - Income tracking
- **Alerts & Notifications** - System alerts

## 🔐 Security Features

- JWT authentication
- Role-based access control (RBAC)
- Data encryption
- Rate limiting
- CORS protection
- SQL injection prevention
- XSS protection
- HTTPS enforcement

## 📱 Mobile Support

- Responsive design
- Mobile-optimized UI
- Native app ready (React Native)
- Offline capability

## 🧪 Testing

```bash
# Backend tests
cd backend
npm run test

# Frontend tests
cd frontend
npm run test
```

## 📈 Performance Optimization

- Code splitting
- Lazy loading
- Image optimization
- Database indexing
- Redis caching
- CDN integration ready

## 🚀 Deployment

### Docker Deployment
```bash
docker-compose -f docker-compose.yml up -d
```

### AWS Deployment
- Configure AWS credentials
- Update deployment variables
- Push to ECR
- Deploy via ECS/Lambda

### Environment-specific Configs
See `deployment/` directory for production configs

## 📞 Support & Contribution

- 📧 Email: support@3jaysdispatching.com
- 🐛 Issues: GitHub Issues
- 🔄 PRs: Welcome!

## 📄 License

MIT License - See LICENSE file

## 🎉 Getting Started Next Steps

1. ✅ Install and run locally
2. ✅ Explore the dashboard
3. ✅ Create test shipments
4. ✅ Add drivers
5. ✅ Test real-time updates
6. ✅ Deploy to production

---

**Built with ❤️ for 3 Jays Dispatching**
