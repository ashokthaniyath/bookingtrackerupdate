-- COMPREHENSIVE DATABASE SCHEMA FOR RESORT BOOKING TRACKER
-- This schema supports all pages/features with many-to-many relationships
-- Designed for PostgreSQL (Supabase)

-- ============================================================================
-- CORE ENTITY TABLES
-- ============================================================================

-- Users/Staff Table (Authentication & User Management)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    username VARCHAR(100) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role ENUM('admin', 'manager', 'staff', 'guest') DEFAULT 'staff',
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Guests Table (Guest Management Page)
CREATE TABLE guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    id_number VARCHAR(50),
    nationality VARCHAR(50),
    date_of_birth DATE,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    preferences TEXT, -- JSON field for dietary preferences, room preferences, etc.
    loyalty_tier ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    total_stays INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Room Types Table
CREATE TABLE room_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL, -- 'Single', 'Double', 'Deluxe', 'Suite'
    description TEXT,
    base_price DECIMAL(8,2) NOT NULL,
    max_occupancy INTEGER NOT NULL,
    amenities TEXT, -- JSON field for amenities list
    square_footage INTEGER,
    bed_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rooms Table (Room Management Page)
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number VARCHAR(10) UNIQUE NOT NULL,
    room_type_id UUID REFERENCES room_types(id),
    floor INTEGER,
    building VARCHAR(50),
    status ENUM('available', 'occupied', 'cleaning', 'maintenance', 'out_of_order') DEFAULT 'available',
    current_rate DECIMAL(8,2),
    wifi_password VARCHAR(50),
    last_cleaned TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Bookings Table (Calendar Page, Booking Form)
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES guests(id),
    room_id UUID REFERENCES rooms(id),
    user_id UUID REFERENCES users(id), -- Staff member who created the booking
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP NOT NULL,
    adults INTEGER DEFAULT 1,
    children INTEGER DEFAULT 0,
    total_amount DECIMAL(10,2),
    deposit_amount DECIMAL(10,2),
    deposit_paid BOOLEAN DEFAULT false,
    payment_status ENUM('pending', 'partial', 'paid', 'refunded', 'cancelled') DEFAULT 'pending',
    booking_status ENUM('confirmed', 'checked_in', 'checked_out', 'cancelled', 'no_show') DEFAULT 'confirmed',
    source ENUM('direct', 'phone', 'email', 'walk_in', 'online', 'agency') DEFAULT 'direct',
    notes TEXT,
    special_requests TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Payments Table (Payments Page)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'credit_card', 'debit_card', 'bank_transfer', 'mobile_payment') NOT NULL,
    payment_type ENUM('deposit', 'full_payment', 'additional_charge', 'refund') NOT NULL,
    transaction_id VARCHAR(255),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by UUID REFERENCES users(id),
    notes TEXT,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed'
);

-- Invoices Table (Invoices Page)
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('draft', 'sent', 'paid', 'overdue', 'cancelled') DEFAULT 'draft',
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FEATURE-SPECIFIC TABLES
-- ============================================================================

-- Room Calendars Table (Calendar Page - Google Calendar Integration)
CREATE TABLE room_calendars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id),
    calendar_id VARCHAR(255) UNIQUE, -- Google Calendar ID
    calendar_name VARCHAR(255),
    is_shared BOOLEAN DEFAULT false,
    auto_accept_bookings BOOLEAN DEFAULT true,
    color VARCHAR(7) DEFAULT '#4285F4', -- Hex color code
    is_public BOOLEAN DEFAULT false,
    public_url TEXT,
    sync_enabled BOOLEAN DEFAULT true,
    last_sync TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Unavailable Hours Table (Calendar Management)
CREATE TABLE unavailable_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_calendar_id UUID REFERENCES room_calendars(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    start_hour INTEGER NOT NULL CHECK (start_hour >= 0 AND start_hour <= 23),
    end_hour INTEGER NOT NULL CHECK (end_hour >= 0 AND end_hour <= 24),
    days_of_week TEXT, -- JSON array: [1,2,3,4,5] for Mon-Fri
    is_recurring BOOLEAN DEFAULT true,
    reason VARCHAR(255) DEFAULT 'Maintenance',
    date_specific DATE, -- For one-time blocks
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Analytics Dashboard Tables
CREATE TABLE daily_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE UNIQUE NOT NULL,
    total_bookings INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    occupancy_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage
    average_daily_rate DECIMAL(8,2) DEFAULT 0.00,
    rooms_available INTEGER DEFAULT 0,
    rooms_occupied INTEGER DEFAULT 0,
    new_guests INTEGER DEFAULT 0,
    returning_guests INTEGER DEFAULT 0,
    cancellations INTEGER DEFAULT 0,
    no_shows INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Profile Settings & Preferences
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) UNIQUE,
    theme ENUM('light', 'dark', 'auto') DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    date_format VARCHAR(20) DEFAULT 'DD/MM/YYYY',
    notifications_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT false,
    dashboard_layout TEXT, -- JSON for custom dashboard configuration
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================================
-- MANY-TO-MANY RELATIONSHIP TABLES
-- ============================================================================

-- Guest-Booking Relationships (Multiple guests per booking for group bookings)
CREATE TABLE booking_guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    guest_id UUID REFERENCES guests(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false, -- Primary guest for the booking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(booking_id, guest_id)
);

-- Room-Booking Relationships (Multiple rooms per booking for group reservations)
CREATE TABLE booking_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP NOT NULL,
    rate DECIMAL(8,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(booking_id, room_id)
);

-- Calendar Sharing (Multiple users can access room calendars)
CREATE TABLE calendar_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_calendar_id UUID REFERENCES room_calendars(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    permission_level ENUM('view', 'edit', 'admin') DEFAULT 'view',
    shared_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(room_calendar_id, user_id)
);

-- Guest Services/Amenities Relationships
CREATE TABLE guest_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(8,2),
    category ENUM('spa', 'restaurant', 'transport', 'activity', 'room_service', 'laundry', 'other') NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booking_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    service_id UUID REFERENCES guest_services(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(8,2),
    total_price DECIMAL(8,2),
    service_date TIMESTAMP,
    status ENUM('requested', 'confirmed', 'completed', 'cancelled') DEFAULT 'requested',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff-Room Assignments (Multiple staff can be assigned to multiple rooms)
CREATE TABLE staff_room_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    assignment_type ENUM('housekeeping', 'maintenance', 'primary_manager') NOT NULL,
    assigned_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    UNIQUE(user_id, room_id, assignment_type)
);

-- Guest Groups (For handling family/corporate group bookings)
CREATE TABLE guest_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    group_type ENUM('family', 'corporate', 'wedding', 'tour', 'other') NOT NULL,
    contact_person_id UUID REFERENCES guests(id),
    special_requirements TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE guest_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES guest_groups(id) ON DELETE CASCADE,
    guest_id UUID REFERENCES guests(id) ON DELETE CASCADE,
    role ENUM('leader', 'member', 'child') DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(group_id, guest_id)
);

-- ============================================================================
-- NOTIFICATION & COMMUNICATION TABLES
-- ============================================================================

-- Notifications (For all pages/features)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    type ENUM('booking_reminder', 'payment_due', 'maintenance_due', 'guest_arrival', 'system_alert') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_id UUID, -- Can reference booking_id, room_id, etc.
    related_type VARCHAR(50), -- 'booking', 'room', 'payment', etc.
    is_read BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMP,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Calendar Notifications (Calendar Page specific)
CREATE TABLE calendar_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    guest_email VARCHAR(255) NOT NULL,
    notification_type ENUM('reminder', 'confirmation', 'cancellation', 'modification') NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    sent BOOLEAN DEFAULT false,
    message TEXT DEFAULT '',
    email_subject VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP
);

-- ============================================================================
-- REPORTING & ANALYTICS TABLES
-- ============================================================================

-- Revenue Analytics (Analytics/Dashboard Page)
CREATE TABLE revenue_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    room_type_id UUID REFERENCES room_types(id),
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    room_revenue DECIMAL(12,2) DEFAULT 0.00,
    service_revenue DECIMAL(12,2) DEFAULT 0.00,
    total_bookings INTEGER DEFAULT 0,
    average_stay_duration DECIMAL(4,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, room_type_id)
);

-- Guest Analytics
CREATE TABLE guest_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    new_guests INTEGER DEFAULT 0,
    returning_guests INTEGER DEFAULT 0,
    total_guests INTEGER DEFAULT 0,
    average_spend DECIMAL(8,2) DEFAULT 0.00,
    guest_satisfaction_score DECIMAL(3,2) DEFAULT 0.00, -- Out of 5.00
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date)
);

-- ============================================================================
-- AUDIT & HISTORY TABLES
-- ============================================================================

-- Booking History (Track all changes to bookings)
CREATE TABLE booking_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id),
    changed_by UUID REFERENCES users(id),
    change_type ENUM('created', 'modified', 'cancelled', 'checked_in', 'checked_out') NOT NULL,
    old_values TEXT, -- JSON of previous values
    new_values TEXT, -- JSON of new values
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Room Status History (Room Management Page)
CREATE TABLE room_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id),
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_by UUID REFERENCES users(id),
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Core entity indexes
CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_guests_phone ON guests(phone);
CREATE INDEX idx_rooms_number ON rooms(number);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_bookings_check_in ON bookings(check_in);
CREATE INDEX idx_bookings_check_out ON bookings(check_out);
CREATE INDEX idx_bookings_status ON bookings(booking_status);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_invoices_number ON invoices(invoice_number);

-- Relationship indexes
CREATE INDEX idx_booking_guests_booking ON booking_guests(booking_id);
CREATE INDEX idx_booking_guests_guest ON booking_guests(guest_id);
CREATE INDEX idx_booking_rooms_booking ON booking_rooms(booking_id);
CREATE INDEX idx_booking_rooms_room ON booking_rooms(room_id);
CREATE INDEX idx_calendar_shares_calendar ON calendar_shares(room_calendar_id);
CREATE INDEX idx_calendar_shares_user ON calendar_shares(user_id);

-- Analytics indexes
CREATE INDEX idx_daily_analytics_date ON daily_analytics(date);
CREATE INDEX idx_revenue_analytics_date ON revenue_analytics(date);
CREATE INDEX idx_guest_analytics_date ON guest_analytics(date);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_calendar_notifications_booking ON calendar_notifications(booking_id);

-- ============================================================================
-- VIEWS FOR COMPLEX QUERIES
-- ============================================================================

-- Room Occupancy View (Room Management Dashboard)
CREATE VIEW room_occupancy_summary AS
SELECT 
    r.id as room_id,
    r.number,
    rt.name as room_type,
    r.status,
    b.id as current_booking_id,
    g.name as current_guest,
    b.check_in,
    b.check_out,
    CASE 
        WHEN b.id IS NULL THEN 'Available'
        WHEN NOW() BETWEEN b.check_in AND b.check_out THEN 'Occupied'
        WHEN b.check_in > NOW() THEN 'Reserved'
        ELSE 'Available'
    END as occupancy_status
FROM rooms r
LEFT JOIN room_types rt ON r.room_type_id = rt.id
LEFT JOIN bookings b ON r.id = b.room_id 
    AND b.booking_status = 'confirmed'
    AND b.check_out > NOW()
    AND b.check_in <= NOW() + INTERVAL '1 day'
LEFT JOIN guests g ON b.guest_id = g.id;

-- Revenue Summary View (Analytics Dashboard)
CREATE VIEW revenue_summary AS
SELECT 
    DATE(b.check_in) as date,
    COUNT(b.id) as total_bookings,
    SUM(b.total_amount) as total_revenue,
    AVG(b.total_amount) as average_booking_value,
    COUNT(DISTINCT b.guest_id) as unique_guests,
    rt.name as room_type
FROM bookings b
JOIN rooms r ON b.room_id = r.id
JOIN room_types rt ON r.room_type_id = rt.id
WHERE b.booking_status != 'cancelled'
GROUP BY DATE(b.check_in), rt.name;

-- Guest Booking Summary View (Guest Management)
CREATE VIEW guest_booking_summary AS
SELECT 
    g.id as guest_id,
    g.name,
    g.email,
    COUNT(b.id) as total_bookings,
    SUM(b.total_amount) as total_spent,
    MAX(b.check_out) as last_stay,
    MIN(b.check_in) as first_stay,
    CASE 
        WHEN COUNT(b.id) = 0 THEN 'New'
        WHEN COUNT(b.id) = 1 THEN 'First Time'
        WHEN COUNT(b.id) <= 5 THEN 'Regular'
        ELSE 'VIP'
    END as guest_tier
FROM guests g
LEFT JOIN bookings b ON g.id = b.guest_id 
    AND b.booking_status != 'cancelled'
GROUP BY g.id, g.name, g.email;

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Update guest analytics when bookings change
DELIMITER //
CREATE TRIGGER update_guest_totals 
AFTER INSERT ON bookings 
FOR EACH ROW
BEGIN
    UPDATE guests 
    SET total_stays = (
        SELECT COUNT(*) FROM bookings 
        WHERE guest_id = NEW.guest_id 
        AND booking_status = 'checked_out'
    ),
    total_spent = (
        SELECT COALESCE(SUM(total_amount), 0) FROM bookings 
        WHERE guest_id = NEW.guest_id 
        AND booking_status != 'cancelled'
    )
    WHERE id = NEW.guest_id;
END//
DELIMITER ;

-- ============================================================================
-- SAMPLE DATA INSERTION FUNCTIONS
-- ============================================================================

-- Function to create sample room types
INSERT INTO room_types (name, description, base_price, max_occupancy, amenities) VALUES
('Single', 'Cozy single room with modern amenities', 99.00, 1, '["WiFi", "TV", "Air Conditioning", "Mini Bar"]'),
('Double', 'Comfortable double room for couples', 149.00, 2, '["WiFi", "TV", "Air Conditioning", "Mini Bar", "Balcony"]'),
('Deluxe', 'Spacious deluxe room with premium features', 199.00, 3, '["WiFi", "TV", "Air Conditioning", "Mini Bar", "Balcony", "Room Service"]'),
('Suite', 'Luxury suite with separate living area', 299.00, 4, '["WiFi", "TV", "Air Conditioning", "Mini Bar", "Balcony", "Room Service", "Jacuzzi", "Butler Service"]');

-- Function to create sample guest services
INSERT INTO guest_services (name, description, price, category) VALUES
('Spa Treatment', 'Relaxing spa treatment', 80.00, 'spa'),
('Airport Transfer', 'Round trip airport transfer', 50.00, 'transport'),
('Laundry Service', 'Professional laundry service', 25.00, 'laundry'),
('Room Service', '24/7 room service', 15.00, 'room_service'),
('City Tour', 'Guided city tour', 60.00, 'activity');

-- ============================================================================
-- NOTES FOR IMPLEMENTATION
-- ============================================================================

/*
This comprehensive schema supports:

1. **All Pages/Features:**
   - Dashboard/Analytics: daily_analytics, revenue_analytics, guest_analytics
   - Guest Management: guests, guest_groups, guest_booking_summary view
   - Room Management: rooms, room_types, room_status_history
   - Calendar: room_calendars, unavailable_hours, calendar_notifications
   - Bookings: bookings, booking_guests, booking_rooms, booking_history
   - Payments: payments, invoices
   - Profile: users, user_preferences

2. **Many-to-Many Relationships:**
   - Guests ↔ Bookings (booking_guests)
   - Rooms ↔ Bookings (booking_rooms)
   - Users ↔ Room Calendars (calendar_shares)
   - Guests ↔ Services (booking_services)
   - Staff ↔ Rooms (staff_room_assignments)
   - Guests ↔ Groups (guest_group_members)

3. **Advanced Features:**
   - Audit trails (booking_history, room_status_history)
   - Analytics and reporting views
   - Notification system
   - Calendar integration support
   - Revenue tracking
   - Guest loyalty/tier system

4. **Database Setup:**
   - Uses UUID for PostgreSQL/Supabase
   - Uses gen_random_uuid() for primary keys
   - Optimized for Supabase PostgreSQL database

To deploy in Supabase:
1. Copy this schema to the Supabase SQL Editor
2. Run the schema to create all tables
3. Enable Row Level Security (RLS) as needed
4. Configure authentication and policies
*/
