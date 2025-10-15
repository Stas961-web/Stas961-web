/*
  # Create Bookings Table

  1. New Tables
    - `bookings`
      - `id` (uuid, primary key) - Unique booking identifier
      - `user_id` (uuid, nullable) - Reference to auth.users if user is authenticated
      - `name` (text) - Customer full name
      - `phone` (text) - Customer phone number
      - `email` (text) - Customer email address
      - `pickup` (text) - Pickup location address
      - `dropoff` (text) - Drop-off location address
      - `date` (date) - Booking date
      - `time` (time) - Booking time
      - `notes` (text, nullable) - Additional notes from customer
      - `booking_type` (text) - Either 'distance' or 'hourly'
      - `hours` (integer, nullable) - Number of hours if booking_type is 'hourly'
      - `distance` (numeric, nullable) - Distance in km if booking_type is 'distance'
      - `price` (numeric) - Final price in EUR
      - `flight_number` (text, nullable) - Flight or train number
      - `payment_status` (text) - Payment status: 'pending', 'paid', 'failed'
      - `payment_intent_id` (text, nullable) - Stripe payment intent ID
      - `status` (text) - Booking status: 'pending', 'confirmed', 'completed', 'cancelled'
      - `created_at` (timestamptz) - When booking was created
      - `updated_at` (timestamptz) - When booking was last updated

  2. Security
    - Enable RLS on `bookings` table
    - Add policy for authenticated users to read their own bookings
    - Add policy for authenticated users to create bookings
    - Add policy for unauthenticated users to create bookings (anyone can book)
    - Add policy for users to read their own bookings by email
*/

CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  pickup text NOT NULL,
  dropoff text NOT NULL,
  date date NOT NULL,
  time time NOT NULL,
  notes text DEFAULT '',
  booking_type text NOT NULL CHECK (booking_type IN ('distance', 'hourly')),
  hours integer CHECK (hours > 0),
  distance numeric CHECK (distance > 0),
  price numeric NOT NULL CHECK (price > 0),
  flight_number text DEFAULT '',
  payment_status text NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
  payment_intent_id text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can create bookings"
  ON bookings
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Users can read their own bookings by email"
  ON bookings
  FOR SELECT
  TO anon, authenticated
  USING (email = current_setting('request.jwt.claims', true)::json->>'email' OR user_id = auth.uid());

CREATE POLICY "Authenticated users can read their own bookings"
  ON bookings
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Authenticated users can update their own bookings"
  ON bookings
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS bookings_user_id_idx ON bookings(user_id);
CREATE INDEX IF NOT EXISTS bookings_email_idx ON bookings(email);
CREATE INDEX IF NOT EXISTS bookings_created_at_idx ON bookings(created_at DESC);
CREATE INDEX IF NOT EXISTS bookings_payment_status_idx ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS bookings_status_idx ON bookings(status);