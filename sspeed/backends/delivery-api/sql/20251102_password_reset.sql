-- Password reset support without email/SMS (no extra cost)
-- Create table to store short-lived reset codes

CREATE TABLE IF NOT EXISTS password_resets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL,
  created_by INTEGER NULL REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);

-- Helpful index to fetch latest active code
CREATE INDEX IF NOT EXISTS idx_password_resets_user_active
  ON password_resets(user_id)
  WHERE used_at IS NULL;

