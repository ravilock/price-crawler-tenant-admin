CREATE TABLE IF NOT EXISTS organization (id uuid PRIMARY KEY, slug text UNIQUE NOT NULL CHECK (slug = 'default'), name text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS membership (id uuid PRIMARY KEY, organization_id uuid NOT NULL REFERENCES organization(id), subject_id text NOT NULL, role text NOT NULL CHECK (role IN ('administrator','manager','auditor','end_user')), created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(organization_id,subject_id));

-- First-login provisioning only creates end-user membership. Administrative roles
-- are granted through the audited administrator workflow, never from a client claim.
CREATE OR REPLACE FUNCTION provision_default_end_user(p_subject_id text, p_display_name text)
RETURNS TABLE (organization_id uuid, membership_id uuid, role text)
LANGUAGE plpgsql AS $$
DECLARE default_org_id uuid;
BEGIN
  IF p_subject_id IS NULL OR length(trim(p_subject_id)) = 0 THEN
    RAISE EXCEPTION 'subject_id is required';
  END IF;
  INSERT INTO organization(id, slug, name)
    VALUES ('00000000-0000-4000-8000-000000000001', 'default', COALESCE(NULLIF(trim(p_display_name), ''), 'Default organization'))
    ON CONFLICT (slug) DO UPDATE SET slug = EXCLUDED.slug
    RETURNING id INTO default_org_id;
  RETURN QUERY
    INSERT INTO membership(id, organization_id, subject_id, role)
      VALUES (gen_random_uuid(), default_org_id, p_subject_id, 'end_user')
      ON CONFLICT (organization_id, subject_id) DO UPDATE SET subject_id = EXCLUDED.subject_id
      RETURNING membership.organization_id, membership.id, membership.role;
END;
$$;
