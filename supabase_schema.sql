-- Run this in Supabase Dashboard: SQL Editor → New query → paste and Run.
-- Creates all tables for Financial App: history (remittance, exchange, tour, daily sold) and cash flow (opening cash).
-- Run once. If you re-run and get "policy already exists", drop policies first or ignore those errors.

CREATE TABLE IF NOT EXISTS remittance_transactions (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  date_time TIMESTAMPTZ NOT NULL,
  customer_name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  bank_name TEXT DEFAULT '',
  account_number TEXT DEFAULT '',
  myr_amount TEXT NOT NULL,
  foreign_amount TEXT NOT NULL,
  currency TEXT NOT NULL,
  fee_amount TEXT NOT NULL,
  is_paid BOOLEAN NOT NULL DEFAULT false,
  exchange_rate TEXT NOT NULL,
  fixed_rate TEXT NOT NULL,
  cost_amount TEXT NOT NULL,
  profit_amount TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exchange (Money Changer) transactions
CREATE TABLE IF NOT EXISTS exchange_transactions (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  date_time TIMESTAMPTZ NOT NULL,
  currency TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('buy', 'sell')),
  foreign_amount TEXT NOT NULL,
  myr_amount TEXT NOT NULL,
  rate_used TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tour & Travel transactions
CREATE TABLE IF NOT EXISTS tour_transactions (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  date_time TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL,
  driver TEXT NOT NULL,
  charge_amount TEXT NOT NULL,
  profit_amount TEXT NOT NULL,
  is_clear BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Sold profits (Money Changer batch)
CREATE TABLE IF NOT EXISTS daily_sold_profits (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  date_time TIMESTAMPTZ NOT NULL,
  amount TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Remittance customers (searchable by name or bank)
CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  bank_name TEXT NOT NULL DEFAULT '',
  account_number TEXT NOT NULL DEFAULT '',
  ifsc_code TEXT,
  country TEXT NOT NULL DEFAULT 'India',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- App settings (e.g. opening_cash) – key-value
CREATE TABLE IF NOT EXISTS app_settings (
  user_id UUID NOT NULL REFERENCES auth.users(id),
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, key)
);

-- Insert default opening cash if not exists (optional)
INSERT INTO app_settings (key, value) VALUES ('opening_cash', '10000.00')
ON CONFLICT (key) DO NOTHING;

-- Enable Row Level Security (RLS) – optional: allow all for anon key for now
ALTER TABLE remittance_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tour_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sold_profits ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Policies: per-user access using user_id = auth.uid(). Drop old anon policies if needed.
DROP POLICY IF EXISTS "Allow all for anon" ON remittance_transactions;
DROP POLICY IF EXISTS "Allow all for anon" ON exchange_transactions;
DROP POLICY IF EXISTS "Allow all for anon" ON tour_transactions;
DROP POLICY IF EXISTS "Allow all for anon" ON daily_sold_profits;
DROP POLICY IF EXISTS "Allow all for anon" ON customers;
DROP POLICY IF EXISTS "Allow all for anon" ON app_settings;

CREATE POLICY "remittance_by_user" ON remittance_transactions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "exchange_by_user" ON exchange_transactions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tour_by_user" ON tour_transactions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "daily_sold_by_user" ON daily_sold_profits
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "customers_by_user" ON customers
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "settings_by_user" ON app_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Optional: one fake customer for testing (run once; ignore if you prefer to add via app)
INSERT INTO customers (id, name, phone, bank_name, account_number, ifsc_code, country, created_at)
VALUES (
  'cust_fake_001',
  'Test Customer',
  '+60111234567',
  'Maybank',
  '1234567890',
  'MAYB0001234',
  'India',
  NOW()
)
ON CONFLICT (id) DO NOTHING;
