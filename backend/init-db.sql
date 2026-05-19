-- Create Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'customer' CHECK (role IN ('admin', 'manager', 'driver', 'customer')),
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
);

-- Drivers Table
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_expiry DATE,
    vehicle_id UUID,
    status VARCHAR(50) DEFAULT 'available' CHECK (status IN ('available', 'on_duty', 'off_duty', 'on_break', 'inactive')),
    current_location GEOGRAPHY(POINT, 4326),
    total_miles DECIMAL(12, 2) DEFAULT 0,
    total_deliveries INT DEFAULT 0,
    on_time_rate DECIMAL(5, 2) DEFAULT 100,
    rating DECIMAL(3, 2) DEFAULT 5.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_license (license_number)
);

-- Vehicles Table
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    make VARCHAR(100),
    model VARCHAR(100),
    year INT,
    capacity_weight DECIMAL(10, 2),
    capacity_volume DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'retired')),
    last_maintenance DATE,
    next_maintenance DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_registration (registration_number),
    INDEX idx_status (status)
);

-- Customers Table
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    phone VARCHAR(20),
    total_shipments INT DEFAULT 0,
    total_spent DECIMAL(15, 2) DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 5.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_company (company_name)
);

-- Shipments Table
CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    driver_id UUID REFERENCES drivers(id),
    origin_address VARCHAR(500) NOT NULL,
    origin_location GEOGRAPHY(POINT, 4326),
    destination_address VARCHAR(500) NOT NULL,
    destination_location GEOGRAPHY(POINT, 4326),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'in_transit', 'delivered', 'cancelled', 'delayed')),
    weight DECIMAL(10, 2),
    dimensions VARCHAR(100),
    contents TEXT,
    special_instructions TEXT,
    estimated_delivery DATE,
    actual_delivery DATE,
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    cost DECIMAL(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_shipment_number (shipment_number),
    INDEX idx_customer_id (customer_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Routes Table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    shipment_ids UUID[],
    total_distance DECIMAL(10, 2),
    estimated_duration INT,
    actual_duration INT,
    status VARCHAR(50) DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status)
);

-- Route Stops Table
CREATE TABLE route_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    shipment_id UUID NOT NULL REFERENCES shipments(id),
    sequence_number INT NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    address VARCHAR(500),
    arrival_time TIMESTAMP,
    departure_time TIMESTAMP,
    duration_minutes INT,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_route_id (route_id),
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_sequence (route_id, sequence_number)
);

-- Analytics Table
CREATE TABLE analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    total_shipments INT DEFAULT 0,
    completed_shipments INT DEFAULT 0,
    delayed_shipments INT DEFAULT 0,
    average_delivery_time DECIMAL(10, 2),
    total_revenue DECIMAL(15, 2),
    active_drivers INT DEFAULT 0,
    total_miles DECIMAL(15, 2),
    on_time_rate DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date)
);

-- Notifications Table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Transactions Table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID NOT NULL REFERENCES shipments(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    amount DECIMAL(15, 2),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50),
    stripe_transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_status (status)
);

-- Dashboard Metrics View
CREATE VIEW dashboard_metrics AS
SELECT
    (SELECT COUNT(*) FROM shipments WHERE status = 'in_transit') as active_shipments,
    (SELECT COUNT(*) FROM drivers WHERE status = 'on_duty') as active_drivers,
    (SELECT COUNT(*) FROM shipments WHERE DATE(created_at) = CURRENT_DATE) as today_shipments,
    (SELECT AVG(rating) FROM drivers) as avg_driver_rating,
    (SELECT SUM(cost) FROM shipments WHERE status = 'delivered' AND DATE(delivery_time) = CURRENT_DATE) as today_revenue,
    (SELECT COUNT(*) FROM shipments WHERE status = 'delivered' AND DATE(delivery_time) = CURRENT_DATE) as today_delivered;

-- Create Indexes for Performance
CREATE INDEX idx_shipments_customer_driver ON shipments(customer_id, driver_id);
CREATE INDEX idx_shipments_status_date ON shipments(status, created_at);
CREATE INDEX idx_drivers_status_location ON drivers(status, current_location);
CREATE INDEX idx_routes_driver_status ON routes(driver_id, status);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX idx_transactions_shipment_status ON transactions(shipment_id, status);
