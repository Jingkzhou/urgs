-- 1. Add role_id column
ALTER TABLE sys_user ADD COLUMN role_id BIGINT COMMENT 'Associated Role ID';

-- 2. Backfill existing data (Match by Name)
-- Update role_id where it finds a match in sys_role by name
UPDATE sys_user u
JOIN sys_role r ON u.role_name = r.name
SET u.role_id = r.id
WHERE u.role_id IS NULL;

-- 3. Backfill existing data (Match by Code as fallback)
UPDATE sys_user u
JOIN sys_role r ON u.role_name = r.code
SET u.role_id = r.id
WHERE u.role_id IS NULL;

-- 4. Verify Index (Optional but good practice)
-- CREATE INDEX idx_user_role_id ON sys_user(role_id);
