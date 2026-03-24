/*
  # RL Goods Packaging Generator Database

  1. New Tables
    - `profiles`: User accounts and metadata
    - `cases`: Display case reference data for different products
    - `designs`: Saved packaging designs
    - `design_revisions`: Version history for designs

  2. Security
    - Enable RLS on all tables
    - Users can only access their own designs
    - Cases are publicly readable
    - Profiles are publicly readable (for social features)

  3. Features
    - User authentication with email/password
    - Save/load unlimited designs
    - Reference library for compatible cases
    - Design versioning and history
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  display_name text,
  email text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by anyone"
  ON profiles FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create cases table
CREATE TABLE IF NOT EXISTS cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  product_code text UNIQUE NOT NULL,
  manufacturer text NOT NULL,
  dimensions_mm text NOT NULL,
  amazon_url text,
  image_url text,
  specifications jsonb,
  insert_card_width_in numeric,
  insert_card_height_in numeric,
  sleeve_width_in numeric,
  sleeve_height_in numeric,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cases are viewable by anyone"
  ON cases FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Create designs table
CREATE TABLE IF NOT EXISTS designs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  case_id uuid NOT NULL REFERENCES cases(id),
  name text NOT NULL,
  description text,
  figure_name text NOT NULL,
  figure_theme text,
  item_no text,
  ref_no text,
  set_name text,
  set_no text,
  bio text,
  fb_handle text,
  ig_handle text,
  accent_color text DEFAULT '#9e2a2a',
  gold_color text DEFAULT '#c8a96e',
  badge text DEFAULT 'HARD TO FIND',
  show_htf boolean DEFAULT true,
  show_bio boolean DEFAULT true,
  show_set boolean DEFAULT true,
  show_case boolean DEFAULT true,
  is_favorite boolean DEFAULT false,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE designs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own designs"
  ON designs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create designs"
  ON designs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own designs"
  ON designs FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own designs"
  ON designs FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create design_revisions table for history
CREATE TABLE IF NOT EXISTS design_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  design_id uuid NOT NULL REFERENCES designs(id) ON DELETE CASCADE,
  revision_number int NOT NULL,
  data jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE design_revisions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view revisions of own designs"
  ON design_revisions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designs
      WHERE designs.id = design_revisions.design_id
      AND designs.user_id = auth.uid()
    )
  );

-- Insert the featured case
INSERT INTO cases (name, product_code, manufacturer, dimensions_mm, amazon_url, insert_card_width_in, insert_card_height_in, sleeve_width_in, sleeve_height_in, specifications)
VALUES (
  'XIN·SHI Minifigure Display Case',
  'XINSHI-ACRYLIC-MINI',
  'XIN·SHI',
  '80x56x9',
  'https://www.amazon.com/XIN%C2%B7SHI-Minifigures-Display-Acrylic-Building/dp/B08ZS717FR',
  1.5,
  2.5,
  8.16,
  2.72,
  '{
    "material": "Acrylic",
    "compartments": 4,
    "led_compatible": true,
    "figures_per_unit": 4,
    "mounting": "Tabletop"
  }'
) ON CONFLICT (product_code) DO NOTHING;
