-- Supabase Database Schema for Booking Tracker
-- Execute these SQL commands in your Supabase SQL Editor

-- Enable Row Level Security (RLS) on all tables
-- You can modify these policies based on your authentication requirements

-- 1. Create Guests table
CREATE TABLE IF NOT EXISTS guests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL,
    email VARCHAR,
    phone VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for guests
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;

-- Create policy for guests (adjust as needed)
CREATE POLICY "Allow all operations on guests" ON guests
    FOR ALL USING (true) WITH CHECK (true);

-- 2. Create Rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    number VARCHAR NOT NULL UNIQUE,
    type VARCHAR NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'available',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for rooms
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Create policy for rooms
CREATE POLICY "Allow all operations on rooms" ON rooms
    FOR ALL USING (true) WITH CHECK (true);

-- 3. Create Bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guest_name VARCHAR NOT NULL,
    guest_email VARCHAR,
    guest_phone VARCHAR,
    room_number VARCHAR NOT NULL,
    room_type VARCHAR NOT NULL,
    room_status VARCHAR NOT NULL,
    check_in TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT DEFAULT '',
    deposit_paid BOOLEAN DEFAULT false,
    payment_status VARCHAR DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policy for bookings
CREATE POLICY "Allow all operations on bookings" ON bookings
    FOR ALL USING (true) WITH CHECK (true);

-- 4. Create Payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guest_name VARCHAR NOT NULL,
    guest_email VARCHAR,
    guest_phone VARCHAR,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'Pending',
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create policy for payments
CREATE POLICY "Allow all operations on payments" ON payments
    FOR ALL USING (true) WITH CHECK (true);

-- 5. Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 6. Create triggers for updated_at
CREATE TRIGGER update_guests_updated_at 
    BEFORE UPDATE ON guests 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at 
    BEFORE UPDATE ON rooms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at 
    BEFORE UPDATE ON bookings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at 
    BEFORE UPDATE ON payments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Insert sample data (optional)
INSERT INTO rooms (number, type, status) VALUES
    ('101', 'Standard', 'available'),
    ('102', 'Standard', 'occupied'),
    ('103', 'Standard', 'cleaning'),
    ('201', 'Suite', 'available'),
    ('202', 'Suite', 'maintenance'),
    ('203', 'Suite', 'available')
ON CONFLICT (number) DO NOTHING;

INSERT INTO guests (name, email, phone) VALUES
    ('John Doe', 'john.doe@example.com', '+1234567890'),
    ('Jane Smith', 'jane.smith@example.com', '+0987654321'),
    ('Bob Johnson', 'bob.johnson@example.com', '+1122334455')
ON CONFLICT DO NOTHING;

-- Note: Replace the policies above with more restrictive ones based on your authentication needs
-- For example, if you want to restrict access to authenticated users only:
--
-- DROP POLICY "Allow all operations on guests" ON guests;
-- CREATE POLICY "Enable CRUD for authenticated users only" ON guests
--     FOR ALL USING (auth.role() = 'authenticated');
--
-- Apply similar policies to other tables as needed.
