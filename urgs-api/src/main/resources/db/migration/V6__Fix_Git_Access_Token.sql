-- Add git_access_token column if it doesn't exist (using logic or just ignore duplicate column error if DB supports it, but standard SQL doesn't really have IF NOT EXISTS for columns in MySQL easily without stored procedure, but assuming it's missing)
-- Since the user got an error "Unknown column", it is definitely missing.
-- V5 might have failed or been run before the line was added.

ALTER TABLE sys_user ADD COLUMN git_access_token VARCHAR(255) COMMENT 'Git Access Token';
