-- Auth schema, supabase_auth_admin role, and auth helper functions
-- Grant membership so current user can SET ROLE
GRANT supabase_auth_admin TO CURRENT_USER;

CREATE SCHEMA IF NOT EXISTS auth;
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
GRANT ALL PRIVILEGES ON SCHEMA auth TO supabase_auth_admin;
ALTER USER supabase_auth_admin SET search_path = 'auth';
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- Auth helper functions (owned by supabase_auth_admin to avoid permission issues)
SET ROLE supabase_auth_admin;

-- Dual-format JWT claim support: PostgREST <=12 sets single-value GUCs
-- (request.jwt.claim.sub), but v13+ only sets request.jwt.claims (JSON).
-- Fall back to JSON so auth.uid() works across all PostgREST versions.
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.role() RETURNS text AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.email() RETURNS text AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text;
$$ LANGUAGE sql STABLE;

RESET ROLE;
