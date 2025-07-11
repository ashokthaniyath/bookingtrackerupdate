-- Room Calendar Management Tables for Supabase
-- Execute these SQL commands in your Supabase SQL Editor

-- Room Calendars Table
CREATE TABLE IF NOT EXISTS room_calendars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id TEXT NOT NULL,
    room_number TEXT NOT NULL,
    room_type TEXT NOT NULL,
    calendar_id TEXT NOT NULL UNIQUE, -- Google Calendar ID
    is_shared BOOLEAN DEFAULT false,
    shared_with TEXT[] DEFAULT '{}', -- Array of email addresses
    auto_accept_bookings BOOLEAN DEFAULT true,
    color TEXT DEFAULT '#4285F4',
    capacity INTEGER DEFAULT 2,
    location TEXT DEFAULT '',
    unavailable_hours JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unavailable Hours Table (Alternative to JSONB approach)
CREATE TABLE IF NOT EXISTS unavailable_hours (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_calendar_id UUID REFERENCES room_calendars(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_hour INTEGER NOT NULL CHECK (start_hour >= 0 AND start_hour <= 23),
    end_hour INTEGER NOT NULL CHECK (end_hour >= 0 AND end_hour <= 24),
    days_of_week INTEGER[] NOT NULL, -- Array: 1=Monday, 7=Sunday
    is_recurring BOOLEAN DEFAULT true,
    reason TEXT DEFAULT 'Maintenance',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calendar Notifications Table
CREATE TABLE IF NOT EXISTS calendar_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    guest_email TEXT NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('reminder', 'confirmation', 'cancellation')),
    sent BOOLEAN DEFAULT false,
    message TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_room_calendars_room_id ON room_calendars(room_id);
CREATE INDEX IF NOT EXISTS idx_room_calendars_calendar_id ON room_calendars(calendar_id);
CREATE INDEX IF NOT EXISTS idx_unavailable_hours_room_calendar_id ON unavailable_hours(room_calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_notifications_booking_id ON calendar_notifications(booking_id);
CREATE INDEX IF NOT EXISTS idx_calendar_notifications_scheduled_time ON calendar_notifications(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_calendar_notifications_sent ON calendar_notifications(sent);

-- RLS (Row Level Security) Policies
ALTER TABLE room_calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE unavailable_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_notifications ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users
CREATE POLICY "Users can view room calendars" ON room_calendars
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert room calendars" ON room_calendars
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update room calendars" ON room_calendars
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete room calendars" ON room_calendars
    FOR DELETE USING (auth.role() = 'authenticated');

-- Similar policies for other tables
CREATE POLICY "Users can manage unavailable hours" ON unavailable_hours
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Users can manage calendar notifications" ON calendar_notifications
    FOR ALL USING (auth.role() = 'authenticated');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_room_calendars_updated_at
    BEFORE UPDATE ON room_calendars
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
