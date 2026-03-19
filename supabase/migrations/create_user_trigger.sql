-- ============================================================
-- Heartbeat · Auto-create public.users on auth signup
-- Run this in Supabase SQL Editor once.
-- ============================================================

-- Function: called by trigger whenever a new auth.users row is inserted
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER           -- runs with owner privileges, bypasses RLS
SET search_path = public
AS $$
DECLARE
  _display_name TEXT;
  _base_username TEXT;
  _username      TEXT;
  _counter       INT := 0;
BEGIN
  -- 1. Derive display name from metadata or email
  _display_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'full_name',
    SPLIT_PART(NEW.email, '@', 1)
  );

  -- 2. Derive base username from metadata or email (lowercase, safe chars only)
  _base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    REGEXP_REPLACE(LOWER(SPLIT_PART(NEW.email, '@', 1)), '[^a-z0-9_]', '_', 'g')
  );

  _username := _base_username;

  -- 3. Ensure username is unique (append _1, _2 … if needed)
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = _username) LOOP
    _counter  := _counter + 1;
    _username := _base_username || '_' || _counter;
  END LOOP;

  -- 4. Insert the profile row; do nothing if already exists (safety guard)
  INSERT INTO public.users (id, email, phone, username, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone,
    _username,
    _display_name
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Drop old trigger if it exists, then recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
